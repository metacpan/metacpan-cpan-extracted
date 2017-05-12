package VMOMI::ClusterDrsMigration;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['time', undef, 0, ],
    ['vm', 'ManagedObjectReference', 0, ],
    ['cpuLoad', undef, 0, 1],
    ['memoryLoad', undef, 0, 1],
    ['source', 'ManagedObjectReference', 0, ],
    ['sourceCpuLoad', undef, 0, 1],
    ['sourceMemoryLoad', undef, 0, 1],
    ['destination', 'ManagedObjectReference', 0, ],
    ['destinationCpuLoad', undef, 0, 1],
    ['destinationMemoryLoad', undef, 0, 1],
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
