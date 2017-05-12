package VMOMI::PlacementRankSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['specs', 'PlacementSpec', 1, ],
    ['clusters', 'ManagedObjectReference', 1, ],
    ['rules', 'PlacementAffinityRule', 1, 1],
    ['placementRankByVm', 'StorageDrsPlacementRankVmSpec', 1, 1],
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
