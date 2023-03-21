/*
 * Copyright 2015 Amazon.com, Inc. or its affiliates.
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <time.h>

#define FILE_BUF_SIZE (1048576ULL * 16)
#define WRITE_BUF_SIZE (FILE_BUF_SIZE * 4)

typedef uint64_t flit_t;
const flit_t wakeup_flits[2] = {
    0x0000000000484000ULL, 
    0x0000000000010001ULL
};


static int wakeup_hart0(int dev_fd, uint64_t chipid);
static int dma_file(int dev_fd, const char* infname, uint64_t start_addr, uint64_t chipid, bool verbose);
void timespec_sub(struct timespec *t1, struct timespec *t2);
flit_t reverse_flit(flit_t flit);
uint64_t dev_address(uint64_t total_num_chips, uint64_t dst_chipid, uint64_t noc_id);

int main(int argc, char **argv) {
    uint64_t fpgaid = strtol(argv[1], NULL, 0);
    uint64_t chipid = strtol(argv[2], NULL, 0);
    const char* infname = argv[3];
    uint64_t start_addr = strtol(argv[4], NULL, 0);

    char dev_path[255];    
    sprintf(dev_path, "/dev/smappic_driver%lu", fpgaid);
    int dev_fd = open(dev_path, O_RDWR);
    if (dev_fd < 0) {
        perror("Cant open device");
        return -1;
    }
    
    dma_file(dev_fd, infname, start_addr, chipid, false);
    wakeup_hart0(dev_fd, chipid);
    close(dev_fd);

    return 0;
}

static int wakeup_hart0(int dev_fd, uint64_t chipid) {
  uint64_t dev_offset = dev_address((1ULL << 5) - 1, chipid, 2);
  pwrite(dev_fd, wakeup_flits, 2, dev_offset);
  return 0;
}

static int dma_file(int dev_fd, const char* infname, uint64_t start_addr, uint64_t chipid, bool verbose)
{
    ssize_t rc;
    int infile_fd = open(infname, O_RDONLY);
    if (infile_fd < 0) {
        fprintf(stderr, "skipping dma phase.\n");
        return 0;
    }

    flit_t* file_buf = calloc(FILE_BUF_SIZE, sizeof(flit_t));
    flit_t* write_buf = calloc(WRITE_BUF_SIZE, sizeof(flit_t));
    if (!file_buf || !write_buf) {
        fprintf(stderr, "cant allocate buffers\n");
        perror("cant allocate buffers");
        rc = -errno;
        goto out;
    }


    size_t file_offset = 0;
    long total_time = 0;
    struct timespec ts_start, ts_end;
    uint64_t addr = start_addr;
    uint64_t dev_offset = dev_address((1ULL << 5) - 1, chipid, 2);
    while(pread(infile_fd, file_buf, FILE_BUF_SIZE * sizeof(flit_t), file_offset) > 0) {

        // prepare buffer
        for (int i = 0; i < FILE_BUF_SIZE; i++) {
            write_buf[i*4 + 0] = 0x8000040080c3c008ULL | (0ULL << 50);
            write_buf[i*4 + 1] = (addr << 16) | 0x0800ULL;
            write_buf[i*4 + 2] = ((1ULL << 13) - 1) << 50;
            write_buf[i*4 + 3] = reverse_flit(file_buf[i]);
            addr += sizeof(flit_t);
        }

        rc = clock_gettime(CLOCK_MONOTONIC, &ts_start);

        rc = pwrite(dev_fd, write_buf, WRITE_BUF_SIZE, dev_offset);
        if (rc < 0) {
            fprintf(stderr, "couldn't write %llu flits to noc 2\n", WRITE_BUF_SIZE);
            goto out;
        }

        rc = clock_gettime(CLOCK_MONOTONIC, &ts_end);
        /* subtract the start time from the end time */
        timespec_sub(&ts_end, &ts_start);
        total_time += ts_end.tv_nsec + ts_end.tv_sec * 1000000000;
        /* a bit less accurate but side-effects are accounted for */
        if (verbose)
        fprintf(stdout,
            "%llu.%03llu sec. write %llu flits to noc 2\n",
            (long long unsigned) ts_end.tv_sec, (long long unsigned) ts_end.tv_nsec, WRITE_BUF_SIZE); 
       
        file_offset += FILE_BUF_SIZE * sizeof(flit_t);
    }


    if (verbose) {
        struct stat stat_buf;
        if (fstat(infile_fd, &stat_buf)) {
            fprintf(stderr, "unable determine size of input file %s.\n", infname);
            perror("input file size");
            rc = -errno;
            goto out;
        }
        uint64_t fsize = stat_buf.st_size;
        float bw = ((float)fsize)/total_time * 1e9 / (1024ULL * 1024);
        printf("** Total time %ld nsec, BW = %f MB/sec \n",
            total_time, bw);
    }
    rc = 0;

out:
    if (infile_fd >= 0)
        close(infile_fd);
    if (file_buf)
        free(file_buf);
    if (write_buf)
        free(write_buf);

    return rc;
}


static int timespec_check(struct timespec *t)
{
    if ((t->tv_nsec < 0) || (t->tv_nsec >= 1000000000))
        return -1;
    return 0;

}

void timespec_sub(struct timespec *t1, struct timespec *t2)
{
    if (timespec_check(t1) < 0) {
        fprintf(stderr, "invalid time #1: %lld.%.9ld.\n",
            (long long)t1->tv_sec, t1->tv_nsec);
        return;
    }
    if (timespec_check(t2) < 0) {
        fprintf(stderr, "invalid time #2: %lld.%.9ld.\n",
            (long long)t2->tv_sec, t2->tv_nsec);
        return;
    }
    t1->tv_sec -= t2->tv_sec;
    t1->tv_nsec -= t2->tv_nsec;
    if (t1->tv_nsec >= 1000000000) {
        t1->tv_sec++;
        t1->tv_nsec -= 1000000000;
    } else if (t1->tv_nsec < 0) {
        t1->tv_sec--;
        t1->tv_nsec += 1000000000;
    }
}

flit_t reverse_flit(flit_t flit)
{
    flit_t res = 0ULL;
    res |= (flit & (0xffULL << 0 )) << 56;
    res |= (flit & (0xffULL << 8 )) << 40;
    res |= (flit & (0xffULL << 16)) << 24;
    res |= (flit & (0xffULL << 24)) << 8 ;
    res |= (flit & (0xffULL << 32)) >> 8 ;
    res |= (flit & (0xffULL << 40)) >> 24;
    res |= (flit & (0xffULL << 48)) >> 40;
    res |= (flit & (0xffULL << 56)) >> 56;
    return res;
}

uint64_t dev_address(uint64_t total_num_chips, uint64_t dst_chipid, uint64_t noc_id)
{
    return (total_num_chips << 9) | ((dst_chipid+1) << 16) | (1ULL << (5+noc_id)) | (1ULL << (2+noc_id));
}
