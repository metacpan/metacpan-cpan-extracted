package VMOMI::PlacementRankResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['candidate', 'ManagedObjectReference', 0, ],
    ['reservedSpaceMB', undef, 0, ],
    ['usedSpaceMB', undef, 0, ],
    ['totalSpaceMB', undef, 0, ],
    ['utilization', undef, 0, ],
    ['faults', 'LocalizedMethodFault', 1, 1],
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
