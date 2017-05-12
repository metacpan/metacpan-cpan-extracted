package VMOMI::HostConfigSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['port', undef, 0, ],
    ['sslThumbprint', undef, 0, 1],
    ['product', 'AboutInfo', 0, 1],
    ['vmotionEnabled', 'boolean', 0, ],
    ['faultToleranceEnabled', 'boolean', 0, 1],
    ['featureVersion', 'HostFeatureVersionInfo', 1, 1],
    ['agentVmDatastore', 'ManagedObjectReference', 0, 1],
    ['agentVmNetwork', 'ManagedObjectReference', 0, 1],
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
