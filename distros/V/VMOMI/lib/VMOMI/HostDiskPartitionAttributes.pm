package VMOMI::HostDiskPartitionAttributes;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['partition', undef, 0, ],
    ['startSector', undef, 0, ],
    ['endSector', undef, 0, ],
    ['type', undef, 0, ],
    ['guid', undef, 0, 1],
    ['logical', 'boolean', 0, ],
    ['attributes', undef, 0, ],
    ['partitionAlignment', undef, 0, 1],
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
