package VMOMI::StorageIORMInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['enabled', 'boolean', 0, ],
    ['congestionThresholdMode', undef, 0, 1],
    ['congestionThreshold', undef, 0, ],
    ['percentOfPeakThroughput', undef, 0, 1],
    ['statsCollectionEnabled', 'boolean', 0, 1],
    ['reservationEnabled', 'boolean', 0, 1],
    ['statsAggregationDisabled', 'boolean', 0, 1],
    ['reservableIopsThreshold', undef, 0, 1],
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
