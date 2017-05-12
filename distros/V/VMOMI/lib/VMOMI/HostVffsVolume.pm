package VMOMI::HostVffsVolume;
use parent 'VMOMI::HostFileSystemVolume';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostFileSystemVolume',
    'DynamicData',
);

our @class_members = ( 
    ['majorVersion', undef, 0, ],
    ['version', undef, 0, ],
    ['uuid', undef, 0, ],
    ['extent', 'HostScsiDiskPartition', 1, ],
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
