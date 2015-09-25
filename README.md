# knoppix2usb

A simple script that takes a Knoppix ISO file, and puts it on a USB stick.

Usage: makekusb [/dev/device] [/path/to/knoppix.iso] [--skip-image]

--skip-image skips over the section where mkdiskimage is used to setup the USB stick. You can use this if you have already prepared the USB stick.

It's also recommended that you zero out the disk before use, but it's not required:
 dd if=/dev/zero of=/dev/device
