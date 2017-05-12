package VMOMI::FcoeConfigFcoeSpecification;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['underlyingPnic', undef, 0, ],
    ['priorityClass', undef, 0, 1],
    ['sourceMac', undef, 0, 1],
    ['vlanRange', 'FcoeConfigVlanRange', 1, 1],
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
