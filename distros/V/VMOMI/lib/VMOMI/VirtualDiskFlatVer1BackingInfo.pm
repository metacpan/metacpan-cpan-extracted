package VMOMI::VirtualDiskFlatVer1BackingInfo;
use parent 'VMOMI::VirtualDeviceFileBackingInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceFileBackingInfo',
    'VirtualDeviceBackingInfo',
    'DynamicData',
);

our @class_members = ( 
    ['diskMode', undef, 0, ],
    ['split', 'boolean', 0, 1],
    ['writeThrough', 'boolean', 0, 1],
    ['contentId', undef, 0, 1],
    ['parent', 'VirtualDiskFlatVer1BackingInfo', 0, 1],
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
