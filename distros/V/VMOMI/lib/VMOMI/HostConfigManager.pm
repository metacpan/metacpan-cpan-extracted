package VMOMI::HostConfigManager;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['cpuScheduler', 'ManagedObjectReference', 0, 1],
    ['datastoreSystem', 'ManagedObjectReference', 0, 1],
    ['memoryManager', 'ManagedObjectReference', 0, 1],
    ['storageSystem', 'ManagedObjectReference', 0, 1],
    ['networkSystem', 'ManagedObjectReference', 0, 1],
    ['vmotionSystem', 'ManagedObjectReference', 0, 1],
    ['virtualNicManager', 'ManagedObjectReference', 0, 1],
    ['serviceSystem', 'ManagedObjectReference', 0, 1],
    ['firewallSystem', 'ManagedObjectReference', 0, 1],
    ['advancedOption', 'ManagedObjectReference', 0, 1],
    ['diagnosticSystem', 'ManagedObjectReference', 0, 1],
    ['autoStartManager', 'ManagedObjectReference', 0, 1],
    ['snmpSystem', 'ManagedObjectReference', 0, 1],
    ['dateTimeSystem', 'ManagedObjectReference', 0, 1],
    ['patchManager', 'ManagedObjectReference', 0, 1],
    ['imageConfigManager', 'ManagedObjectReference', 0, 1],
    ['bootDeviceSystem', 'ManagedObjectReference', 0, 1],
    ['firmwareSystem', 'ManagedObjectReference', 0, 1],
    ['healthStatusSystem', 'ManagedObjectReference', 0, 1],
    ['pciPassthruSystem', 'ManagedObjectReference', 0, 1],
    ['licenseManager', 'ManagedObjectReference', 0, 1],
    ['kernelModuleSystem', 'ManagedObjectReference', 0, 1],
    ['authenticationManager', 'ManagedObjectReference', 0, 1],
    ['powerSystem', 'ManagedObjectReference', 0, 1],
    ['cacheConfigurationManager', 'ManagedObjectReference', 0, 1],
    ['esxAgentHostManager', 'ManagedObjectReference', 0, 1],
    ['iscsiManager', 'ManagedObjectReference', 0, 1],
    ['vFlashManager', 'ManagedObjectReference', 0, 1],
    ['vsanSystem', 'ManagedObjectReference', 0, 1],
    ['messageBusProxy', 'ManagedObjectReference', 0, 1],
    ['userDirectory', 'ManagedObjectReference', 0, 1],
    ['accountManager', 'ManagedObjectReference', 0, 1],
    ['hostAccessManager', 'ManagedObjectReference', 0, 1],
    ['graphicsManager', 'ManagedObjectReference', 0, 1],
    ['vsanInternalSystem', 'ManagedObjectReference', 0, 1],
    ['certificateManager', 'ManagedObjectReference', 0, 1],
    ['cryptoManager', 'ManagedObjectReference', 0, 1],
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
