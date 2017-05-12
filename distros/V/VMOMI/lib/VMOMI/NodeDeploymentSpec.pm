package VMOMI::NodeDeploymentSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['esxHost', 'ManagedObjectReference', 0, 1],
    ['datastore', 'ManagedObjectReference', 0, 1],
    ['publicNetworkPortGroup', 'ManagedObjectReference', 0, 1],
    ['clusterNetworkPortGroup', 'ManagedObjectReference', 0, 1],
    ['folder', 'ManagedObjectReference', 0, ],
    ['resourcePool', 'ManagedObjectReference', 0, 1],
    ['managementVc', 'ServiceLocator', 0, 1],
    ['nodeName', undef, 0, ],
    ['ipSettings', 'CustomizationIPSettings', 0, ],
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
