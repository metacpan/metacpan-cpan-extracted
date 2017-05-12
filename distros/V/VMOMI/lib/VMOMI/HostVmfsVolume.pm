package VMOMI::HostVmfsVolume;
use parent 'VMOMI::HostFileSystemVolume';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostFileSystemVolume',
    'DynamicData',
);

our @class_members = ( 
    ['blockSizeMb', undef, 0, ],
    ['blockSize', undef, 0, 1],
    ['unmapGranularity', undef, 0, 1],
    ['unmapPriority', undef, 0, 1],
    ['maxBlocks', undef, 0, ],
    ['majorVersion', undef, 0, ],
    ['version', undef, 0, ],
    ['uuid', undef, 0, ],
    ['extent', 'HostScsiDiskPartition', 1, ],
    ['vmfsUpgradable', 'boolean', 0, ],
    ['forceMountedInfo', 'HostForceMountedInfo', 0, 1],
    ['ssd', 'boolean', 0, 1],
    ['local', 'boolean', 0, 1],
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
