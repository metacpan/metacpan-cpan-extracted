package VMOMI::VirtualDiskPartitionedRawDiskVer2BackingInfo;
use parent 'VMOMI::VirtualDiskRawDiskVer2BackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDiskRawDiskVer2BackingInfo',
    'VirtualDeviceDeviceBackingInfo',
    'VirtualDeviceBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['partition', undef, 1, ],
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
