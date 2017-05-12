package VMOMI::HostListSummaryQuickStats;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['overallCpuUsage', undef, 0, 1],
    ['overallMemoryUsage', undef, 0, 1],
    ['distributedCpuFairness', undef, 0, 1],
    ['distributedMemoryFairness', undef, 0, 1],
    ['uptime', undef, 0, 1],
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
