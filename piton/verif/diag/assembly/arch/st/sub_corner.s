// Modified by Princeton University on June 9th, 2015
/*
* ========== Copyright Header Begin ==========================================
* 
* OpenSPARC T1 Processor File: sub_corner.s
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
 * Name:   
 * Date:   
 *
 *
 *  Description:
 *  boundary cases for sub instruction
 *
 **********************************************************************/

#include "boot.s"

.text
.global main  

#define DATA_NB 14
	
main:
	mov %g0, %l1
	mov %g0, %l2
	
	setx operand, %l0, %g1
	setx operand, %l0, %g2

loop_g1:	
	ldx [%g1 + %l1], %l3
loop_g2:	
	ldx [%g2 + %l2], %l4

sub:	
	wr %g0, %g0, %ccr
	sub %l3, %l4, %g7
	rd %ccr, %g6

subc:		
	wr %g0, %g0, %ccr
	subc %l3, %l4, %g7
	rd %ccr, %g6

subcc:		
	wr %g0, %g0, %ccr
	subcc %l3, %l4, %g7
	rd %ccr, %g6
	wr %g0, 1, %ccr
	subcc %l3, %l4, %g7
	rd %ccr, %g6
	wr %g0, 0x10, %ccr
	subcc %l3, %l4, %g7
	rd %ccr, %g6
	wr %g0, 0x11, %ccr
	subcc %l3, %l4, %g7
	rd %ccr, %g6

subccc:		
	wr %g0, %g0, %ccr
	subccc %l3, %l4, %g7
	rd %ccr, %g6
	wr %g0, 1, %ccr
	subccc %l3, %l4, %g7
	rd %ccr, %g6
	wr %g0, 0x10, %ccr
	subccc %l3, %l4, %g7
	rd %ccr, %g6
	wr %g0, 0x11, %ccr
	subccc %l3, %l4, %g7
	rd %ccr, %g6
		
	add %l2, 8, %l2
	cmp %l2, DATA_NB<<3
	bne loop_g2
	nop

	mov %g0, %l2
	add %l1, 8, %l1
	cmp %l1, DATA_NB<<3
	bne loop_g1
	nop
	
pass:
	ta		T_GOOD_TRAP

fail:
	ta		T_BAD_TRAP


/*******************************************************
 * Data section 
 *******************************************************/
	
.data

operand:		
	.xword 0x0000000000000000
	.xword 0x0000000000000001
	.xword 0x000000007ffffffe
	.xword 0x000000007fffffff
	.xword 0x0000000080000000
	.xword 0x0000000080000001	
	.xword 0x00000000fffffffe
	.xword 0x00000000ffffffff
	.xword 0x7ffffffffffffffe
	.xword 0x7fffffffffffffff
	.xword 0x8000000000000000
	.xword 0x8000000000000001
	.xword 0xfffffffffffffffe
	.xword 0xffffffffffffffff




