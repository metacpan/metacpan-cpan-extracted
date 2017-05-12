package VMOMI::VrpResourceAllocationInfo;
use parent 'VMOMI::ResourceAllocationInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'ResourceAllocationInfo',
    'DynamicData',
);

our @class_members = ( 
    ['reservationLimit', undef, 0, 1],
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
