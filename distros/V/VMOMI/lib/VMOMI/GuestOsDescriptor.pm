package VMOMI::GuestOsDescriptor;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['family', undef, 0, ],
    ['fullName', undef, 0, ],
    ['supportedMaxCPUs', undef, 0, ],
    ['numSupportedPhysicalSockets', undef, 0, 1],
    ['numSupportedCoresPerSocket', undef, 0, 1],
    ['supportedMinMemMB', undef, 0, ],
    ['supportedMaxMemMB', undef, 0, ],
    ['recommendedMemMB', undef, 0, ],
    ['recommendedColorDepth', undef, 0, ],
    ['supportedDiskControllerList', undef, 1, ],
    ['recommendedSCSIController', undef, 0, 1],
    ['recommendedDiskController', undef, 0, ],
    ['supportedNumDisks', undef, 0, ],
    ['recommendedDiskSizeMB', undef, 0, ],
    ['recommendedCdromController', undef, 0, 1],
    ['supportedEthernetCard', undef, 1, ],
    ['recommendedEthernetCard', undef, 0, 1],
    ['supportsSlaveDisk', 'boolean', 0, 1],
    ['cpuFeatureMask', 'HostCpuIdInfo', 1, 1],
    ['smcRequired', 'boolean', 0, 1],
    ['supportsWakeOnLan', 'boolean', 0, ],
    ['supportsVMI', 'boolean', 0, 1],
    ['supportsMemoryHotAdd', 'boolean', 0, 1],
    ['supportsCpuHotAdd', 'boolean', 0, 1],
    ['supportsCpuHotRemove', 'boolean', 0, 1],
    ['supportedFirmware', undef, 1, 1],
    ['recommendedFirmware', undef, 0, 1],
    ['supportedUSBControllerList', undef, 1, 1],
    ['recommendedUSBController', undef, 0, 1],
    ['supports3D', 'boolean', 0, 1],
    ['recommended3D', 'boolean', 0, 1],
    ['smcRecommended', 'boolean', 0, 1],
    ['ich7mRecommended', 'boolean', 0, 1],
    ['usbRecommended', 'boolean', 0, 1],
    ['supportLevel', undef, 0, 1],
    ['supportedForCreate', 'boolean', 0, 1],
    ['vRAMSizeInKB', 'IntOption', 0, 1],
    ['numSupportedFloppyDevices', undef, 0, 1],
    ['wakeOnLanEthernetCard', undef, 1, 1],
    ['supportsPvscsiControllerForBoot', 'boolean', 0, 1],
    ['diskUuidEnabled', 'boolean', 0, 1],
    ['supportsHotPlugPCI', 'boolean', 0, 1],
    ['supportsSecureBoot', 'boolean', 0, 1],
    ['defaultSecureBoot', 'boolean', 0, 1],
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
