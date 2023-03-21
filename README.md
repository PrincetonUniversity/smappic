# SMAPPIC: Scalable Multi-FPGA Architecture Prototype Platform in Cloud

SMAPPIC is a computer architecture prototype platform in Cloud FPGAs. SMAPPIC is designed to make FPGA prototypes cheaper, easier, more accessible, and more scalable to researchers in academia and industry. 

SMAPPIC has been published in ASPLOS 2023: Grigory Chirkov and David Wentzlaff. ["SMAPPIC: Scalable Multi-FPGA Architecture Prototype Platform in the Cloud"](https://dl.acm.org/doi/10.1145/3575693.3575753) In Proceedings of the 28th International Conference on Architectural Support for Programming Languages and Operating Systems (ASPLOS '23), March 2023.
If you use SMAPPIC in your research please reference our ASPLOS 2023 paper mentioned above and send us a citation of your work.

#### SMAPPIC structure

SMAPPIC is by design a platform for multi-node (multi-chiplet/multi-socket) systems. There can be up to 4 nodes per each FPGA, and up to 4 FPGAs in a single prototype. Therefore, each node has 3 different related IDs: `local ID` (ID of the node inside an FPGA), `FPGA ID` (ID of the FPGA where the node is located), and `global ID` (`FPGA ID * number of FPGAs + local ID`). Figure below shows SMAPPIC prototype with 4 FPGAs, 16 nodes, and with `FPGA IDs` and `global IDs` shown.

![SMAPPIC structure](/docs/smappic_structure.svg?raw=true)

#### Using prototype 

SMAPPIC prototypes are executed Cloud FPGAs in AWS EC2 F1 instances. Each prototype has a unique identifier (`agfi-xxxxxxxxxxxxxxxxx`) that is used to program an FPGA. Here is the generic flow to run SMAPPIC. 

1. We assume that you already have F1 instance up and running. If not - steps 1,2,4,5 from [this guide](https://github.com/vegaluisjose/aws-fpga-notes) will help you. Keep in mind the number of FPGAs in your prototype when choosing instance:
 - 1 FPGA - f1.2xl
 - 2 FPGAs - f1.4xl
 - 3 or more FPGAs - f1.16xl

2. ssh into your instance, clone [SMAPPIC repository](https://github.com/PrincetonUniversity/smappic) and [aws-fpga repository](https://github.com/aws/aws-fpga). 

3. Setup the environment:
    ```
    $ cd AWS_FPGA_LOCATION
    $ source sdk_setup.sh
    $ cd SMAPPIC_LOCATION
    $ source piton/ariane_setup.sh
    ```

4. Compile software 
    ``` 
    $ cd $DV_ROOT/tools/src/smappic
    $ make
    ```
    This will compile SMAPPIC utilities (`smappic_dma`, `smappic_off`, `smappic_reg_rw`, `smappic_reset`, `smappic_uart`) and SMAPPIC PCIe driver (`smappic_driver`).

5. Load SMAPPIC image into all FPGA boards:
    ``` 
    $ fpga-load-local-image -S 0 -I agfi-xxxxxxxxxxxxxxxxx 
    $ fpga-load-local-image -S 1 -I agfi-xxxxxxxxxxxxxxxxx 
    ...
    $ fpga-load-local-image -S NUMFPGAS-1 -I agfi-xxxxxxxxxxxxxxxxx 
    ```
    After this step the fpga is programmed, but the reset signal is high, so the system is still not working. 

6. Initialize SMAPPIC configuration registers:
    ```
    $ smappic_init_regs -f NUMFPGAS -c NUMNODES
    ```

7. Load SMAPPIC driver
    ```
    $ sudo insmod smappic_driver.ko numfpgas=NUMFPGAS
    ```
    This will create `/dev/smappic_driver0` device driver. 

8. Write OS image in memory: 
    ``` 
    % smappic_dma -i $FILE_LOCATION 
    ```
    This will put the os image from FILE_LOCATION in the appropriate place in memory.

9. Create uart connection:
    ``` 
    $ smappic_uart 
    ```
    This will create a pseudo-terminal and tell you the location of the corresponding file (e.g. /dev/pts/3)

10. Start prototype (you need to issue separate command to each node in each FPGA):
    ``` 
    $ smappic_reset -f 0 -c 0
    $ smappic_reset -f 0 -c 1
    ...
    $ smappic_reset -f 0 -c NUMNODES_PER_FPGA-1
    $ smappic_reset -f 1 -c 0
    ...
    $ smappic_reset -f NUMFPGAS-1 -c NUMNODES_PER_FPGA-1

    ```
    After this the processor will start working and printing UART data in your pseudo-terminal. You can connect to the terminal using your favourite terminal program (e.g. screen, tio). 

11. Resetting prototype:
    In case you need to reset prototype, you should first power off the prototype (you need to issue separate command to each node in each FPGA):
    ```
    $ smappic_off -f 0 -c 0
    $ smappic_off -f 0 -c 1
    ...
    $ smappic_off -f 0 -c NUMNODES_PER_FPGA-1
    $ smappic_off -f 1 -c 0
    ...
    $ smappic_off -f NUMFPGAS-1 -c NUMNODES_PER_FPGA-1
    ```
    Then, repeat steps 8 and 10. 

12. Managing the fpga:
    In the software directory we provide you with some useful programs: 
    - smappic_uart : starts pseudo-terminal, connected to the OpenPiton's uart
    - smappiic_dma : copies file from argument into the SD part of the memory
    - smappic_reset : resets the fpga
    - smappic_off : sets the reset in the fpga to high, basically powering off SMAPPIC so that you could write the data into memory without memory corruptions. 

    Besides, you might find useful some utilities from AWS:
    - fpga-clear-local-image : clears the image from FPGA
    - fpga-set-virtual-dip-switch : sets the value of 16 virtual dip switches. Note that the last NUMNODES_PER_FPGA switches are connected to nodes' resets
    - fpga-get-virtual-led : reads the value of 16 virtual leds


#### Generating prototype bitstream
The flow is very simillar to synthesizing FPGA image in OpenPiton, but has own nuances. You will need Vivado ver. 2018.2 or newer. 


1. Create the S3 credentials, configure your S3 bucket, and store it in `SMAPPIC_S3_BUCKET` environment variable. You can find step guides here (https://github.com/vegaluisjose/aws-fpga-notes). 
    ```
    $ export SMAPPIC_S3_BUCKET=YOUR_S3_BUCKET
    ```

2. Clone [SMAPPIC repository](https://github.com/PrincetonUniversity/openpiton) and [aws-fpga repository](https://github.com/aws/aws-fpga). 

3. Setup the environment:
    ```
    $ cd AWS_FPGA_LOCATION
    $ source hdk_setup.sh
    $ cd OPENPITON_LOCATION
    $ source piton/ariane_setup.sh
    ```
    The second command will ask for the root password to apply patch for Vivado, but you don't have to do it - the flow still works even without patch. 

4. Run the synthesis:
    ``` 
    $ protosyn -b f1 -c ariane OPTIONS
    ```
    There are a few options configurable straight from CLI: 
    - `--x_tiles`, `--y_tiles` &mdash; dimensions of the single node. The number of tiles in one node is equal to their product. 
    - `--name` &mdash; the name of your prototype
    - `--num_chips` &mdash; total number of nodes in your prototype
    - `--num_fpgas` &mdash; number of FPGAs in prototype. Each FPGA will contain `num_chips / num_fpgas` nodes
    - `--local_lat` &mdash; latency of the interconnect between nodes on the same FPGA (in cycles)
    - `--global_lat` &mdash; latency of the interconnect between nodes on different FPGAs (in cycles)
    - `--mc_lat` &mdash; memory controller latency (in cycles)
    - `--freq` &mdash; prototype frequency (in MHz, only 62.5, 75 and 100 are supported currently)

    The command will print the afi and agfi IDs of your image. These IDs are assigned to the prototype after they are submitted to AWS for final processing. Note: at this stage the prototype might not be ready and might still be in processing stage at AWS. You can track the synthesis progress with
    ``` 
    $ aws ec2 describe-fpga-images --fpga-image-ids AFI_OF_YOUR_IMAGE 
    ```

8. After the synthesis is done - you can go load it into your F1 instance!

#### Preparing OS image

To prepare a Linux image for SMAPPIC you need to create an empty "disk" file and format it with
[`sgdisk`](https://wiki.archlinux.org/index.php/GPT_fdisk)
then write the image with
[`dd`](https://wiki.archlinux.org/index.php/Dd).
1. Download the Ariane Linux OS image from either
   the ariane-sdk [release](https://github.com/pulp-platform/ariane-sdk/releases/tag/v0.3.0-op)
   or
   the Princeton [archive](http://openpiton.org/download.php),
   extract and save the `.bin` file as `bbl.bin` in the current directory.
   If you want to build your own Linux image please see
   [ariane-sdk](https://github.com/pulp-platform/ariane-sdk).
2.  Create empty "disk" file:
    ```
    $ touch smappic-osdisk.img
    $ dd if=/dev/zero of=smappic-osdisk.img bs=1M count=128
    ```

3. Format disk:
    ```
    $ sgdisk --clear --new=1:2048:67583 --new=2 --typecode=1:3000 --typecode=2:8300 smappic-osdisk.img
    ```
    Create a new [GPT](https://en.wikipedia.org/wiki/GUID_Partition_Table)
    partition table and two partitions:
    1st partition 32MB (ONIE boot),
    2nd partition rest (Linux root).

4. Initialize disk:
    ```
    $ dd if=bbl.bin of=/dev/sdb1 oflag=sync bs=1M seek=1 conv=notrunc
    ```
    Write the `bbl.bin` file to the first partition.


#### OpenPiton

![OpenPiton Logo](/docs/openpiton_logo_black.png?raw=true)

SMAPPIC is based on [OpenPiton](https://github.com/PrincetonUniversity/openpiton) &mdash; the world's first open source, general purpose, multithreaded manycore processor and has the same basic functionality and architecture. There are several detailed pieces of documentation about OpenPiton that you can also use for your experiments in SMAPPIC:

- [OpenPiton GitHub repository](https://github.com/PrincetonUniversity/openpiton)
- [OpenPiton Simulation Manual](http://parallel.princeton.edu/openpiton/docs/sim_man.pdf)
- [OpenPiton Microarchitecture Specification](http://parallel.princeton.edu/openpiton/docs/micro_arch.pdf)
- [OpenPiton FPGA Prototype Manual](http://parallel.princeton.edu/openpiton/docs/fpga_man.pdf)
- [OpenPiton Synthesis and Back-end Manual](http://parallel.princeton.edu/openpiton/docs/synbck_man.pdf)
- [Piton Linux Kernel](https://github.com/PrincetonUniversity/piton-linux)
- [Piton Hypervisor](https://github.com/PrincetonUniversity/piton-sw)



