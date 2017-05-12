package VMOMI::ClusterHostPowerAction;
use parent 'VMOMI::ClusterAction';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterAction',
    'DynamicData',
);

our @class_members = ( 
    ['operationType', 'HostPowerOperationType', 0, ],
    ['powerConsumptionWatt', undef, 0, 1],
    ['cpuCapacityMHz', undef, 0, 1],
    ['memCapacityMB', undef, 0, 1],
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
