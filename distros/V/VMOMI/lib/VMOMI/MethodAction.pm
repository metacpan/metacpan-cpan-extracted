package VMOMI::MethodAction;
use parent 'VMOMI::Action';

use strict;
use warnings;

our @class_ancestors = ( 
    'Action',
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['argument', 'MethodActionArgument', 1, 1],
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
