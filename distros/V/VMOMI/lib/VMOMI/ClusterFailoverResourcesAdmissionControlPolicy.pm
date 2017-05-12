package VMOMI::ClusterFailoverResourcesAdmissionControlPolicy;
use parent 'VMOMI::ClusterDasAdmissionControlPolicy';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterDasAdmissionControlPolicy',
    'DynamicData',
);

our @class_members = ( 
    ['cpuFailoverResourcesPercent', undef, 0, ],
    ['memoryFailoverResourcesPercent', undef, 0, ],
    ['failoverLevel', undef, 0, 1],
    ['autoComputePercentages', 'boolean', 0, 1],
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
