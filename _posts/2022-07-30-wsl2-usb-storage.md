---
layout: post
title: "Directly accessing USB storage in WSL2 Debian"
categories: project
tags: wsl2 usb debian linux
---
I needed to access a USB storage device in WSL2 so I could install LVM and LUKS on it. The only full Linux boxes I have at my disposal don't have USB-C, and I didn't have an adapter, so naturally I turned to the most absurd and indirect way to solve this problem. I followed some guides partially, including [this Microsoft blog](https://devblogs.microsoft.com/commandline/connecting-usb-devices-to-wsl/) and [this Stack Exchange answer](https://unix.stackexchange.com/a/702288/128767), but none matched my situation exactly.

## Overview
The core USB-passthrough function in WSL2 is powered by USB-IP. This is a protocol that translates USB traffic into IP traffic. WSL2 uses this to host a USB device on the Windows side as a server, and then connects the device on the Linux side as a client. Once the USB device is present on the Linux side, though, the current kernel implementation does not provide USB storage out of the box. 

*[does not provide USB storage]: Of course, it usually doesn't need to; WSL2 supports mounting folders inside through the normal file-sharing mechanism, assuming you'd use the Windows USB Storage support.

That means we'll need to complete a handful of tasks:
1. Get the WSL2 Kernel and build the `usb-storage` module
2. Install the Linux-side USB-IP tool
3. Install the Windows-side USB-IP tool/driver
4. Connect the device to Linux

## My situation
You should always use caution following any guide on the internet. In particular, this guide may be out of date by the time you read it. (It may also be malicious, so be careful to verify anything a guide asks you to download or run.) So you can follow along, I have WSL2 running Debian. Inside of Linux, `cat /etc/issue` reports `Debian GNU/Linux 11`, and `uname -r` reports `5.10.102.1-microsoft-standard-WSL2`. With regard to Linux, I'm currently running Windows 10 21H2 (as told by running `winver`). If yours are similar, you'll probably have success following this guide.

## WSL prerequisites
Because we're going to be doing stuff that is sensitive to the kernel version you're using, it's best if we get the most up-to-date WSL2 kernel available before we go too far. This update actually happens in Windows: you will need to run this in an elevated (Administrator) Command Prompt or PowerShell:
```
wsl --update
```

## Debian prerequisites
Next, before we try to build a kernel, you will want to get some things installed by running inside your Debian shell:
```
sudo apt-get update
sudo apt-get install build-essential flex bison libssl-dev bc libelf-dev usb-ip
```

This sets up Debian to be able to compile the kernel as well as grabbing the `usb-ip` Linux software while we're at it.

## Linux Kernel usb-storage module
If you're relatively seasoned with Linux, you might be searching for the comment section already. "Wait, why not use `uas`? It's way faster." This is correct, and that was my initial goal. However, it turns out that the [Linux USB-IP host controller is incompatible](https://gist.github.com/ironiridis/d515faecc1a2c063b297600d33dbfa24) with `uas`, and so we will need to fall back to the more basic variation, `usb-storage`.

*[searching for the comment section]: For your benefit and mine -- mostly mine -- I don't host comments here. If you do have feedback, please don't hesitate to send them to my email: chris@harrington.mn

To start, we need to check out the WSL2 kernel source code inside the Debian shell. This will take a long time. The filesystem on WSL2 is not very fast, and the git operation does millions of filesystem operations and downloads gigs of data.
```
git clone https://github.com/microsoft/WSL2-Linux-Kernel.git ~/wsl2k && cd ~/wsl2k
```

(Have you done this step before? Jump down to the [cleaning up section](#reuse-git-repo) for how to reuse your git repo to save yourself some time.)

Now, we need to check out the specific kernel revision that matches your running kernel. This one-liner tries to construct the right tag and branch to match your kernel. Don't worry if this doesn't work, since it will just keep using the default branch's code, which should still match the kernel you updated to earlier (by running `wsl --update`).
```
export wslBranch=$(git ls-remote --symref https://github.com/microsoft/WSL2-Linux-Kernel.git HEAD | grep -oE 'refs/heads/[^[:space:]]+' | cut -f 3 -d /)
export wslTag=tags/linux-msft-wsl-$(grep -oE '([0-9]+\.?)+' /proc/version | head -n1)
git checkout -f -B $wslBranch $wslTag
```

Now we'll unpack the existing kernel configuration, and make a couple of changes. The first is to disable the `BTF` debugging data, as it requires software that `apt-get` refused to install for me. The second is to explicitly enable the `usb-storage` module. The last line runs `yes` (but paradoxically with `n`) to update the kernel configuration to be satisfied with the previous change.
```
gunzip < /proc/config.gz > .config
sed -ix 's/CONFIG_DEBUG_INFO_BTF=y/CONFIG_DEBUG_INFO_BTF=n/' .config
sed -ix 's/^.*CONFIG_USB_STORAGE.*$/CONFIG_USB_STORAGE=m/' .config
yes n | make oldconfig
```

*[paradoxically]: The "yes" utility just outputs its argument over and over again. We use "yes" to respond "no" to the kernel configuration tool, because we don't want any of the optional choices compiled in.

Now, we compile. If you have lots of CPU power, you can replace the first `make` with `make -jX` where X is the number of cores you want to use, and the compile may run faster.
```
make modules && sudo make modules_install
```

Another surprising problem I encountered was to find that the `modules_install` does not use the same location that the kernel expects. I ended up with modules in `/lib/modules/5.10.102.1-microsoft-standard-WSL2+` but `modprobe` wanted no plus symbol at the end. So you may also need to copy your module directory into the right place.
```
sudo cp -av /lib/modules/$(uname -r)+ /lib/modules/$(uname -r)
```

Finally, to make sure the module compiled correctly and is matched with your kernel, probe it. If this command outputs nothing, you should be in business.
```
sudo modprobe usb-storage
```

Keep this terminal open in the background so your Debian VM doesn't suspend.

## Windows USB-IP
You'll want to download and install [the latest release of usbipd-win](https://github.com/dorssel/usbipd-win/releases). I used [usbipd-win 2.3.0](https://github.com/dorssel/usbipd-win/releases/tag/v2.3.0) because it was the most current at the time. This will require administrative access on Windows. I didn't need to reboot, so you probably don't need to either.

Before you continue, note that Windows has probably mounted your USB storage or is otherwise hanging on to it. You will want to [safely eject the device](https://support.microsoft.com/en-us/windows/safely-remove-hardware-in-windows-1ee6677d-4e6c-4359-efca-fd44b9cec369) first, to minimize the risk that something will be upset (either Windows *or* Linux).

You'll need to identify which device ID you want to connect to Linux. The easiest way is to open an elevated (Administrator) Command Prompt or PowerShell, list the devices, identify the "bus ID" of the device, and then attach it. In my case, the ID of my storage device was `1-13`. You will need to substitute your own.
```
usbipd wsl list
usbipd wsl attach --busid 1-13
```

If all goes according to plan, you should be able to run `usbipd wsl list` again and see the state of your device change to `Attached - Debian`. If so, you should be able to swing back over to your Debian terminal and do the normal things, like `dmesg` or `lsblk` to see your device.

## Cleaning things up
The kernel sources we checked out in `~/wsl2k`, alongside the built object files from `make`, clock in at a staggering 6.2 gigabytes in my case. If everything is working for you, you can clear this out in your Debian shell. Note that the `-f` flag here is because `git` will create read-only files which `rm` will otherwise prompt you about.
```
cd ; rm -rf ~/wsl2k
```

Note that WSL2 automatically updates kernels behind your back. As a result, you may find that you are unable to `sudo modprobe usb-storage` anymore in the future. If that's the case, you will need the kernel sources again. If you anticipate needing the direct USB Storage ability in the future, you should hang on to the `~/wsl2k` directory. In the [directions above](#linux-kernel-usb-storage-module), instead of `git clone ... ; cd ~/wsl2k` do `cd ~/wsl2k ; git fetch ; git reset --hard ; make distclean`
{: #reuse-git-repo}

If you don't need to build kernels or anything anymore, you can also remove the packages we installed. Just replace `apt-get install` with `apt-get remove`. However, be warned: you may have actually been using some of these packages already for other purposes. If in any doubt, just leave them in place. You also likely want to leave `usb-ip` installed unless you're certain you won't be using the USB passthrough function again.

To disconnect your USB device from the passthrough mechanism, you can run this in an elevated (Administrator) Command Prompt or PowerShell. Make sure you `unmount` any USB storage filesystems you have mounted in Debian first. The `--all` does just what it says, although if you only want to disconnect one passed-through device, specify the ID as before with `--busid 1-13` instead. (Naturally, substitute your ID from `usbipd wsl list`.)
```
usbipd wsl detach --all
```

