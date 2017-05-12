package VMOMI::PlacementSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['priority', 'VirtualMachineMovePriority', 0, 1],
    ['vm', 'ManagedObjectReference', 0, 1],
    ['configSpec', 'VirtualMachineConfigSpec', 0, 1],
    ['relocateSpec', 'VirtualMachineRelocateSpec', 0, 1],
    ['hosts', 'ManagedObjectReference', 1, 1],
    ['datastores', 'ManagedObjectReference', 1, 1],
    ['storagePods', 'ManagedObjectReference', 1, 1],
    ['disallowPrerequisiteMoves', 'boolean', 0, 1],
    ['rules', 'ClusterRuleInfo', 1, 1],
    ['key', undef, 0, 1],
    ['placementType', undef, 0, 1],
    ['cloneSpec', 'VirtualMachineCloneSpec', 0, 1],
    ['cloneName', undef, 0, 1],
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
