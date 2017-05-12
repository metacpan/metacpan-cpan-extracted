package VMOMI::DistributedVirtualSwitch;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['capability', 'DVSCapability', 0, 1],
    ['config', 'DVSConfigInfo', 0, 1],
    ['networkResourcePool', 'DVSNetworkResourcePool', 1, 0],
    ['portgroup', 'DistributedVirtualPortgroup', 1, 0],
    ['runtime', 'DVSRuntimeInfo', 0, 0],
    ['summary', 'DVSSummary', 0, 1],
    ['uuid', undef, 0, 1],
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
