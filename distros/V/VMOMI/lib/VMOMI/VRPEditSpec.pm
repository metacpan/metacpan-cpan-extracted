package VMOMI::VRPEditSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vrpId', undef, 0, ],
    ['description', undef, 0, 1],
    ['cpuAllocation', 'VrpResourceAllocationInfo', 0, 1],
    ['memoryAllocation', 'VrpResourceAllocationInfo', 0, 1],
    ['addedHubs', 'ManagedObjectReference', 1, 1],
    ['removedHubs', 'ManagedObjectReference', 1, 1],
    ['changeVersion', undef, 0, 1],
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
