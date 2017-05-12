package VMOMI::ServiceContent;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['rootFolder', 'ManagedObjectReference', 0, ],
    ['propertyCollector', 'ManagedObjectReference', 0, ],
    ['viewManager', 'ManagedObjectReference', 0, 1],
    ['about', 'AboutInfo', 0, ],
    ['setting', 'ManagedObjectReference', 0, 1],
    ['userDirectory', 'ManagedObjectReference', 0, 1],
    ['sessionManager', 'ManagedObjectReference', 0, 1],
    ['authorizationManager', 'ManagedObjectReference', 0, 1],
    ['serviceManager', 'ManagedObjectReference', 0, 1],
    ['perfManager', 'ManagedObjectReference', 0, 1],
    ['scheduledTaskManager', 'ManagedObjectReference', 0, 1],
    ['alarmManager', 'ManagedObjectReference', 0, 1],
    ['eventManager', 'ManagedObjectReference', 0, 1],
    ['taskManager', 'ManagedObjectReference', 0, 1],
    ['extensionManager', 'ManagedObjectReference', 0, 1],
    ['customizationSpecManager', 'ManagedObjectReference', 0, 1],
    ['customFieldsManager', 'ManagedObjectReference', 0, 1],
    ['accountManager', 'ManagedObjectReference', 0, 1],
    ['diagnosticManager', 'ManagedObjectReference', 0, 1],
    ['licenseManager', 'ManagedObjectReference', 0, 1],
    ['searchIndex', 'ManagedObjectReference', 0, 1],
    ['fileManager', 'ManagedObjectReference', 0, 1],
    ['datastoreNamespaceManager', 'ManagedObjectReference', 0, 1],
    ['virtualDiskManager', 'ManagedObjectReference', 0, 1],
    ['virtualizationManager', 'ManagedObjectReference', 0, 1],
    ['snmpSystem', 'ManagedObjectReference', 0, 1],
    ['vmProvisioningChecker', 'ManagedObjectReference', 0, 1],
    ['vmCompatibilityChecker', 'ManagedObjectReference', 0, 1],
    ['ovfManager', 'ManagedObjectReference', 0, 1],
    ['ipPoolManager', 'ManagedObjectReference', 0, 1],
    ['dvSwitchManager', 'ManagedObjectReference', 0, 1],
    ['hostProfileManager', 'ManagedObjectReference', 0, 1],
    ['clusterProfileManager', 'ManagedObjectReference', 0, 1],
    ['complianceManager', 'ManagedObjectReference', 0, 1],
    ['localizationManager', 'ManagedObjectReference', 0, 1],
    ['storageResourceManager', 'ManagedObjectReference', 0, 1],
    ['guestOperationsManager', 'ManagedObjectReference', 0, 1],
    ['overheadMemoryManager', 'ManagedObjectReference', 0, 1],
    ['certificateManager', 'ManagedObjectReference', 0, 1],
    ['ioFilterManager', 'ManagedObjectReference', 0, 1],
    ['vStorageObjectManager', 'ManagedObjectReference', 0, 1],
    ['hostSpecManager', 'ManagedObjectReference', 0, 1],
    ['cryptoManager', 'ManagedObjectReference', 0, 1],
    ['healthUpdateManager', 'ManagedObjectReference', 0, 1],
    ['failoverClusterConfigurator', 'ManagedObjectReference', 0, 1],
    ['failoverClusterManager', 'ManagedObjectReference', 0, 1],
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
