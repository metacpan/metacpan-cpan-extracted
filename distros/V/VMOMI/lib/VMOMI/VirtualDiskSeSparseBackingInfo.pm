package VMOMI::VirtualDiskSeSparseBackingInfo;
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
    ['writeThrough', 'boolean', 0, 1],
    ['uuid', undef, 0, 1],
    ['contentId', undef, 0, 1],
    ['changeId', undef, 0, 1],
    ['parent', 'VirtualDiskSeSparseBackingInfo', 0, 1],
    ['deltaDiskFormat', undef, 0, 1],
    ['digestEnabled', 'boolean', 0, 1],
    ['grainSize', undef, 0, 1],
    ['keyId', 'CryptoKeyId', 0, 1],
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
