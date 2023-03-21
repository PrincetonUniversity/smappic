# start sequence of the bootloader
# 
# 
#include <smp.h>
#define DRAM_BASE 0x80000000

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
  csrr a0, mhartid
  bne a0, zero, _ipis_sent

  li sp, 0x84000000
  call main
# Use x/y configs for wakeup interrupt. (i.e. New IPI vector format in micro_arch.pdf)
# See openpiton micro_arch.pdf and OST1 micro arch spec
# for encoding.
# [17:16] == 01 and [5:0] == 000001 means power on reset
# [63] == 1 means the New IPI vector format
# [25:18] = x, [33:26] = y, [47:34] = chip_id, [51:48] = fbits
# Note that P-Mesh is big endian so our 8B word is flipped
#ifndef NO_PMESH_NOC_WAKEUP
  li t2, MAX_HARTS
  addi t2, t2, -1
  beq t2, zero, _ipis_sent

# set a3 a4 a5 to number of tiles in x and y and number of chips
# t0 t1 t2 are the current x and y and chip
  li a3, PITON_X_TILES
  li a4, PITON_Y_TILES
  li a5, PITON_NUM_CHIPS_SM

  li t0, 0
  li t1, 0
  li t2, 0
loop:
  # skip (0,0,0)
  addi t0, t0, 1
  bltu t0, a3, xy_determined
  addi t1, t1, 1
  li   t0, 0
  bltu t1, a4, xy_determined
  addi t2, t2, 1
  li   t1, 0

xy_determined:
  beq  t2, a5, _ipis_sent 
  # load x, y, chipid into t5 and 
  # other bits(flipped) into t6
  slli t5, t0, 18
  slli t6, t1, 26
  or   t5, t5, t6
  slli t6, t2, 34
  or   t5, t5, t6
  li   t6, 0x0100010000000080

  # load t5 into t6 byte by byte, changing
  # endianness in parallel
  li   t4, 0x0000000000ff0000
  and  t4, t5, t4
  slli t4, t4, 24  
  or   t6, t4, t6
  
  li   t4, 0x00000000ff000000
  and  t4, t5, t4
  slli t4, t4, 8
  or   t6, t4, t6

  li   t4, 0x000000ff00000000
  and  t4, t5, t4
  srli t4, t4, 8
  or   t6, t4, t6

  li   t4, 0x0000ff0000000000
  and  t4, t5, t4
  srli t4, t4, 24
  or   t6, t4, t6
  
  li t4, 0x9800000800
  sd t6, 0(t4)
  j loop
#endif

_ipis_sent:
  smp_pause(s1, s2)

  smp_resume(s1, s2)
  csrr a0, mhartid
  la a1, _dtb
  li s1, DRAM_BASE
  jr s1

  .section .dtb
  .globl _dtb
  .align 4, 0
_dtb:
  .incbin "ariane.dtb"
