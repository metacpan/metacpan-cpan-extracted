package VMOMI::VirtualMachineSriovInfo;
use parent 'VMOMI::VirtualMachinePciPassthroughInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachinePciPassthroughInfo',
    'VirtualMachineTargetInfo',
    'DynamicData',
);

our @class_members = ( 
    ['virtualFunction', 'boolean', 0, ],
    ['pnic', undef, 0, 1],
    ['devicePool', 'VirtualMachineSriovDevicePoolInfo', 0, 1],
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
