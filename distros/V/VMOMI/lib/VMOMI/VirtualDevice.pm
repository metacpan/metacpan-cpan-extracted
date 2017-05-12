package VMOMI::VirtualDevice;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['deviceInfo', 'Description', 0, 1],
    ['backing', 'VirtualDeviceBackingInfo', 0, 1],
    ['connectable', 'VirtualDeviceConnectInfo', 0, 1],
    ['slotInfo', 'VirtualDeviceBusSlotInfo', 0, 1],
    ['controllerKey', undef, 0, 1],
    ['unitNumber', undef, 0, 1],
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
