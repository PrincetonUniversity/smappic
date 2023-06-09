# Copyright (c) 2019 Princeton University
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Princeton University nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


F1_INCLUDES = -I$(SDK_DIR)/userspace/include
MY_CFLAGS = -D_GNU_SOURCE -std=gnu11 -g -Wall -Werror -Wno-error=format
MY_LDLIBS = -lpthread -lbsd -lutil
F1_LDLIBS = -lfpga_mgmt 
MY_INCLUDES = -I./

all: smappic_driver smappic_dma smappic_uart smappic_reg_rw


obj-m += smappic_driver.o

smappic_driver:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

smappic_dma: smappic_dma.c
	gcc $(MY_CFLAGS) -o $@ smappic_dma.c

smappic_uart: smappic_uart.c smappic_uart.h 
	gcc $(MY_CFLAGS) -o $@ smappic_uart.c $(F1_LDLIBS) $(MY_LDLIBS) $(F1_INCLUDES) $(MY_INCLUDES) 

smappic_reg_rw: smappic_reg_rw.c  
	gcc $(MY_CFLAGS) -o $@ smappic_reg_rw.c $(F1_LDLIBS) $(MY_LDLIBS) $(F1_INCLUDES) $(MY_INCLUDES) 

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	rm -rf smappic_dma smappic_uart smappic_reg_rw 


