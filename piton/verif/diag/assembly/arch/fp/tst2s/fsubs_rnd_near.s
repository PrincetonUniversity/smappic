// Modified by Princeton University on June 9th, 2015
/*
* ========== Copyright Header Begin ==========================================
* 
* OpenSPARC T1 Processor File: fsubs_rnd_near.s
* Copyright (c) 2006 Sun Microsystems, Inc.  All Rights Reserved.
* DO NOT ALTER OR REMOVE COPYRIGHT NOTICES.
* 
* The above named program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License version 2 as published by the Free Software Foundation.
* 
* The above named program is distributed in the hope that it will be 
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
* 
* You should have received a copy of the GNU General Public
* License along with this work; if not, write to the Free Software
* Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
* 
* ========== Copyright Header End ============================================
*/
/***********************************************************************
* Name:   fsubs_rnd_near.s
* Date:   11/6/02
*
*
**********************************************************************/

#define ENABLE_T0_Fp_disabled_0x20
#include "boot.s"

.global sam_fast_immu_miss
.global sam_fast_dmmu_miss

.text
.global main

! Testing fsubs with rounding mode near

!// fsubs_rnd_near
!//
!//	Tests FSUBS in round to nearest mode
!//	Inputs are positive and negative:
!//		- infinity and infinity
!//		- infinity and NaN
!//		- NaN and infinity
!//		- NaN and NaN
!//		- infinity and norm/denorm/zero
!//		- NaN and norm/denorm/zero
!//		- norm/denorm/zero and infinity
!//		- norm/denorm/zero and NaN
!//		- norm/denorm/zero and norm/denorm/zero


main:

	! Common code

	wr		%g0, 0x4, %fprs		! make sure fef is 1 
	setx		source1, %l0, %l1
	setx		source2, %l0, %l2
	setx		result, %l0, %l3
	setx		fcc_result, %l0, %l4
	setx		cexc_flag, %l0, %l5
	setx		fsr_rounding_mode, %l0, %l6
	setx		scratch, %l0, %l7


	set		398, %g1		! Set loop count
	set		0x0, %g2		! Set loop iterator


fsubs_loop:
	ldx		[%l6+0x0], %fsr


	! instruction specific code

	sll		%g2, 0x2, %g3

	ldx		[%l6], %fsr		! Load fsr with rounding mode
	ld		[%l1+%g3], %f0		! Load source 1
	ld		[%l2+%g3], %f2		! Load source 2
	fsubs		%f0, %f2, %f4		! Perform the operation
	st		%f4, [%l7+0x0]		! Store the result for comparison
	stx		%fsr, [%l7+0x8]		! Store the fsr for comparison
	ld		[%l7+0x0], %g4		! Load result from memory for comparison

        ldx     [%l7+0x8], %g5   ! Load fsr from memory for comparison
        sll     %g2, 0x3, %g3
        ldx     [%l5+%g3], %g6   ! Load fsr with expected cexc mode
        mov     0x0f, %g3              ! Mask for nv
        and     %g3, %g6, %g7          ! Mask off nv
        srl     %g7, 0x3, %g7          ! Shift to get of
        or      %g7, %g6, %g6          ! Generate correct nx with of
        mov     0x01, %g3              ! Mask to get nx
        and     %g3, %g6, %g7          ! Mask off all but nx
        sll     %g7, 0x2, %g7          ! Shift to align nx and uf
        or      %g7, 0x1b, %g7         ! Mask for all cexc bits
        and     %g7, %g6, %g6          ! Generate correct uf for denorm
	      sll     %g6, 0x5, %g7          ! Generate aexc
	      or      %g6, %g7, %g7          ! Generate expected fsr
	      ldx     [%l6], %g6        ! Load fsr with rounding mode
	      or      %g6, %g7, %g7          ! Generate expected fsr

	sll		%g2, 0x2, %g3
	ld		[%l3+%g3], %g6		! Load expected result

	subcc		%g4, %g6, %g0		! Compare
	bne,a		test_fail		! If not equal, test failed
	nop
	subcc		%g5, %g7, %g0		! Compare
	bne,a		test_fail		! If not equal, test failed
	nop


	add		%g2, 0x1, %g2		! Increment loop iterator
	subcc		%g2, %g1, %g0		! Compare
	bne,a		fsubs_loop		! Loop
	nop


/*******************************************************
 * Exit code
 *******************************************************/

test_pass:
	ta		T_GOOD_TRAP

test_fail:
	ta		T_BAD_TRAP




/*******************************************************
* Data section
*******************************************************/
.data


fsr_rounding_mode:
	.xword		0x0000000000000000


source1:
	.word		0xff800000
	.word		0xff800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffab000f
	.word		0xffab000f
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0x7fab000f
	.word		0x7fab000f
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffe000a
	.word		0xfffe000a
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffe000a
	.word		0x7ffe000a
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xf2800000
	.word		0xf2ffffff
	.word		0xf3000000
	.word		0xf3000001
	.word		0xf3400000
	.word		0xf3800000
	.word		0xf3800001
	.word		0xf3c00000
	.word		0xf4000000
	.word		0xf4000001
	.word		0xf4200000
	.word		0xff7fffff
	.word		0xf37fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xb2800000
	.word		0xb2ffffff
	.word		0xb3000000
	.word		0xb3000001
	.word		0xb3400000
	.word		0xb3800000
	.word		0xb3800001
	.word		0xb3c00000
	.word		0xb4000000
	.word		0xb4000001
	.word		0xb4200000
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x8c7fffff
	.word		0x80200000
	.word		0x80400000
	.word		0x80400001
	.word		0x80600000
	.word		0x80800000
	.word		0x80800001
	.word		0x80c00000
	.word		0x81000000
	.word		0x81000001
	.word		0x81200000
.align 8


source2:
	.word		0x7f800000
	.word		0xff800000
	.word		0x7f800000
	.word		0xff800000
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffab000f
	.word		0x7fab000f
	.word		0xffab000f
	.word		0x7fab000f
	.word		0xfffe000a
	.word		0x7ffe000a
	.word		0xfffe000a
	.word		0x7ffe000a
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0xffabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0x7fabcdef
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000001
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0x00000000
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000001
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x80000000
	.word		0x72800000
	.word		0x72ffffff
	.word		0x73000000
	.word		0x73000001
	.word		0x73400000
	.word		0x73800000
	.word		0x73800001
	.word		0x73c00000
	.word		0x74000000
	.word		0x74000001
	.word		0x74200000
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x737fffff
	.word		0x7f7fffff
	.word		0x32800000
	.word		0x32ffffff
	.word		0x33000000
	.word		0x33000001
	.word		0x33400000
	.word		0x33800000
	.word		0x33800001
	.word		0x33c00000
	.word		0x34000000
	.word		0x34000001
	.word		0x34200000
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x3f7fffff
	.word		0x00200000
	.word		0x00400000
	.word		0x00400001
	.word		0x00600000
	.word		0x00800000
	.word		0x00800001
	.word		0x00c00000
	.word		0x01000000
	.word		0x01000001
	.word		0x01200000
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
	.word		0x0c7fffff
.align 8


result:
	.word		0xff800000
	.word		0x7fffffff
	.word		0x7fffffff
	.word		0x7f800000
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0xffeb000f
	.word		0x7feb000f
	.word		0xffeb000f
	.word		0x7feb000f
	.word		0xfffe000a
	.word		0x7ffe000a
	.word		0xfffe000a
	.word		0x7ffe000a
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0x7f800000
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0xffebcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0x7febcdef
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0xfffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0x7ffedcba
	.word		0xff800000
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0x00000000
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xc0000000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0x7f7fffff
	.word		0x00000000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x81000000
	.word		0x80ffffff
	.word		0x80800001
	.word		0x80800000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00000000
	.word		0x80000001
	.word		0x807fffff
	.word		0x80800000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80ffffff
	.word		0x80fffffe
	.word		0x80800000
	.word		0x807fffff
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00000001
	.word		0x00000000
	.word		0x807ffffe
	.word		0x807fffff
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800001
	.word		0x80800000
	.word		0x80000002
	.word		0x80000001
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x007fffff
	.word		0x007ffffe
	.word		0x00000000
	.word		0x80000001
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x80000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0x00000000
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f800000
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0x7f7fffff
	.word		0xff7fffff
	.word		0x00000000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x7f7fffff
	.word		0x40000000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0x3f800000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x00000000
	.word		0x00000001
	.word		0x007fffff
	.word		0x00800000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x01000000
	.word		0x00ffffff
	.word		0x00800001
	.word		0x00800000
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80000001
	.word		0x00000000
	.word		0x007ffffe
	.word		0x007fffff
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00ffffff
	.word		0x00fffffe
	.word		0x00800000
	.word		0x007fffff
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x807fffff
	.word		0x807ffffe
	.word		0x00000000
	.word		0x00000001
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800001
	.word		0x00800000
	.word		0x00000002
	.word		0x00000001
	.word		0xff7fffff
	.word		0xbf800000
	.word		0x80800000
	.word		0x807fffff
	.word		0x80000001
	.word		0x00000000
	.word		0x7f7fffff
	.word		0x3f800000
	.word		0x00800000
	.word		0x007fffff
	.word		0x00000001
	.word		0x00000000
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff7fffff
	.word		0xff7fffff
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xff800000
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800001
	.word		0xbf800001
	.word		0xbf7fffff
	.word		0xbf7fffff
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800000
	.word		0xbf800001
	.word		0xbf800001
	.word		0x8c7fffff
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800001
	.word		0x8c800001
	.word		0x8c7fffff
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800000
	.word		0x8c800001
	.word		0x8c800001
.align 8
fcc_result:


cexc_flag:
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000010
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000008
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000008
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000000
	.xword		0x0000000000000004
	.xword		0x0000000000000004
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000008
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000008
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000009
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000000
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
	.xword		0x0000000000000001
.align 8


scratch:
	.xword		0x0000000000000000
	.xword		0x0000000000000000


