package VMOMI::VirtualMachineCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['snapshotOperationsSupported', 'boolean', 0, ],
    ['multipleSnapshotsSupported', 'boolean', 0, ],
    ['snapshotConfigSupported', 'boolean', 0, ],
    ['poweredOffSnapshotsSupported', 'boolean', 0, ],
    ['memorySnapshotsSupported', 'boolean', 0, ],
    ['revertToSnapshotSupported', 'boolean', 0, ],
    ['quiescedSnapshotsSupported', 'boolean', 0, ],
    ['disableSnapshotsSupported', 'boolean', 0, ],
    ['lockSnapshotsSupported', 'boolean', 0, ],
    ['consolePreferencesSupported', 'boolean', 0, ],
    ['cpuFeatureMaskSupported', 'boolean', 0, ],
    ['s1AcpiManagementSupported', 'boolean', 0, ],
    ['settingScreenResolutionSupported', 'boolean', 0, ],
    ['toolsAutoUpdateSupported', 'boolean', 0, ],
    ['vmNpivWwnSupported', 'boolean', 0, ],
    ['npivWwnOnNonRdmVmSupported', 'boolean', 0, ],
    ['vmNpivWwnDisableSupported', 'boolean', 0, 1],
    ['vmNpivWwnUpdateSupported', 'boolean', 0, 1],
    ['swapPlacementSupported', 'boolean', 0, ],
    ['toolsSyncTimeSupported', 'boolean', 0, ],
    ['virtualMmuUsageSupported', 'boolean', 0, ],
    ['diskSharesSupported', 'boolean', 0, ],
    ['bootOptionsSupported', 'boolean', 0, ],
    ['bootRetryOptionsSupported', 'boolean', 0, 1],
    ['settingVideoRamSizeSupported', 'boolean', 0, ],
    ['settingDisplayTopologySupported', 'boolean', 0, 1],
    ['recordReplaySupported', 'boolean', 0, 1],
    ['changeTrackingSupported', 'boolean', 0, 1],
    ['multipleCoresPerSocketSupported', 'boolean', 0, 1],
    ['hostBasedReplicationSupported', 'boolean', 0, 1],
    ['guestAutoLockSupported', 'boolean', 0, 1],
    ['memoryReservationLockSupported', 'boolean', 0, 1],
    ['featureRequirementSupported', 'boolean', 0, 1],
    ['poweredOnMonitorTypeChangeSupported', 'boolean', 0, 1],
    ['seSparseDiskSupported', 'boolean', 0, 1],
    ['nestedHVSupported', 'boolean', 0, 1],
    ['vPMCSupported', 'boolean', 0, 1],
    ['secureBootSupported', 'boolean', 0, 1],
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
