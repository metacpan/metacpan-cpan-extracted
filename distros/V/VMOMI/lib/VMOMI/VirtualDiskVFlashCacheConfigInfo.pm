package VMOMI::VirtualDiskVFlashCacheConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vFlashModule', undef, 0, 1],
    ['reservationInMB', undef, 0, 1],
    ['cacheConsistencyType', undef, 0, 1],
    ['cacheMode', undef, 0, 1],
    ['blockSizeInKB', undef, 0, 1],
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
