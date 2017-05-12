package VMOMI::StoragePlacementAction;
use parent 'VMOMI::ClusterAction';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterAction',
    'DynamicData',
);

our @class_members = ( 
    ['vm', 'ManagedObjectReference', 0, 1],
    ['relocateSpec', 'VirtualMachineRelocateSpec', 0, ],
    ['destination', 'ManagedObjectReference', 0, ],
    ['spaceUtilBefore', undef, 0, 1],
    ['spaceDemandBefore', undef, 0, 1],
    ['spaceUtilAfter', undef, 0, 1],
    ['spaceDemandAfter', undef, 0, 1],
    ['ioLatencyBefore', undef, 0, 1],
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
