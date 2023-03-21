// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

// Modified by Princeton University

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <pthread.h>
#include <errno.h>
#include <unistd.h>
#include <signal.h>
#include <pty.h>
#include <stdlib.h>
#include <fcntl.h>
#include <time.h>

#include <fpga_mgmt.h>
#include <utils/lcd.h>

#include "smappic_uart.h"

/*
 * pci_vendor_id and pci_device_id values below are Amazon's and avaliable to use for a given FPGA slot. 
 * Users may replace these with their own if allocated to them by PCI SIG
 */
const static uint16_t pci_vendor_id = 0x1D0F; /* Amazon PCI Vendor ID */
const static uint16_t pci_device_id = 0xF001; /* PCI Device ID preassigned by Amazon for F1 applications */
const static uint16_t pf_id = FPGA_APP_PF;
static pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;
typedef struct {
    int local_chip_id;
    bool is_secondary;
} thread_args_t;

static pthread_t outbound_thread;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
int pty_fd = 0;

int check_afi_ready(int fpga_id);
int start_transmission(int fpga_id, int local_chip_id, int is_secondary);
void* inbound_handler(void* thread_args);
void* outbound_handler(void* thread_args);
void term_handler(int sig);
int get_bar(int is_secondary);
void cleanup();

int main(int argc, char **argv) {
    int fpga_id = 0;
    int local_chip_id = 0;
    int rc;
   
    int is_secondary = 0;
    if (argc == 4) {
        fpga_id = strtol(argv[1], NULL, 10);
        fail_on(-errno, out, "invalid ``fpga_id`` field");
        local_chip_id = strtol(argv[2], NULL, 10);
        fail_on(-errno, out, "invalid ``local_chip_id`` field");
        is_secondary = strtol(argv[3], NULL, 10);
        fail_on(-errno, out, "invalid ``is_secondary`` field");
    } else {
        printf("wrong args\n");
        exit(1);
    }
 
    /* initialize the fpga_pci library so we could have access to FPGA PCIe from this applications */
    rc = fpga_pci_init();
    fail_on(rc, out, "Unable to initialize the fpga_pci library");

    /* initialize the fpga_plat library */
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

    rc = check_afi_ready(fpga_id);
    fail_on(rc, out, "AFI not ready");
    
    rc = start_transmission(fpga_id, local_chip_id, is_secondary);
    fail_on(rc, out, "transmission failed");

    return rc;
out:
    return 1;
}

 int check_afi_ready(int fpga_id) {
    struct fpga_mgmt_image_info info = {0}; 
    int rc;

    /* get local image description, contains status, vendor id, and device id. */
    rc = fpga_mgmt_describe_local_image(fpga_id, &info,0);
    fail_on(rc, out, "Unable to get AFI information from slot %d. Are you running as root?", fpga_id);

    /* check to see if the slot is ready */
    if (info.status != FPGA_STATUS_LOADED) {
        rc = 1;
        fail_on(rc, out, "AFI in Slot %d is not in READY state !", fpga_id);
    }

    /* confirm that the AFI that we expect is in fact loaded */
    if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
       info.spec.map[FPGA_APP_PF].device_id != pci_device_id) {
     fprintf(stderr, "AFI does not show expected PCI vendor id and device ID. If the AFI "
            "was just loaded, it might need a rescan. Rescanning now.\n");

     rc = fpga_pci_rescan_slot_app_pfs(fpga_id);
     fail_on(rc, out, "Unable to update PF for slot %d",fpga_id);
     /* get local image description, contains status, vendor id, and device id. */
     rc = fpga_mgmt_describe_local_image(fpga_id, &info,0);
     fail_on(rc, out, "Unable to get AFI information from slot %d",fpga_id);


     /* confirm that the AFI that we expect is in fact loaded after rescan */
     if (info.spec.map[FPGA_APP_PF].vendor_id != pci_vendor_id ||
         info.spec.map[FPGA_APP_PF].device_id != pci_device_id) {
       rc = 1;
       fail_on(rc, out, "The PCI vendor id and device of the loaded AFI are not "
               "the expected values.");
     }
    }

    return rc;
 out:
    return 1;
 }

int init_uart(int local_chip_id, int is_secondary) {
    /* init uart regs */
    int rc;

    uint64_t base_addr = 0x100000ULL * local_chip_id;
    pthread_mutex_lock(&mutex);
    rc = fpga_pci_poke(pci_bar_handle, base_addr | IER_ADDR, UINT32_C(0));
    fail_on(rc, out, "Unable to write to the fpga !");

    rc = fpga_pci_poke(pci_bar_handle, base_addr | FCR_ADDR, UINT32_C(0));
    fail_on(rc, out, "Unable to write to the fpga !");
    
    rc = fpga_pci_poke(pci_bar_handle, base_addr | FCR_ADDR, FCR_XMIT_RESET|FCR_RCVR_RESET);
    fail_on(rc, out, "Unable to write to the fpga !");

    rc = fpga_pci_poke(pci_bar_handle, base_addr | FCR_ADDR, FCR_FIFO_ENABLE);
    fail_on(rc, out, "Unable to write to the fpga !");

    rc = fpga_pci_poke(pci_bar_handle, base_addr | LCR_ADDR, LCR_DLAB | LCR_8N1);
    fail_on(rc, out, "Unable to write to the fpga !");

    // int div = is_secondary ? 9 : 66; 
    int div = is_secondary ? 66 : 66; 
    rc = fpga_pci_poke(pci_bar_handle, base_addr | DLL_ADDR, div);
    fail_on(rc, out, "Unable to write to the fpga !");

    rc = fpga_pci_poke(pci_bar_handle, base_addr | DLM_ADDR, 0);
    fail_on(rc, out, "Unable to write to the fpga !");
    
    rc = fpga_pci_poke(pci_bar_handle, base_addr | LCR_ADDR, LCR_8N1);
    fail_on(rc, out, "Unable to write to the fpga !");

    /* if there is an error code, exit with status 1 */
out:
    pthread_mutex_unlock(&mutex);
    return (rc != 0 ? 1 : 0);
}

int open_pty_pair (int *amaster, char** slave_name) {
    int master;
    char *name;

    master = getpt ();
    if (master < 0)
        return errno;

    if (grantpt (master) < 0 || unlockpt (master) < 0)
        goto close_master;
    
    name = ptsname (master);
    if (name == NULL)
        goto close_master;

    *amaster = master;
    *slave_name = name;
    return 0;

close_master:
    close (master);
    return errno;
}

int start_transmission(int fpga_id, int local_chip_id, int is_secondary) {
    int rc;

    /* attach to the fpga, with a pci_bar_handle out param */
    uint16_t bar_id = get_bar(is_secondary);
    rc = fpga_pci_attach(fpga_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", fpga_id);

    rc = init_uart(local_chip_id, is_secondary);
    fail_on(rc, out, "Unable to init uart regs");
    
    signal(SIGTERM, term_handler);

    char* slave_name = NULL;
    rc = open_pty_pair(&pty_fd, &slave_name);
    fail_on(rc, out, "Unable to get pty pair !");
    fprintf(stdout, "terminal is open at %s\n", slave_name);
    
    thread_args_t thread_args;
    thread_args.local_chip_id = local_chip_id;
    thread_args.is_secondary = is_secondary;

    pthread_mutex_init(&mutex, NULL);

    pthread_create( &outbound_thread, NULL, &outbound_handler, (void*) &thread_args);
    inbound_handler((void*) &thread_args);

    pthread_join(outbound_thread, NULL);

out:
    /* clean up */
    cleanup();

    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}

void* inbound_handler(void* thread_args)  {
    int rc;
    int local_chip_id = ((thread_args_t*)thread_args)->local_chip_id;
    //bool is_secondary = ((thread_args_t*)thread_args)->is_secondary;
    uint64_t base_addr = 0x100000ULL * local_chip_id;
    uint32_t read_val = 0;
    while (1) {
        /* check if we're rebooting instance */
        //read_val = 0;
        //rc = fpga_pci_peek(pci_bar_handle, base_addr | SCR_ADDR, &read_val);
        //fail_on(rc, out, "Unable to read read from the fpga !");
        //if (read_val == 0xffffffff) {
        //    init_uart(local_chip_id, is_secondary);
        //    continue;
        //}

        /* Check if we have data to receive */
        uint32_t drdy = 0;
        do {
            read_val = 0;
            rc = fpga_pci_peek(pci_bar_handle, base_addr | LSR_ADDR, &read_val);
            fail_on(rc, out, "Unable to read read from the fpga !");
            drdy = read_val & LSR_DRDY;
        } while (!drdy);

        /* receive data */
        read_val = 0;
        rc = fpga_pci_peek(pci_bar_handle, base_addr | RBR_ADDR, &read_val);
        fail_on(rc, out, "Unable to read read from the fpga !");
	
        /* retransmit into the console */
        if (!write(pty_fd, &read_val, 1)) {
            rc = 1;
            fail_on(rc, out, "Unable to write to stream!");
        }
//        msleep(1);
    }
out:
    return NULL;
}

void* outbound_handler(void* thread_args) {
    int rc;
    int local_chip_id = ((thread_args_t*)thread_args)->local_chip_id;
    uint64_t base_addr = 0x100000ULL * local_chip_id;
    while (1) {
        char c;
	    if (!read(pty_fd, &c, 1)) {
            rc = 1;
            fail_on(rc, out, "Unable to write to stream!");
        }
        /* Send a value */
        pthread_mutex_lock(&mutex);
        uint32_t temt = 0;
        do {
            uint32_t tmp = 0;
            rc = fpga_pci_peek(pci_bar_handle, base_addr | LSR_ADDR, &tmp);
            fail_on(rc, out, "Unable to read read from the fpga !");
            temt = tmp & LSR_TEMT;
//            temt = tmp & LSR_THRE;
        } while (!temt);

        rc = fpga_pci_poke(pci_bar_handle, base_addr | THR_ADDR, (uint32_t) c);
        fail_on(rc, out, "Unable to write to the fpga !");
        pthread_mutex_unlock(&mutex);
        msleep(10);
    }
out:
    return NULL;
}

void term_handler(int sig) {
    cleanup();
}

int get_bar(int is_secondary) {
    switch (is_secondary) {
        case 0: return APP_PF_BAR0;
        case 1: return APP_PF_BAR1;
        default: return -EINVAL; 
    }
}

void cleanup()
{
    pthread_cancel(outbound_thread);     
    close(pty_fd);
    pthread_mutex_destroy(&mutex);
    if (pci_bar_handle >= 0) {
        fpga_pci_detach(pci_bar_handle);
    }
}
