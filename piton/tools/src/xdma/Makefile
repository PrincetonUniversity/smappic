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

CFLAGS = -D_GNU_SOURCE -std=gnu11 -g -Wall -Werror 
LDLIBS = -lpthread -lbsd -lutil
F1_LDLIBS = -lfpga_mgmt 
INCLUDES = -I./

all: dma_os f1_uart f1_reg_rw

dma_os: dma_os.c
	gcc $(CFLAGS) -o $@ dma_os.c -lrt  $(LDLIBS) $(INCLUDES)

f1_uart: f1_uart.c f1_uart.h 
	gcc $(CFLAGS) -o $@ f1_uart.c $(F1_LDLIBS) $(LDLIBS) $(F1_INCLUDES) $(INCLUDES) 

f1_reg_rw: f1_reg_rw.c  
	gcc $(CFLAGS) -o $@ f1_reg_rw.c $(F1_LDLIBS) $(LDLIBS) $(F1_INCLUDES) $(INCLUDES) 

clean:
	rm -rf dma_os f1_uart 


