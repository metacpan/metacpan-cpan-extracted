# Uptake

Download kernels from <http://kernel.ubuntu.com/~kernel-ppa/mainline/>.

## List

List all kernels:

    uptake list

List all 3.1x but rc kernels:

    uptake list --no rc --regex '3.1[0-9]'


## Get

The default download path is $HOME/.cache/kernels.

Download all kernels:
    
    uptake list | uptake get

Download all but rc, i386 and lowlatency kernels:

    uptake list --no rc | uptake get --no i386 --no lowlatency

Download the latest kernel to ~/Download:

    uptake list | tail -1 | uptake get --dir ~/Download

