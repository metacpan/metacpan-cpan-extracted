package VMOMI::ClusterVmToolsMonitoringSettings;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['enabled', 'boolean', 0, 1],
    ['vmMonitoring', undef, 0, 1],
    ['clusterSettings', 'boolean', 0, 1],
    ['failureInterval', undef, 0, 1],
    ['minUpTime', undef, 0, 1],
    ['maxFailures', undef, 0, 1],
    ['maxFailureWindow', undef, 0, 1],
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
