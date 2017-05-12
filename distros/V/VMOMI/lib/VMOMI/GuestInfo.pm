package VMOMI::GuestInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['toolsStatus', 'VirtualMachineToolsStatus', 0, 1],
    ['toolsVersionStatus', undef, 0, 1],
    ['toolsVersionStatus2', undef, 0, 1],
    ['toolsRunningStatus', undef, 0, 1],
    ['toolsVersion', undef, 0, 1],
    ['toolsInstallType', undef, 0, 1],
    ['guestId', undef, 0, 1],
    ['guestFamily', undef, 0, 1],
    ['guestFullName', undef, 0, 1],
    ['hostName', undef, 0, 1],
    ['ipAddress', undef, 0, 1],
    ['net', 'GuestNicInfo', 1, 1],
    ['ipStack', 'GuestStackInfo', 1, 1],
    ['disk', 'GuestDiskInfo', 1, 1],
    ['screen', 'GuestScreenInfo', 0, 1],
    ['guestState', undef, 0, ],
    ['appHeartbeatStatus', undef, 0, 1],
    ['guestKernelCrashed', 'boolean', 0, 1],
    ['appState', undef, 0, 1],
    ['guestOperationsReady', 'boolean', 0, 1],
    ['interactiveGuestOperationsReady', 'boolean', 0, 1],
    ['guestStateChangeSupported', 'boolean', 0, 1],
    ['generationInfo', 'GuestInfoNamespaceGenerationInfo', 1, 1],
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
