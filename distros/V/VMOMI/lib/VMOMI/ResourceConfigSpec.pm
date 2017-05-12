package VMOMI::ResourceConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entity', 'ManagedObjectReference', 0, 1],
    ['changeVersion', undef, 0, 1],
    ['lastModified', undef, 0, 1],
    ['cpuAllocation', 'ResourceAllocationInfo', 0, ],
    ['memoryAllocation', 'ResourceAllocationInfo', 0, ],
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
