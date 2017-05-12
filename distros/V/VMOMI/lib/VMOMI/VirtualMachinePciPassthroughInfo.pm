package VMOMI::VirtualMachinePciPassthroughInfo;
use parent 'VMOMI::VirtualMachineTargetInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineTargetInfo',
    'DynamicData',
);

our @class_members = ( 
    ['pciDevice', 'HostPciDevice', 0, ],
    ['systemId', undef, 0, ],
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
