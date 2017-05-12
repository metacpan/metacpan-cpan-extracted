package VMOMI::VirtualDiskRawDiskVer2BackingInfo;
use parent 'VMOMI::VirtualDeviceDeviceBackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceDeviceBackingInfo',
    'VirtualDeviceBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['descriptorFileName', undef, 0, ],
    ['uuid', undef, 0, 1],
    ['changeId', undef, 0, 1],
    ['sharing', undef, 0, 1],
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
