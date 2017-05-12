package VMOMI::ResourcePoolQuickStats;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['overallCpuUsage', undef, 0, 1],
    ['overallCpuDemand', undef, 0, 1],
    ['guestMemoryUsage', undef, 0, 1],
    ['hostMemoryUsage', undef, 0, 1],
    ['distributedCpuEntitlement', undef, 0, 1],
    ['distributedMemoryEntitlement', undef, 0, 1],
    ['staticCpuEntitlement', undef, 0, 1],
    ['staticMemoryEntitlement', undef, 0, 1],
    ['privateMemory', undef, 0, 1],
    ['sharedMemory', undef, 0, 1],
    ['swappedMemory', undef, 0, 1],
    ['balloonedMemory', undef, 0, 1],
    ['overheadMemory', undef, 0, 1],
    ['consumedOverheadMemory', undef, 0, 1],
    ['compressedMemory', undef, 0, 1],
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
