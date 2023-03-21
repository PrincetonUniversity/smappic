// Copyright (c) 2022 Princeton University
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <time.h>

#include <fpga_mgmt.h>
#include <utils/lcd.h>

/*
 * pci_vendor_id and pci_device_id values below are Amazon's and avaliable to use for a given FPGA slot. 
 * Users may replace these with their own if allocated to them by PCI SIG
 */
static const uint16_t pci_vendor_id = 0x1D0F; /* Amazon PCI Vendor ID */
static const uint16_t pci_device_id = 0xF001; /* PCI Device ID preassigned by Amazon for F1 applications */

/* lower two fields are specific to how config regs in SMAPPIC are attached to the shell */
static const uint16_t pf_id = FPGA_MGMT_PF; 
static const uint16_t bar_id = MGMT_PF_BAR4; 

int check_afi_ready(int fpga_id);
int do_write(int fpga_id, uint64_t addr, uint32_t val);
int do_read(int fpga_id, uint64_t addr, uint32_t* val);

int main(int argc, char **argv) {
    int fpga_id = 0;
    int write = 0;
    int rc;
    uint64_t addr = 0;
    uint32_t val = 0;
    int verbose = false;

    if (argc >= 3) {  
        addr = strtol(argv[2], NULL, 0);
        fail_on(-errno, out, "invalid address");
        fpga_id = strtol(argv[1], NULL, 0);
        fail_on(-errno, out, "invalid fpga_id");
    } 
    else {
        printf("wrong args\n");
        exit(1);
    }
    
    if (argc == 4) {
        val = strtol(argv[3], NULL, 0);
        fail_on(-errno, out, "invalid value");
        write = 1;
    }
 
    /* initialize the fpga_pci library so we could have access to FPGA PCIe from this applications */
    rc = fpga_pci_init();
    fail_on(rc, out, "Unable to initialize the fpga_pci library");

    /* initialize the fpga_plat library */
    rc = fpga_mgmt_init();
    fail_on(rc, out, "Unable to initialize the fpga_mgmt library");

    rc = check_afi_ready(fpga_id);
    fail_on(rc, out, "AFI not ready");
    
    if (write) {
        rc = do_write(fpga_id, addr, val);
        fail_on(rc, out, "couldn't do write");
        if (verbose)
            printf("Wrote to addr 0x%lx, value: 0x%x\n", addr, val);
    }
    else {
        rc = do_read(fpga_id, addr, &val);
        fail_on(rc, out, "couldn't do read");
        if (verbose)
            printf("Read from addr 0x%lx, value: 0x%x\n", addr, val);
    }
    
    return rc;
out:
    return 1;
}

 int check_afi_ready(int fpga_id) {
    struct fpga_mgmt_image_info info = {0}; 
    int rc;

    /* get local image description, contains status, vendor id, and device id. */
    rc = fpga_mgmt_describe_local_image(fpga_id, &info,0);
    fail_on(rc, out, "Unable to get AFI information from FPGA id %d. Are you running as root?", fpga_id);

    /* check to see if the fpga is ready */
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


int do_write(int fpga_id, uint64_t addr, uint32_t val) {
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;

    /* attach to the fpga, with a pci_bar_handle out param */
    rc = fpga_pci_attach(fpga_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on slot id %d", fpga_id);

    rc = fpga_pci_poke(pci_bar_handle, addr, val);
    fail_on(rc, out, "Unable to write to the fpga !");
    
out:
    /* clean up */
    if (pci_bar_handle >= 0) {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc) {
            fprintf(stderr, "Failure while detaching from the fpga.\n");
        }
    }

    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}


int do_read(int fpga_id, uint64_t addr, uint32_t* val) {
    int rc;
    pci_bar_handle_t pci_bar_handle = PCI_BAR_HANDLE_INIT;

    /* attach to the fpga, with a pci_bar_handle out param */
    rc = fpga_pci_attach(fpga_id, pf_id, bar_id, 0, &pci_bar_handle);
    fail_on(rc, out, "Unable to attach to the AFI on FPGA id %d", fpga_id);

    rc = fpga_pci_peek(pci_bar_handle, addr, val);
    fail_on(rc, out, "Unable to read from the fpga !");
    
out:
    /* clean up */
    if (pci_bar_handle >= 0) {
        rc = fpga_pci_detach(pci_bar_handle);
        if (rc) {
            fprintf(stderr, "Failure while detaching from the fpga.\n");
        }
    }

    /* if there is an error code, exit with status 1 */
    return (rc != 0 ? 1 : 0);
}

