package VMOMI::HostConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['host', 'ManagedObjectReference', 0, ],
    ['product', 'AboutInfo', 0, ],
    ['deploymentInfo', 'HostDeploymentInfo', 0, 1],
    ['hyperThread', 'HostHyperThreadScheduleInfo', 0, 1],
    ['consoleReservation', 'ServiceConsoleReservationInfo', 0, 1],
    ['virtualMachineReservation', 'VirtualMachineMemoryReservationInfo', 0, 1],
    ['storageDevice', 'HostStorageDeviceInfo', 0, 1],
    ['multipathState', 'HostMultipathStateInfo', 0, 1],
    ['fileSystemVolume', 'HostFileSystemVolumeInfo', 0, 1],
    ['systemFile', undef, 1, 1],
    ['network', 'HostNetworkInfo', 0, 1],
    ['vmotion', 'HostVMotionInfo', 0, 1],
    ['virtualNicManagerInfo', 'HostVirtualNicManagerInfo', 0, 1],
    ['capabilities', 'HostNetCapabilities', 0, 1],
    ['datastoreCapabilities', 'HostDatastoreSystemCapabilities', 0, 1],
    ['offloadCapabilities', 'HostNetOffloadCapabilities', 0, 1],
    ['service', 'HostServiceInfo', 0, 1],
    ['firewall', 'HostFirewallInfo', 0, 1],
    ['autoStart', 'HostAutoStartManagerConfig', 0, 1],
    ['activeDiagnosticPartition', 'HostDiagnosticPartition', 0, 1],
    ['option', 'OptionValue', 1, 1],
    ['optionDef', 'OptionDef', 1, 1],
    ['datastorePrincipal', undef, 0, 1],
    ['localSwapDatastore', 'ManagedObjectReference', 0, 1],
    ['systemSwapConfiguration', 'HostSystemSwapConfiguration', 0, 1],
    ['systemResources', 'HostSystemResourceInfo', 0, 1],
    ['dateTimeInfo', 'HostDateTimeInfo', 0, 1],
    ['flags', 'HostFlagInfo', 0, 1],
    ['adminDisabled', 'boolean', 0, 1],
    ['lockdownMode', 'HostLockdownMode', 0, 1],
    ['ipmi', 'HostIpmiInfo', 0, 1],
    ['sslThumbprintInfo', 'HostSslThumbprintInfo', 0, 1],
    ['sslThumbprintData', 'HostSslThumbprintInfo', 1, 1],
    ['certificate', undef, 1, 1],
    ['pciPassthruInfo', 'HostPciPassthruInfo', 1, 1],
    ['authenticationManagerInfo', 'HostAuthenticationManagerInfo', 0, 1],
    ['featureVersion', 'HostFeatureVersionInfo', 1, 1],
    ['powerSystemCapability', 'PowerSystemCapability', 0, 1],
    ['powerSystemInfo', 'PowerSystemInfo', 0, 1],
    ['cacheConfigurationInfo', 'HostCacheConfigurationInfo', 1, 1],
    ['wakeOnLanCapable', 'boolean', 0, 1],
    ['featureCapability', 'HostFeatureCapability', 1, 1],
    ['maskedFeatureCapability', 'HostFeatureCapability', 1, 1],
    ['vFlashConfigInfo', 'HostVFlashManagerVFlashConfigInfo', 0, 1],
    ['vsanHostConfig', 'VsanHostConfigInfo', 0, 1],
    ['domainList', undef, 1, 1],
    ['scriptCheckSum', undef, 0, 1],
    ['hostConfigCheckSum', undef, 0, 1],
    ['graphicsInfo', 'HostGraphicsInfo', 1, 1],
    ['sharedPassthruGpuTypes', undef, 1, 1],
    ['graphicsConfig', 'HostGraphicsConfig', 0, 1],
    ['ioFilterInfo', 'HostIoFilterInfo', 1, 1],
    ['sriovDevicePool', 'HostSriovDevicePoolInfo', 1, 1],
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
