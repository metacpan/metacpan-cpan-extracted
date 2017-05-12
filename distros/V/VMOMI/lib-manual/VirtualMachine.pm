package VMOMI::VirtualMachine;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['capability', 'VirtualMachineCapability', 0, 1],
    ['config', 'VirtualMachineConfigInfo', 0, 0],
    ['datastore', 'ManagedObjectReference', 1, 0],
    ['environmentBrowser', 'ManagedObjectReference ', 0, 1],
    ['guest', 'GuestInfo', 0, 0],
    ['guestHeartbeatStatus', 'ManagedEntityStatus', 0, 1],
    ['layout', 'VirtualMachineFileLayout', 0, 0],
    ['layoutEx', 'VirtualMachineFileLayoutEx', 0, 0],
    ['network', 'ManagedObjectReference', 1, 0],
    ['resourcePool', 'ManagedObjectReference', 0, 0],
    ['rootSnapshot', 'ManagedObjectReference', 1, 0],
    ['runtime', 'VirtualMachineRuntimeInfo', 0, 1],
    ['snapshot', 'VirtualMachineSnapshotInfo', 0, 0],
    ['storage', 'VirtualMachineStorageInfo', 0, 0],
    ['summary', 'VirtualMachineSummary', 0, 1],
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
