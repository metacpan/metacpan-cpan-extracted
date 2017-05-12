package VMOMI::HostSystem;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['capability', 'HostCapability', 0, 0],
    ['config', 'HostConfigInfo', 0, 0],
    ['configManager', 'HostConfigManager', 0, 1],
    ['datastore', 'ManagedObjectReference', 1, 0],
    ['datastoreBrowser', 'ManagedObjectReference', 0, 1],
    ['hardware', 'HostHardwareInfo', 0, 0],
    ['licensableResource', 'HostLicensableResourceInfo', 0, 1],
    ['network', 'ManagedObjectReference', 1, 0],
    ['runtime', 'HostRuntimeInfo', 0, 1],
    ['summary', 'HostListSummary', 0, 1],
    ['systemResources', 'HostSystemResourceInfo', 0, 0],
    ['vm', 'ManagedObjectReference', 1, 0],
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
