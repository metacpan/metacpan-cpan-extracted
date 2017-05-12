package VMOMI::EVCMode;
use parent 'VMOMI::ElementDescription';

use strict;
use warnings;

our @class_ancestors = ( 
    'ElementDescription',
    'Description',
    'DynamicData',
);

our @class_members = ( 
    ['guaranteedCPUFeatures', 'HostCpuIdInfo', 1, 1],
    ['featureCapability', 'HostFeatureCapability', 1, 1],
    ['featureMask', 'HostFeatureMask', 1, 1],
    ['featureRequirement', 'VirtualMachineFeatureRequirement', 1, 1],
    ['vendor', undef, 0, ],
    ['track', undef, 1, 1],
    ['vendorTier', undef, 0, ],
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
