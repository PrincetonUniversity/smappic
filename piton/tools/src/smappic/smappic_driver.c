/*
 * Copyright 2017 Amazon.com, Inc. or its affiliates.
 *
 * This software is available to you under a choice of one of two
 * licenses.  You may choose to be licensed under the terms of the GNU
 * General Public License (GPL) Version 2, available from the file
 * COPYING in the main directory of this source tree, or the
 * BSD license below:
 *
 *     Redistribution and use in source and binary forms, with or
 *     without modification, are permitted provided that the following
 *     conditions are met:
 *
 *      - Redistributions of source code must retain the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer.
 *
 *      - Redistributions in binary form must reproduce the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer in the documentation and/or other materials
 *        provided with the distribution.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

// Modified by Princeton University


#define pr_fmt(fmt) KBUILD_MODNAME ":%s: " fmt, __func__

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/stat.h>
#include <linux/uaccess.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/pci.h>
#include <linux/slab.h>
#include <linux/device.h>
#include <linux/kdev_t.h>



MODULE_AUTHOR("Grigory Chirkov <gchirkov@princeton.edu>");
MODULE_DESCRIPTION("SMAPPIC Driver");
MODULE_LICENSE("GPL");
MODULE_VERSION("1.0.0");

#define MAX_NUM_FPGAS 4

static int fpgas[MAX_NUM_FPGAS];
static int numfpgas;
module_param(numfpgas, int, 0);
MODULE_PARM_DESC(numfpgas, "Number of FPGAs in the system");

static struct cdev *kernel_cdev;
static dev_t dev_no;
static struct class *smappic_file_class;

#define DOMAIN 0
#define BUS 0
#define FUNCTION 0
#define DDR_BAR 4

ssize_t smappic_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos);
ssize_t smappic_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos);

struct file_operations smappic_fops = {
 .read =           smappic_read,
 .write =          smappic_write
};

int smappic_major;
#define SMAPPIC_HOST_BUFFER_SIZE 0x200000
unsigned char *smappic_host_buffer;
unsigned char *phys_smappic_host_buffer;

struct pci_dev *smappic_devs[MAX_NUM_FPGAS];
void __iomem *fpga_bases[MAX_NUM_FPGAS];

static int init_fpgas_array(int numfpgas) {
  switch (numfpgas) {
    case 1:
      fpgas[0] = 0x1d;
      return 0;
    case 2:
      fpgas[0] = 0x1b;
      fpgas[1] = 0x1d;
      return 0;
    case 4:
      fpgas[0] = 0x0f;
      fpgas[1] = 0x11;
      fpgas[2] = 0x13;
      fpgas[3] = 0x15;
      return 0;
    default:
      pr_alert("wrong number of fpgas!");
      return -1;
  }
}

static int __init smappic_init(void) {
  int result;
  int i;
  resource_size_t bar_start;
  resource_size_t bar_len;

  pr_notice("Installing SMAPPIC module\n");
  if (numfpgas == 8) numfpgas = 4;
  if (init_fpgas_array(numfpgas) < 0) {
      pr_alert("wrong numfpgas specified");
      return -1;
  }

  for (i = 0; i < numfpgas; i++) {
    smappic_devs[i] = pci_get_domain_bus_and_slot(DOMAIN, BUS, PCI_DEVFN(fpgas[i],FUNCTION));
    if (smappic_devs[i] == NULL) {
        pr_alert("Unable to locate PCI card number %d.\n", i);
        return -1;
    }
    result = pci_enable_device(smappic_devs[i]);
    if (result < 0) {
      pr_alert("Couldn't enable FPGA %d: %x\n", i, result);
      return result;
    }

    pcie_capability_set_word(smappic_devs[i], PCI_EXP_DEVCTL, PCI_EXP_DEVCTL_EXT_TAG);
    result = pcie_set_readrq(smappic_devs[i], 512);
    if (result < 0) {
      pr_alert("error set PCI_EXP_DEVCTL_READRQ in card %d: %d", i, result);
      return result;
    }
    pci_set_master(smappic_devs[i]);
    result = pci_request_region(smappic_devs[i], DDR_BAR, "DDR Region");
    if (result <0) {
      pr_alert("cannot obtain the DDR region in card %d.\n", i);
      return result;
    }
    bar_start = pci_resource_start(smappic_devs[i], DDR_BAR);
    bar_len   = pci_resource_len  (smappic_devs[i], DDR_BAR);
    pr_info("FPGA %d: base address 0x%llx, length=%llx", i, (u64)bar_start, (u64)bar_len);

    fpga_bases[i] = pci_iomap(smappic_devs[i], DDR_BAR, INT_MAX);
    if (fpga_bases[i] == NULL) {
        pr_alert("cant iomap ddr, card %d", i);
        return -1;
    }
  }

  result = alloc_chrdev_region(&dev_no, 0, numfpgas, "smappic_driver");   // get an assigned major device number
  if (result <0) {
    pr_alert("cannot alloc_chrdev_region.\n");
    return result;
  }

  smappic_file_class = class_create(THIS_MODULE, "smappic_driver");
  if (smappic_file_class == NULL) {
    pr_alert("couldn't create class for smappic_driver");
    return -1;
  }
  for (i = 0; i < numfpgas; i++) {
    if (device_create(smappic_file_class, NULL, MKDEV(MAJOR(dev_no), MINOR(dev_no) + i), NULL, "smappic_driver%d", i) == NULL) {
      pr_alert("cannot create smappic sysfs entry");
      return -1;
    }
  }
  
  kernel_cdev = cdev_alloc();
  kernel_cdev->ops = &smappic_fops;
  kernel_cdev->owner = THIS_MODULE;
  result = cdev_add(kernel_cdev, dev_no, numfpgas);
  if (result <0) {
    pr_alert("Unable to add cdev.\n");
    return result;
  }

  smappic_host_buffer = kmalloc(SMAPPIC_HOST_BUFFER_SIZE, GFP_DMA | GFP_USER);    // DMA buffer, do not swap memory
  phys_smappic_host_buffer = (unsigned char *)virt_to_phys(smappic_host_buffer);  // get the physical address for later
  pr_info("Host: base address 0x%lx, length=%llx\n", (long unsigned)phys_smappic_host_buffer, (u64)SMAPPIC_HOST_BUFFER_SIZE);

  return 0;
}

static void __exit smappic_exit(void) 
{
  int i;
  if (smappic_host_buffer != NULL)
    kfree(smappic_host_buffer);
  
  cdev_del(kernel_cdev);
  for (i = 0; i < numfpgas; i++) {
    device_destroy(smappic_file_class, MKDEV(MAJOR(dev_no), MINOR(dev_no) + i));
  }
  class_destroy(smappic_file_class);
  unregister_chrdev_region(dev_no, numfpgas);

  for (i = 0; i < numfpgas; i++) {
    if (smappic_devs[i] != NULL) {
      pci_iounmap(smappic_devs[i], fpga_bases[i]);
      pci_disable_device(smappic_devs[i]);
      pci_release_region(smappic_devs[i], DDR_BAR);    // release DDR region
      pci_dev_put(smappic_devs[i]);                    // free device memory
    }
  }
  pr_notice("Removing SMAPPIC module\n");
}

module_init(smappic_init);
module_exit(smappic_exit);

ssize_t smappic_read(struct file *filp, char __user *buf, size_t count, loff_t *f_pos) 
{
  pr_alert("attempt to read");
  return 0;
}

ssize_t smappic_write(struct file *filp, const char __user *buf, size_t count, loff_t *f_pos) 
{
  int dev;
  u64 i;
  u64* addr;  

  dev = iminor(filp->f_path.dentry->d_inode);
  if (dev < 0 || dev >= numfpgas) {
      pr_alert("writing to non-existent FPGA number %d", dev);
      return 0;
  }
  addr = (u64*) ((u64) fpga_bases[dev] | (u64)(*f_pos));

  for (i = 0; i < count; i++) {
    *addr = *((u64*)buf + i);
  }
  
  return count;
}

