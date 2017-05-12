package VMOMI::VirtualDisk;
use parent 'VMOMI::VirtualDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['capacityInKB', undef, 0, ],
    ['capacityInBytes', undef, 0, 1],
    ['shares', 'SharesInfo', 0, 1],
    ['storageIOAllocation', 'StorageIOAllocationInfo', 0, 1],
    ['diskObjectId', undef, 0, 1],
    ['vFlashCacheConfigInfo', 'VirtualDiskVFlashCacheConfigInfo', 0, 1],
    ['iofilter', undef, 1, 1],
    ['vDiskId', 'ID', 0, 1],
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
