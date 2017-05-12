package VMOMI::VirtualDeviceOption;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['type', undef, 0, ],
    ['connectOption', 'VirtualDeviceConnectOption', 0, 1],
    ['busSlotOption', 'VirtualDeviceBusSlotOption', 0, 1],
    ['controllerType', undef, 0, 1],
    ['autoAssignController', 'BoolOption', 0, 1],
    ['backingOption', 'VirtualDeviceBackingOption', 1, 1],
    ['defaultBackingOptionIndex', undef, 0, 1],
    ['licensingLimit', undef, 1, 1],
    ['deprecated', 'boolean', 0, ],
    ['plugAndPlay', 'boolean', 0, ],
    ['hotRemoveSupported', 'boolean', 0, 1],
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
