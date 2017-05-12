package VMOMI::VirtualPCIPassthroughDeviceBackingInfo;
use parent 'VMOMI::VirtualDeviceDeviceBackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceDeviceBackingInfo',
    'VirtualDeviceBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['deviceId', undef, 0, ],
    ['systemId', undef, 0, ],
    ['vendorId', undef, 0, ],
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
