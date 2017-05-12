package VMOMI::VirtualMachineVMCIDevice;
use parent 'VMOMI::VirtualDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, 1],
    ['allowUnrestrictedCommunication', 'boolean', 0, 1],
    ['filterEnable', 'boolean', 0, 1],
    ['filterInfo', 'VirtualMachineVMCIDeviceFilterInfo', 0, 1],
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
