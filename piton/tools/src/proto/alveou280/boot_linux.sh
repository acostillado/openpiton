
#In separate terminal:
#   $ screen /dev/ttyUSB2 115200
#To stop screen:
#   $ screen -ls
#   $ screen -S <proc_id> -X quit
#Another option:
#   $ picocom --send-cmd "cat" -b 115200 /dev/ttyUSB2 # send-cmd option is for file transfer using stdio

#Some Linux sanity commands:
# Linux version:
#   $ uname -a
# To check file system:
#   $ df -ah
#   $ sudo fdisk -l
# To check RAM:
#   $ top
#   $ free -th
#   $ cat /proc/meminfo

#PCIe GPIO bus: {Timeout_en(bit4), Bootrom_nOS(bit3), UartBoot_en(bit2), Ariane_rstn(bit1), System_rstn(bit0)}
dma-ctl qdma08000 reg write bar 2 0x0 0x0 && #Both resets
sleep 2 &&
dma-ctl qdma08000 reg write bar 2 0x0 0x1 && #Release system reset, we must wait until the memory is filled with 0s
sleep 5 &&

#Load the bbl linux image (with tetris) into main memory, actually at address 0x0, but should be 0x8000_0000
# dma-to-device -d /dev/qdma08000-MM-1 -s 14919792 -a 0x0000000 -f bbl8.bin

# Loading Fedora:
FEDORA_IMG_PATH=/home/tools/load-ariane/firmware
$FEDORA_IMG_PATH/load_image.sh $FEDORA_IMG_PATH/fedora-fs-dx.raw  $((0x13ff00000)) &&
sleep 1 &&

offset=0;
i=0;

echo -e "\r\nZeroing 8GB of memory as requirement for a manycore booting... \r\n"
while [ "$i" -lt "16" ]
do
        offset=$(( 2 * $i ))
        offsetHex=$( printf "%x" $offset ) ;
        echo -e "Zeroing 512MB starting at address 0x"$offsetHex"0000000\r\n"
        dma-to-device -d /dev/qdma08000-MM-1 -s 0x2000000 -a 0x"$offsetHex"0000000 0x0
        i=$(($i + 1));
done

echo -e "\r\nMemory zeroing finished\r\n"


$FEDORA_IMG_PATH/load_image.sh $FEDORA_IMG_PATH/osbi.bin  $((0x00000000)) &&
ln -s -f $FEDORA_IMG_PATH/send-file.sh ./send-file
ln -s -f $FEDORA_IMG_PATH/get-file.sh  ./get-file
echo "After booting Fedora login on Riscv side with user:riscv, pass:'fedora_rocks!', then: source ./setup.sh"
echo "Transfering files (Caution: Transfers are *limited to 1MB* in both directions):"
echo "Host to Riscv:"
echo "host_ $ ./send-file <filename>            # the file is copied to the intermediate memory"
echo "riscv_$   get-file  <filesize> <filename> # this is indicated in above step"
echo "Riscv to Host:"
echo "riscv_$   send-file <filename>            # the file is copied to the intermediate memory"
echo "host_ $ ./get-file  <filesize> <filename> # this is indicated in above step"
echo "Both send-file/get-file require proper PATH to QDMA drivers as utilize dma-to-device/dma-from-device utils"

sleep 2
dma-ctl qdma08000 reg write bar 2 0x0 0x3 #Release Ariane's reset

#picocom -b 115200 /dev/ttyUSB2
