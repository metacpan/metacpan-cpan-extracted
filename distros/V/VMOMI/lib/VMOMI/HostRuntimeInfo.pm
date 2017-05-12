package VMOMI::HostRuntimeInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['connectionState', 'HostSystemConnectionState', 0, ],
    ['powerState', 'HostSystemPowerState', 0, ],
    ['standbyMode', undef, 0, 1],
    ['inMaintenanceMode', 'boolean', 0, ],
    ['inQuarantineMode', 'boolean', 0, 1],
    ['bootTime', undef, 0, 1],
    ['healthSystemRuntime', 'HealthSystemRuntime', 0, 1],
    ['dasHostState', 'ClusterDasFdmHostState', 0, 1],
    ['tpmPcrValues', 'HostTpmDigestInfo', 1, 1],
    ['vsanRuntimeInfo', 'VsanHostRuntimeInfo', 0, 1],
    ['networkRuntimeInfo', 'HostRuntimeInfoNetworkRuntimeInfo', 0, 1],
    ['vFlashResourceRuntimeInfo', 'HostVFlashManagerVFlashResourceRunTimeInfo', 0, 1],
    ['hostMaxVirtualDiskCapacity', undef, 0, 1],
    ['cryptoState', undef, 0, 1],
    ['cryptoKeyId', 'CryptoKeyId', 0, 1],
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
