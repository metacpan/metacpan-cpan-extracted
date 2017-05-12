package VMOMI::DvsResourceRuntimeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['capacity', undef, 0, 1],
    ['usage', undef, 0, 1],
    ['available', undef, 0, 1],
    ['allocatedResource', 'DvsVnicAllocatedResource', 1, 1],
    ['vmVnicNetworkResourcePoolRuntime', 'DvsVmVnicNetworkResourcePoolRuntimeInfo', 1, 1],
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
