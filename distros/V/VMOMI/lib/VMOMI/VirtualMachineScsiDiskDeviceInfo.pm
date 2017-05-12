package VMOMI::VirtualMachineScsiDiskDeviceInfo;
use parent 'VMOMI::VirtualMachineDiskDeviceInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineDiskDeviceInfo',
    'VirtualMachineTargetInfo',
    'DynamicData',
);

our @class_members = ( 
    ['disk', 'HostScsiDisk', 0, 1],
    ['transportHint', undef, 0, 1],
    ['lunNumber', undef, 0, 1],
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
