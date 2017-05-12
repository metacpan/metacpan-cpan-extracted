package VMOMI::VirtualMachineDeviceRuntimeInfoVirtualEthernetCardRuntimeState;
use parent 'VMOMI::VirtualMachineDeviceRuntimeInfoDeviceRuntimeState';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualMachineDeviceRuntimeInfoDeviceRuntimeState',
    'DynamicData',
);

our @class_members = ( 
    ['vmDirectPathGen2Active', 'boolean', 0, ],
    ['vmDirectPathGen2InactiveReasonVm', undef, 1, 1],
    ['vmDirectPathGen2InactiveReasonOther', undef, 1, 1],
    ['vmDirectPathGen2InactiveReasonExtended', undef, 0, 1],
    ['reservationStatus', undef, 0, 1],
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
