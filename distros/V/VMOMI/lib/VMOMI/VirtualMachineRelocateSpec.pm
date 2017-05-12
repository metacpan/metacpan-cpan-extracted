package VMOMI::VirtualMachineRelocateSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['service', 'ServiceLocator', 0, 1],
    ['folder', 'ManagedObjectReference', 0, 1],
    ['datastore', 'ManagedObjectReference', 0, 1],
    ['diskMoveType', undef, 0, 1],
    ['pool', 'ManagedObjectReference', 0, 1],
    ['host', 'ManagedObjectReference', 0, 1],
    ['disk', 'VirtualMachineRelocateSpecDiskLocator', 1, 1],
    ['transform', 'VirtualMachineRelocateTransformation', 0, 1],
    ['deviceChange', 'VirtualDeviceConfigSpec', 1, 1],
    ['profile', 'VirtualMachineProfileSpec', 1, 1],
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
