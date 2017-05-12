package VMOMI::HostHardwareInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['systemInfo', 'HostSystemInfo', 0, ],
    ['cpuPowerManagementInfo', 'HostCpuPowerManagementInfo', 0, 1],
    ['cpuInfo', 'HostCpuInfo', 0, ],
    ['cpuPkg', 'HostCpuPackage', 1, ],
    ['memorySize', undef, 0, ],
    ['numaInfo', 'HostNumaInfo', 0, 1],
    ['smcPresent', 'boolean', 0, 1],
    ['pciDevice', 'HostPciDevice', 1, 1],
    ['cpuFeature', 'HostCpuIdInfo', 1, 1],
    ['biosInfo', 'HostBIOSInfo', 0, 1],
    ['reliableMemoryInfo', 'HostReliableMemoryInfo', 0, 1],
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
