package VMOMI::ClusterEVCManagerEVCState;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['supportedEVCMode', 'EVCMode', 1, ],
    ['currentEVCModeKey', undef, 0, 1],
    ['guaranteedCPUFeatures', 'HostCpuIdInfo', 1, 1],
    ['featureCapability', 'HostFeatureCapability', 1, 1],
    ['featureMask', 'HostFeatureMask', 1, 1],
    ['featureRequirement', 'VirtualMachineFeatureRequirement', 1, 1],
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
