package VMOMI::VirtualDeviceDeviceBackingInfo;
use parent 'VMOMI::VirtualDeviceBackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['deviceName', undef, 0, ],
    ['useAutoDetect', 'boolean', 0, 1],
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
