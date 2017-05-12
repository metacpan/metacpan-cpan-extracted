package VMOMI::VirtualMachineConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['changeVersion', undef, 0, ],
    ['modified', undef, 0, ],
    ['name', undef, 0, ],
    ['guestFullName', undef, 0, ],
    ['version', undef, 0, ],
    ['uuid', undef, 0, ],
    ['instanceUuid', undef, 0, 1],
    ['npivNodeWorldWideName', undef, 1, 1],
    ['npivPortWorldWideName', undef, 1, 1],
    ['npivWorldWideNameType', undef, 0, 1],
    ['npivDesiredNodeWwns', undef, 0, 1],
    ['npivDesiredPortWwns', undef, 0, 1],
    ['npivTemporaryDisabled', 'boolean', 0, 1],
    ['npivOnNonRdmDisks', 'boolean', 0, 1],
    ['locationId', undef, 0, 1],
    ['template', 'boolean', 0, ],
    ['guestId', undef, 0, ],
    ['alternateGuestName', undef, 0, ],
    ['annotation', undef, 0, 1],
    ['files', 'VirtualMachineFileInfo', 0, ],
    ['tools', 'ToolsConfigInfo', 0, 1],
    ['flags', 'VirtualMachineFlagInfo', 0, ],
    ['consolePreferences', 'VirtualMachineConsolePreferences', 0, 1],
    ['defaultPowerOps', 'VirtualMachineDefaultPowerOpInfo', 0, ],
    ['hardware', 'VirtualHardware', 0, ],
    ['cpuAllocation', 'ResourceAllocationInfo', 0, 1],
    ['memoryAllocation', 'ResourceAllocationInfo', 0, 1],
    ['latencySensitivity', 'LatencySensitivity', 0, 1],
    ['memoryHotAddEnabled', 'boolean', 0, 1],
    ['cpuHotAddEnabled', 'boolean', 0, 1],
    ['cpuHotRemoveEnabled', 'boolean', 0, 1],
    ['hotPlugMemoryLimit', undef, 0, 1],
    ['hotPlugMemoryIncrementSize', undef, 0, 1],
    ['cpuAffinity', 'VirtualMachineAffinityInfo', 0, 1],
    ['memoryAffinity', 'VirtualMachineAffinityInfo', 0, 1],
    ['networkShaper', 'VirtualMachineNetworkShaperInfo', 0, 1],
    ['extraConfig', 'OptionValue', 1, 1],
    ['cpuFeatureMask', 'HostCpuIdInfo', 1, 1],
    ['datastoreUrl', 'VirtualMachineConfigInfoDatastoreUrlPair', 1, 1],
    ['swapPlacement', undef, 0, 1],
    ['bootOptions', 'VirtualMachineBootOptions', 0, 1],
    ['ftInfo', 'FaultToleranceConfigInfo', 0, 1],
    ['repConfig', 'ReplicationConfigSpec', 0, 1],
    ['vAppConfig', 'VmConfigInfo', 0, 1],
    ['vAssertsEnabled', 'boolean', 0, 1],
    ['changeTrackingEnabled', 'boolean', 0, 1],
    ['firmware', undef, 0, 1],
    ['maxMksConnections', undef, 0, 1],
    ['guestAutoLockEnabled', 'boolean', 0, 1],
    ['managedBy', 'ManagedByInfo', 0, 1],
    ['memoryReservationLockedToMax', 'boolean', 0, 1],
    ['initialOverhead', 'VirtualMachineConfigInfoOverheadInfo', 0, 1],
    ['nestedHVEnabled', 'boolean', 0, 1],
    ['vPMCEnabled', 'boolean', 0, 1],
    ['scheduledHardwareUpgradeInfo', 'ScheduledHardwareUpgradeInfo', 0, 1],
    ['forkConfigInfo', 'VirtualMachineForkConfigInfo', 0, 1],
    ['vFlashCacheReservation', undef, 0, 1],
    ['vmxConfigChecksum', undef, 0, 1],
    ['messageBusTunnelEnabled', 'boolean', 0, 1],
    ['vmStorageObjectId', undef, 0, 1],
    ['swapStorageObjectId', undef, 0, 1],
    ['keyId', 'CryptoKeyId', 0, 1],
    ['guestIntegrityInfo', 'VirtualMachineGuestIntegrityInfo', 0, 1],
    ['migrateEncryption', undef, 0, 1],
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
