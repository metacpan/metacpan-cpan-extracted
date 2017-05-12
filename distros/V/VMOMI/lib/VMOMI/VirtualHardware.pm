package VMOMI::VirtualHardware;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['numCPU', undef, 0, ],
    ['numCoresPerSocket', undef, 0, 1],
    ['memoryMB', undef, 0, ],
    ['virtualICH7MPresent', 'boolean', 0, 1],
    ['virtualSMCPresent', 'boolean', 0, 1],
    ['device', 'VirtualDevice', 1, 1],
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
