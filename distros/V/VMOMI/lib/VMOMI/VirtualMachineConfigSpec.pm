package VMOMI::VirtualMachineConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['changeVersion', undef, 0, 1],
    ['name', undef, 0, 1],
    ['version', undef, 0, 1],
    ['uuid', undef, 0, 1],
    ['instanceUuid', undef, 0, 1],
    ['npivNodeWorldWideName', undef, 1, 1],
    ['npivPortWorldWideName', undef, 1, 1],
    ['npivWorldWideNameType', undef, 0, 1],
    ['npivDesiredNodeWwns', undef, 0, 1],
    ['npivDesiredPortWwns', undef, 0, 1],
    ['npivTemporaryDisabled', 'boolean', 0, 1],
    ['npivOnNonRdmDisks', 'boolean', 0, 1],
    ['npivWorldWideNameOp', undef, 0, 1],
    ['locationId', undef, 0, 1],
    ['guestId', undef, 0, 1],
    ['alternateGuestName', undef, 0, 1],
    ['annotation', undef, 0, 1],
    ['files', 'VirtualMachineFileInfo', 0, 1],
    ['tools', 'ToolsConfigInfo', 0, 1],
    ['flags', 'VirtualMachineFlagInfo', 0, 1],
    ['consolePreferences', 'VirtualMachineConsolePreferences', 0, 1],
    ['powerOpInfo', 'VirtualMachineDefaultPowerOpInfo', 0, 1],
    ['numCPUs', undef, 0, 1],
    ['numCoresPerSocket', undef, 0, 1],
    ['memoryMB', undef, 0, 1],
    ['memoryHotAddEnabled', 'boolean', 0, 1],
    ['cpuHotAddEnabled', 'boolean', 0, 1],
    ['cpuHotRemoveEnabled', 'boolean', 0, 1],
    ['virtualICH7MPresent', 'boolean', 0, 1],
    ['virtualSMCPresent', 'boolean', 0, 1],
    ['deviceChange', 'VirtualDeviceConfigSpec', 1, 1],
    ['cpuAllocation', 'ResourceAllocationInfo', 0, 1],
    ['memoryAllocation', 'ResourceAllocationInfo', 0, 1],
    ['latencySensitivity', 'LatencySensitivity', 0, 1],
    ['cpuAffinity', 'VirtualMachineAffinityInfo', 0, 1],
    ['memoryAffinity', 'VirtualMachineAffinityInfo', 0, 1],
    ['networkShaper', 'VirtualMachineNetworkShaperInfo', 0, 1],
    ['cpuFeatureMask', 'VirtualMachineCpuIdInfoSpec', 1, 1],
    ['extraConfig', 'OptionValue', 1, 1],
    ['swapPlacement', undef, 0, 1],
    ['bootOptions', 'VirtualMachineBootOptions', 0, 1],
    ['vAppConfig', 'VmConfigSpec', 0, 1],
    ['ftInfo', 'FaultToleranceConfigInfo', 0, 1],
    ['repConfig', 'ReplicationConfigSpec', 0, 1],
    ['vAppConfigRemoved', 'boolean', 0, 1],
    ['vAssertsEnabled', 'boolean', 0, 1],
    ['changeTrackingEnabled', 'boolean', 0, 1],
    ['firmware', undef, 0, 1],
    ['maxMksConnections', undef, 0, 1],
    ['guestAutoLockEnabled', 'boolean', 0, 1],
    ['managedBy', 'ManagedByInfo', 0, 1],
    ['memoryReservationLockedToMax', 'boolean', 0, 1],
    ['nestedHVEnabled', 'boolean', 0, 1],
    ['vPMCEnabled', 'boolean', 0, 1],
    ['scheduledHardwareUpgradeInfo', 'ScheduledHardwareUpgradeInfo', 0, 1],
    ['vmProfile', 'VirtualMachineProfileSpec', 1, 1],
    ['messageBusTunnelEnabled', 'boolean', 0, 1],
    ['crypto', 'CryptoSpec', 0, 1],
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
