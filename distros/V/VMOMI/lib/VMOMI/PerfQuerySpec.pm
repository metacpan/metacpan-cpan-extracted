package VMOMI::PerfQuerySpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entity', 'ManagedObjectReference', 0, ],
    ['startTime', undef, 0, 1],
    ['endTime', undef, 0, 1],
    ['maxSample', undef, 0, 1],
    ['metricId', 'PerfMetricId', 1, 1],
    ['intervalId', undef, 0, 1],
    ['format', undef, 0, 1],
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
