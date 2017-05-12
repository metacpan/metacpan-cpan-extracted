package VMOMI::VsanPolicyCost;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['changeDataSize', undef, 0, 1],
    ['currentDataSize', undef, 0, 1],
    ['tempDataSize', undef, 0, 1],
    ['copyDataSize', undef, 0, 1],
    ['changeFlashReadCacheSize', undef, 0, 1],
    ['currentFlashReadCacheSize', undef, 0, 1],
    ['currentDiskSpaceToAddressSpaceRatio', undef, 0, 1],
    ['diskSpaceToAddressSpaceRatio', undef, 0, 1],
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
