package VMOMI::InventoryDescription;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['numHosts', undef, 0, ],
    ['numVirtualMachines', undef, 0, ],
    ['numResourcePools', undef, 0, 1],
    ['numClusters', undef, 0, 1],
    ['numCpuDev', undef, 0, 1],
    ['numNetDev', undef, 0, 1],
    ['numDiskDev', undef, 0, 1],
    ['numvCpuDev', undef, 0, 1],
    ['numvNetDev', undef, 0, 1],
    ['numvDiskDev', undef, 0, 1],
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
