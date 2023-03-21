#include <stdint.h>
#include <stdio.h>
#include "util.h"
#define NHARTS       (PITON_NUMTILES*PITON_NUMCHIPS)
#define PLIC_SOURCES 2
#ifdef CLINT_BASE
    #undef CLINT_BASE
#endif
#define CLINT_BASE   0xe100f00000ULL
#define PLIC_BASE    0xe200000000ULL

volatile  uint64_t int_count[8] __attribute__((aligned(64))) ; // separate cache line
volatile  uint64_t interrupt_value[8]  __attribute__((aligned(64)));
volatile  uint64_t *l15_int_vec_dis = (uint64_t *) 0x9800000800ULL;
volatile  uint64_t *trigger_address[2] = {(uint64_t*)0xfff0d00000ULL, (uint64_t*)0xfff0d01000ULL};

inline void trap_success(uint8_t hartid) {
    // Read mcause
    uint64_t mcause;
    __asm__ __volatile__ ("csrr %0, mcause" : "=r" (mcause));

    // Check for interrupt
    if ((mcause >> 63) != 1) fail();
    if ((mcause & 15) != 11) fail();

    // printf("%d\n", hartid);

    ATOMIC_OP(int_count[0], 1, add, d); 

    // write to the claim register to specify the interrupt is finished
    volatile uint32_t *addr = (uint32_t*)(PLIC_BASE + 0x200000 + 4);
    uint32_t val_claim = *addr;
    if (!val_claim) return;
    *(addr) = val_claim;
    // printf("%d\n", val_claim);
        
    return;
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

int main(int argc, char ** argv) {
    uint8_t hartid = argv[0][0];

    // enabling
    if (hartid == 0) {
        volatile uint32_t *addr = NULL;
        // Enable interrupts in all HARTS
        for (int i = 0; i < 7; i+=2) {
            addr = (uint32_t*)(PLIC_BASE + 0x2000 + 0x80*i);
            *addr = 0xffffffff;
        }

        addr = (uint32_t*)(PLIC_BASE + 0x4);
        *(addr) = 0x3;
        addr = (uint32_t*)(PLIC_BASE + 0x8);
        *(addr) = 0x1;
    }

    // Enabling interrupts for Supervisor and Machine mode
    uint64_t mie = (1 << 11); // M + S external interrupt enable
    uint64_t mstatus = (1 << 3); // Global interrupt enable
    __asm__ __volatile__ ("csrw mie, %0": : "r" (mie));
    __asm__ __volatile__ ("csrs mstatus, %0" : : "r" (mstatus));

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

    if (hartid == 0) {
        // Constructing edge interrupt packet (endianness will be flipped)
        interrupt_value[0] = 0ULL;
        interrupt_value[0] |= 0x1ULL << 63; // [63] == 1 - packet format using x/y
        interrupt_value[0] |= 0x0ULL << 38; // [45:38] chip id == 0
        interrupt_value[0] |= 0x0ULL << 34; // [37:34] fbits == 0 (processor)
        interrupt_value[0] |= 0x0ULL << 26; // [33:26] y == 0
        interrupt_value[0] |= 0x0ULL << 18; // [25:18] x == 0
        interrupt_value[0] |= 0x0ULL << 16; // [17:16] type == 0 (hw int)
        interrupt_value[0] |= 0x1ULL <<  7; // [7] irq_le == 1
        interrupt_value[0] |= 0x0ULL <<  6; // [6] edge == 0 (rising)
        interrupt_value[0] |= 0x1ULL <<  0; // [4:0] id = 1
        interrupt_value[0] = swap_uint64(interrupt_value[0]);

        // Constructing level interrupt packet (endianness will be flipped)
        interrupt_value[1] = 0ULL;
        interrupt_value[1] |= 0x1ULL << 63; // [63] == 1 - packet format using x/y
        interrupt_value[1] |= 0x0ULL << 38; // [45:38] chip id == 0
        interrupt_value[1] |= 0x0ULL << 34; // [37:34] fbits == 0 (processor)
        interrupt_value[1] |= 0x0ULL << 26; // [33:26] y == 0
        interrupt_value[1] |= 0x0ULL << 18; // [25:18] x == 0
        interrupt_value[1] |= 0x0ULL << 16; // [17:16] type == 0 (hw int)
        interrupt_value[1] |= 0x0ULL <<  7; // [7] irq_le == 0
        interrupt_value[1] |= 0x0ULL <<  6; // [6] edge == 0 (rising)
        interrupt_value[1] |= 0x2ULL <<  0; // [4:0] id = 2
        interrupt_value[1] = swap_uint64(interrupt_value[1]);
    }


    if (hartid == 0) {
        int_count[0] = 0;
    }

    barrier(NHARTS);
    // trigger edge sensitive interrupt from source 1
    if (hartid == 0) {
        *l15_int_vec_dis = interrupt_value[0];
        // *trigger_address[0] = 0x1;
    } 
    while (int_count[0] < 1) {};
    pass();
}