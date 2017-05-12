package VMOMI::HostScsiDisk;
use parent 'VMOMI::ScsiLun';

use strict;
use warnings;

our @class_ancestors = ( 
    'ScsiLun',
    'HostDevice',
    'DynamicData',
);

our @class_members = ( 
    ['capacity', 'HostDiskDimensionsLba', 0, ],
    ['devicePath', undef, 0, ],
    ['ssd', 'boolean', 0, 1],
    ['localDisk', 'boolean', 0, 1],
    ['physicalLocation', undef, 1, 1],
    ['emulatedDIXDIFEnabled', 'boolean', 0, 1],
    ['vsanDiskInfo', 'VsanHostVsanDiskInfo', 0, 1],
    ['scsiDiskType', undef, 0, 1],
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
