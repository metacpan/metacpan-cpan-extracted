package VMOMI::VirtualHardwareOption;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['hwVersion', undef, 0, ],
    ['virtualDeviceOption', 'VirtualDeviceOption', 1, ],
    ['deviceListReadonly', 'boolean', 0, ],
    ['numCPU', undef, 1, ],
    ['numCoresPerSocket', 'IntOption', 0, 1],
    ['numCpuReadonly', 'boolean', 0, ],
    ['memoryMB', 'LongOption', 0, ],
    ['numPCIControllers', 'IntOption', 0, ],
    ['numIDEControllers', 'IntOption', 0, ],
    ['numUSBControllers', 'IntOption', 0, ],
    ['numUSBXHCIControllers', 'IntOption', 0, 1],
    ['numSIOControllers', 'IntOption', 0, ],
    ['numPS2Controllers', 'IntOption', 0, ],
    ['licensingLimit', undef, 1, 1],
    ['numSupportedWwnPorts', 'IntOption', 0, 1],
    ['numSupportedWwnNodes', 'IntOption', 0, 1],
    ['resourceConfigOption', 'ResourceConfigOption', 0, 1],
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
