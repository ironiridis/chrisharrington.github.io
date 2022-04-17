---
layout: post
title: "The Rigol DS1202Z-E does not support GPT on USB storage"
categories: techsupport
tags: electronics
---
If you happen to own or use a Rigol osilloscope, you may have been a victim of the error message:

`Flash Drive Not a DOS Disk,Please Format Flash Drive!`

I looked up a few threads, including [this top Google result](https://www.eevblog.com/forum/testgear/rigol-ds1074z-not-recognising-usb-flash-drives/), that were all over the place: You didn't eject the drive before you took it out of your computer. You can't use USB3 drives with your scope. Some drives just are too big, or too old, or too new, or they simply aren't compatible for some other mystery reason. The answer these (and other) threads seem to arrive at is always: just keep trying new USB sticks until you find one that works.

As an IT person, I don't like this explanation. It doesn't actually solve any problem, and it definitely doesn't prevent it from happening in the future. After encountering this issue myself and actually finding the *real reason*, I'd like to share it with you.

My Rigol DS1202Z-E (and possibly other Rigol scopes) does not support USB disks that use a [GUID Partition Table](https://en.wikipedia.org/wiki/GUID_Partition_Table), aka GPT. It's not worth your time for me to explain what this is, why it's on your drive, or why you would (or wouldn't) want it, and so on. The most important part to understand is that you don't need to buy a new USB stick, and "formatting" the drive, as the on-screen diagnostic requests, will not help. At least, not exactly.

## Fixing your USB drive
The single most important part of this article is to be adamantly clear: you cannot fix your drive without erasing it. All of the steps below carry the risk of data loss, so you need to proceed carefully.

### Fixing it on Windows 10
You're going to need to open an elevated command prompt or PowerShell window. You can do this by holding the Windows Key and tapping `X`, you should get a menu offering "Windows PowerShell (Admin)" or "Command Prompt (Admin)". Both of these are fine, so whichever one you have, select that. If your computer is configured to ask permission before elevating permission (as it should) you will be asked to confirm, either by clicking "Yes" or entering your admin-level password.

At this point, you want to start with the USB disk disconnected. This is critical; we are dealing with tools that could potentially erase your hard drive, so we need to be certain which drive is which. Once you've made sure the USB disk is definitely not inserted into your computer, you're going to run `diskpart` (and press enter) in your admin command window. This will take a moment, and when it's ready, you will see a `DISKPART>` prompt. Here, you will type `list disk` and press enter; this will display all of the disks in your computer that you absolutely do not want to ruin. Pay attention to the numbers.

![diskpart list disk, before inserting the usb stick](/assets/rigol-gpt-usb/usb-disk-diskpart-nousb.PNG)

Go ahead and insert your USB stick. Give your computer a moment to collect itself, and go back to that window and type `list disk` again. (Don't forget to hit enter.) You should see another entry, and the new entry size should be about the size of your USB device. (As a caveat: the companies that make storage devices have changed how they define "gigabyte" over the years, and some of them also slightly fudge their numbers. In this screenshot, my device is labeled "16GB" but `diskpart` says it has "14 GB".)

![diskpart list disk, after inserting the usb stick](/assets/rigol-gpt-usb/usb-disk-diskpart-withusb.PNG)

Note in the screenshot the asterisk under the `Gpt` column; this corresponds to a GPT-layout device. This is what is causing my problem with the Rigol. If your USB device does *not* have this asterisk, stop here. My instructions may do more harm than good for you. You can just close the command window to exit the disk erasing danger zone.

The next step is to select the disk. In my screenshots, I am using `disk 2` because that's where it is showing up for me, but it will likely show up as a different number for you. If your USB device isn't `disk 2` then you need to use your disk number in the following command.

`select disk 2`

then

`list disk`

![diskpart list disk, after selecting the disk](/assets/rigol-gpt-usb/usb-disk-diskpart-disk2selected.PNG)

This verifies we really, really have the right disk selected. You'll see an asterisk on the left edge of the disk you selected. Now, be aware: the following step will destroy data. If you have files you want to keep on this USB device, pause here and copy them off the device.

`clean`

![diskpart clean](/assets/rigol-gpt-usb/usb-disk-diskpart-afterclean.PNG)

This step erases all the partitions on the device, and prepares the device to convert it to the more basic MBR-layout.

`convert mbr`

![diskpart convert mbr](/assets/rigol-gpt-usb/usb-disk-diskpart-afterconvert.PNG)

This changes the device to use MBR.

`list disk`

![diskpart list disk, after converting to mbr](/assets/rigol-gpt-usb/usb-disk-diskpart-listafterconvert.PNG)

Now you should see your disk is missing the asterisk in the `Gpt` column. This means it worked! A couple more steps while we're here to make the Rigol happy.

`create partition primary`

![diskpart create partition primary](/assets/rigol-gpt-usb/usb-disk-diskpart-aftercreate.PNG)

This creates a new partition, which is the thing you actually are working with when you see a Drive in Windows. `C:` is a partition on a disk that may have several partitions. This will create an empty partition, we need to format it though. (Note that `partition 1` here is always going to be the same; we had zero partitions before, and `1` is the first one which we just created.)

`select paritition 1`

`format fs=fat32 quick`

![diskpart format](/assets/rigol-gpt-usb/usb-disk-diskpart-afterformat.PNG)

This selects the new partition we made, and then puts a FAT32 filesystem on it. Windows may pop up your new empty USB Drive now, and you should be all set. You can close the Command window, eject the drive, and jam it into your Rigol meter.

