package VMOMI::ConfigTarget;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['numCpus', undef, 0, ],
    ['numCpuCores', undef, 0, ],
    ['numNumaNodes', undef, 0, ],
    ['smcPresent', 'boolean', 0, 1],
    ['datastore', 'VirtualMachineDatastoreInfo', 1, 1],
    ['network', 'VirtualMachineNetworkInfo', 1, 1],
    ['opaqueNetwork', 'OpaqueNetworkTargetInfo', 1, 1],
    ['distributedVirtualPortgroup', 'DistributedVirtualPortgroupInfo', 1, 1],
    ['distributedVirtualSwitch', 'DistributedVirtualSwitchInfo', 1, 1],
    ['cdRom', 'VirtualMachineCdromInfo', 1, 1],
    ['serial', 'VirtualMachineSerialInfo', 1, 1],
    ['parallel', 'VirtualMachineParallelInfo', 1, 1],
    ['sound', 'VirtualMachineSoundInfo', 1, 1],
    ['usb', 'VirtualMachineUsbInfo', 1, 1],
    ['floppy', 'VirtualMachineFloppyInfo', 1, 1],
    ['legacyNetworkInfo', 'VirtualMachineLegacyNetworkSwitchInfo', 1, 1],
    ['scsiPassthrough', 'VirtualMachineScsiPassthroughInfo', 1, 1],
    ['scsiDisk', 'VirtualMachineScsiDiskDeviceInfo', 1, 1],
    ['ideDisk', 'VirtualMachineIdeDiskDeviceInfo', 1, 1],
    ['maxMemMBOptimalPerf', undef, 0, ],
    ['resourcePool', 'ResourcePoolRuntimeInfo', 0, 1],
    ['autoVmotion', 'boolean', 0, 1],
    ['pciPassthrough', 'VirtualMachinePciPassthroughInfo', 1, 1],
    ['sriov', 'VirtualMachineSriovInfo', 1, 1],
    ['vFlashModule', 'VirtualMachineVFlashModuleInfo', 1, 1],
    ['sharedGpuPassthroughTypes', 'VirtualMachinePciSharedGpuPassthroughInfo', 1, 1],
);

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
