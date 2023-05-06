# The script to build test Ethernet application, last updated for Vitis/Vivado-2021.2

echo ""
echo "Extracting hw definitions from BD tcl script by Vivado to create C-header file"
vivado -mode batch -nolog -nojournal -notrace -source ./eth_syst_xparams.tcl

echo ""
# Taking some DMA driver sources
cp $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src/xaxidma_bdring.c ./
cp $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src/xaxidma_g.c      ./
# and commenting some lines in them
sed -i 's|DATA_SYNC|//DATA_SYNC|g' ./xaxidma_bdring.c
sed -i 's|#define XPAR_AXIDMA_0_INCLUDE_SG|//#define XPAR_AXIDMA_0_INCLUDE_SG|g' ./xaxidma_g.c

riscv64-unknown-linux-gnu-gcc -Wall -Og -fpermissive -D__aarch64__ -o ./eth_test \
                              -I./ \
                              -I../src/syst_hw \
                              -I$XILINX_VIVADO/data/embeddedsw/lib/sw_apps/versal_plm/misc \
                              -I$XILINX_VITIS/data/embeddedsw/lib/bsp/standalone_v7_6/src/common \
                              -I$XILINX_VITIS/data/embeddedsw/lib/bsp/standalone_v7_6/src/arm/cortexa9 \
                              -I$XILINX_VITIS/data/embeddedsw/lib/bsp/standalone_v7_6/src/arm/common/gcc \
                              -I$XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/tmrctr_v4_8/src \
                              -I$XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src \
                              -I$XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/gpio_v4_8/src \
                              -I$XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axis_switch_v1_4/src \
                                $XILINX_VITIS/data/embeddedsw/lib/bsp/standalone_v7_6/src/common/xil_assert.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/tmrctr_v4_8/src/xtmrctr.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/tmrctr_v4_8/src/xtmrctr_l.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/tmrctr_v4_8/src/xtmrctr_sinit.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/tmrctr_v4_8/src/xtmrctr_selftest.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/tmrctr_v4_8/src/xtmrctr_g.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src/xaxidma.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src/xaxidma_bd.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src/xaxidma_sinit.c \
                                $XILINX_VITIS/data/embeddedsw/XilinxProcessorIPLib/drivers/axidma_v9_13/src/xaxidma_selftest.c \
                                ./xaxidma_bdring.c \
                                ./xaxidma_g.c \
                                ../src/syst_hw/EthSyst.cpp \
                                ../src/app/ping_test.cpp \
                                ../src/app/eth_test.cpp

echo ""
FEDORA_IMG_PATH=/home/tools/load-ariane/firmware
ln -s -f $FEDORA_IMG_PATH/send-file.sh ./send-file
ln -s -f $FEDORA_IMG_PATH/get-file.sh  ./get-file
echo "Transfering files to/from Fedora on RISC-V (Caution: Transfers are *limited to 1MB* in both directions):"
echo "Host to Riscv:"
echo "host_ $ ./send-file <filename>            # the file is copied to the intermediate memory"
echo "riscv_$   get-file  <filesize> <filename> # this is indicated in above step"
echo "Riscv to Host:"
echo "riscv_$   send-file <filename>            # the file is copied to the intermediate memory"
echo "host_ $ ./get-file  <filesize> <filename> # this is indicated in above step"
echo "Both send-file/get-file require proper PATH to QDMA drivers as utilize dma-to-device/dma-from-device utils"

# ./send-file ./eth_test
