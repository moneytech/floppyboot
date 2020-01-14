# floppyboot

![floppyboot](https://i.postimg.cc/6p8LBBnX/screenshot2.png)

floppyboot is a bootable Flappy Bird clone written in x86 Assembly, fitting entirely within the boot sector. The assembled binary is currently exactly 512 bytes. If your score reaches 16, you win!

Use the up arrow key to jump!

To assemble floppyboot, install NASM and then run `./build.sh`.

To run floppyboot, you can either install QEMU and run `./run.sh`, or you can burn the binary to make a bootable disk and play it on "real steel".
