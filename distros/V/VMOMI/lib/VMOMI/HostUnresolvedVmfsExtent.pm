package VMOMI::HostUnresolvedVmfsExtent;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['device', 'HostScsiDiskPartition', 0, ],
    ['devicePath', undef, 0, ],
    ['vmfsUuid', undef, 0, ],
    ['isHeadExtent', 'boolean', 0, ],
    ['ordinal', undef, 0, ],
    ['startBlock', undef, 0, ],
    ['endBlock', undef, 0, ],
    ['reason', undef, 0, ],
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
