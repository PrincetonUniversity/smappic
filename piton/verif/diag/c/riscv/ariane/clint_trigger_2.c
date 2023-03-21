

/*
 * This test checks if timer interrupts are working 
 */
#include <stdint.h>
#include <stdio.h>
#include "util.h"
#define NUM_INTERRUPTS 128
#ifdef CLINT_BASE
  #undef CLINT_BASE
#endif
#define CLINT_BASE   0xe100f00000ULL
#define NCORES (PITON_NUMTILES * PITON_NUMCHIPS)

uint64_t *mtimecmp = (uint64_t*)(CLINT_BASE + 0x4000);
uint64_t *mtime = (uint64_t*)(CLINT_BASE + 0xbff8);
uint32_t *msip = (uint32_t*)(CLINT_BASE + 0x0000);
volatile  uint64_t int_count[8] __attribute__((aligned(64))) ; // separate cache line

inline void trap_success(uint8_t hartid) {
    // Read mcause
    uint64_t mcause;
    __asm__ __volatile__ ("csrr %0, mcause" : "=r" (mcause));

    // Check for interrupt
    if ((mcause >> 63) != 1) fail();
    if (((mcause & 15) != 3) && ((mcause & 15) != 1) && ((mcause & 15) != 0)) fail();
    
    ATOMIC_OP(int_count[0], 1, add, d);
    printf("%d\n", hartid);

    // Clear own interrupt, set up interrupt of next core
    msip[(hartid + 0) % NCORES] = 0;
    __sync_synchronize();
    if (int_count[0] < NUM_INTERRUPTS) {
        msip[(hartid + 1) % NCORES] = 0xffffffff;
    } 
}


#pragma GCC push_options
#pragma GCC optimize ("align-functions=64")
void trap_success0(void) __attribute__((interrupt));
void trap_success0(void) {
    trap_success(0);
    return;
}
void trap_success1(void) __attribute__((interrupt));
void trap_success1(void) {
    trap_success(1);
    return;
}
void trap_success2(void) __attribute__((interrupt));
void trap_success2(void) {
    trap_success(2);
    return;
}
void trap_success3(void) __attribute__((interrupt));
void trap_success3(void) {
    trap_success(3);
    return;
}
void trap_success4(void) __attribute__((interrupt));
void trap_success4(void) {
    trap_success(4);
    return;
}
void trap_success5(void) __attribute__((interrupt));
void trap_success5(void) {
    trap_success(5);
    return;
}
void trap_success6(void) __attribute__((interrupt));
void trap_success6(void) {
    trap_success(6);
    return;
}
void trap_success7(void) __attribute__((interrupt));
void trap_success7(void) {
    trap_success(7);
    return;
}
#pragma GCC pop_options

void main(uint64_t argc, char * argv[]) {
    uint8_t hartid = argv[0][0];
    int_count[0] = 0;    


    // Set up trap to alternate handler
    switch (hartid) {
        case 0:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success0));
            break;
        case 1:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success1));
            break;
        case 2:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success2));
            break;
        case 3:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success3));
            break;
        case 4:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success4));
            break;
        case 5:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success5));
            break;
        case 6:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success6));
            break;
        case 7:
            __asm__ __volatile__ ("csrw mtvec, %0": : "r" (&trap_success7));
            break;
        default:
            printf("No interrupt handler!\n");
            fail();
    }

    // Enabling interrupts for User, Supervisor and Machine mode
    uint64_t mie = (1 << 3) | (1 << 1) | (1 << 0); // M + S + U timer interrupt enable
    uint64_t mstatus = (1 << 3) | (1 << 1) | (1 << 0); // Global interrupt enable
    __asm__ __volatile__ ("csrw mie, %0": : "r" (mie));
    __asm__ __volatile__ ("csrs mstatus, %0" : : "r" (mstatus));
  
    msip[(hartid + 1) % NCORES] = 0xffffffff; // start all IPIs simultaneously for stress test

    while(int_count[0] < NUM_INTERRUPTS) {};
    barrier(NCORES);
    pass();
}