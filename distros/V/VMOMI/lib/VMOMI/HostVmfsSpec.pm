package VMOMI::HostVmfsSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['extent', 'HostScsiDiskPartition', 0, ],
    ['blockSizeMb', undef, 0, 1],
    ['majorVersion', undef, 0, ],
    ['volumeName', undef, 0, ],
    ['blockSize', undef, 0, 1],
    ['unmapGranularity', undef, 0, 1],
    ['unmapPriority', undef, 0, 1],
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
