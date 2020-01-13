# floppyboot

![floppyboot](https://i.postimg.cc/XvhKG8Pr/screenshot.png)

floppyboot is a bootable Flappy Bird clone written in x86 Assembly, fitting entirely within the boot sector. The assembled binary is only 490 bytes (padded to 512 to make it bootable). I'm planning on finding ways to make it smaller so I can add more features like scoring.

Use the up arrow key to jump!

To assemble floppyboot, install NASM and then run `./build.sh`.

To run floppyboot, you can either install QEMU and run `./run.sh`, or you can burn the binary to make a bootable disk and play it on "real steel".
