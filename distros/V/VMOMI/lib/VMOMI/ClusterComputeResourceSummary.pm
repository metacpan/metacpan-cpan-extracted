package VMOMI::ClusterComputeResourceSummary;
use parent 'VMOMI::ComputeResourceSummary';

use strict;
use warnings;

our @class_ancestors = ( 
    'ComputeResourceSummary',
    'DynamicData',
);

our @class_members = ( 
    ['currentFailoverLevel', undef, 0, ],
    ['admissionControlInfo', 'ClusterDasAdmissionControlInfo', 0, 1],
    ['numVmotions', undef, 0, ],
    ['targetBalance', undef, 0, 1],
    ['currentBalance', undef, 0, 1],
    ['usageSummary', 'ClusterUsageSummary', 0, 1],
    ['currentEVCModeKey', undef, 0, 1],
    ['dasData', 'ClusterDasData', 0, 1],
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
