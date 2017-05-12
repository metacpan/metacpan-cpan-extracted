package VMOMI::VirtualMachineFlagInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['disableAcceleration', 'boolean', 0, 1],
    ['enableLogging', 'boolean', 0, 1],
    ['useToe', 'boolean', 0, 1],
    ['runWithDebugInfo', 'boolean', 0, 1],
    ['monitorType', undef, 0, 1],
    ['htSharing', undef, 0, 1],
    ['snapshotDisabled', 'boolean', 0, 1],
    ['snapshotLocked', 'boolean', 0, 1],
    ['diskUuidEnabled', 'boolean', 0, 1],
    ['virtualMmuUsage', undef, 0, 1],
    ['virtualExecUsage', undef, 0, 1],
    ['snapshotPowerOffBehavior', undef, 0, 1],
    ['recordReplayEnabled', 'boolean', 0, 1],
    ['faultToleranceType', undef, 0, 1],
    ['cbrcCacheEnabled', 'boolean', 0, 1],
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
