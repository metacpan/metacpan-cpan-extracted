package VMOMI::VirtualDiskOption;
use parent 'VMOMI::VirtualDeviceOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDeviceOption',
    'DynamicData',
);

our @class_members = ( 
    ['capacityInKB', 'LongOption', 0, ],
    ['ioAllocationOption', 'StorageIOAllocationOption', 0, 1],
    ['vFlashCacheConfigOption', 'VirtualDiskOptionVFlashCacheConfigOption', 0, 1],
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
