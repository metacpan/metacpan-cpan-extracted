package VMOMI::StoragePlacementSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['type', undef, 0, ],
    ['priority', 'VirtualMachineMovePriority', 0, 1],
    ['vm', 'ManagedObjectReference', 0, 1],
    ['podSelectionSpec', 'StorageDrsPodSelectionSpec', 0, ],
    ['cloneSpec', 'VirtualMachineCloneSpec', 0, 1],
    ['cloneName', undef, 0, 1],
    ['configSpec', 'VirtualMachineConfigSpec', 0, 1],
    ['relocateSpec', 'VirtualMachineRelocateSpec', 0, 1],
    ['resourcePool', 'ManagedObjectReference', 0, 1],
    ['host', 'ManagedObjectReference', 0, 1],
    ['folder', 'ManagedObjectReference', 0, 1],
    ['disallowPrerequisiteMoves', 'boolean', 0, 1],
    ['resourceLeaseDurationSec', undef, 0, 1],
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
