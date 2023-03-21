smappic_off -f 0 -c 0
smappic_off -f 0 -c 1
smappic_off -f 1 -c 0
smappic_off -f 1 -c 1

smappic_init_regs -f 2 -c 4

smappic_reset -f 0 -c 0
smappic_reset -f 0 -c 1
smappic_reset -f 1 -c 0
smappic_reset -f 1 -c 1

sleep 1

smappic_dma -f 0 -c 0 -i ~/f1-osdisk.img
