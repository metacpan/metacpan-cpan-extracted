package VMOMI::VirtualMachineRuntimeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['device', 'VirtualMachineDeviceRuntimeInfo', 1, 1],
    ['host', 'ManagedObjectReference', 0, 1],
    ['connectionState', 'VirtualMachineConnectionState', 0, ],
    ['powerState', 'VirtualMachinePowerState', 0, ],
    ['faultToleranceState', 'VirtualMachineFaultToleranceState', 0, 1],
    ['dasVmProtection', 'VirtualMachineRuntimeInfoDasProtectionState', 0, 1],
    ['toolsInstallerMounted', 'boolean', 0, ],
    ['suspendTime', undef, 0, 1],
    ['bootTime', undef, 0, 1],
    ['suspendInterval', undef, 0, 1],
    ['question', 'VirtualMachineQuestionInfo', 0, 1],
    ['memoryOverhead', undef, 0, 1],
    ['maxCpuUsage', undef, 0, 1],
    ['maxMemoryUsage', undef, 0, 1],
    ['numMksConnections', undef, 0, ],
    ['recordReplayState', 'VirtualMachineRecordReplayState', 0, 1],
    ['cleanPowerOff', 'boolean', 0, 1],
    ['needSecondaryReason', undef, 0, 1],
    ['onlineStandby', 'boolean', 0, 1],
    ['minRequiredEVCModeKey', undef, 0, 1],
    ['consolidationNeeded', 'boolean', 0, 1],
    ['offlineFeatureRequirement', 'VirtualMachineFeatureRequirement', 1, 1],
    ['featureRequirement', 'VirtualMachineFeatureRequirement', 1, 1],
    ['featureMask', 'HostFeatureMask', 1, 1],
    ['vFlashCacheAllocation', undef, 0, 1],
    ['paused', 'boolean', 0, 1],
    ['snapshotInBackground', 'boolean', 0, 1],
    ['quiescedForkParent', 'boolean', 0, 1],
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
