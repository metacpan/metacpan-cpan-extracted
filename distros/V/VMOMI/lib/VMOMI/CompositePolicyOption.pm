package VMOMI::CompositePolicyOption;
use parent 'VMOMI::PolicyOption';

use strict;
use warnings;

our @class_ancestors = ( 
    'PolicyOption',
    'DynamicData',
);

our @class_members = ( 
    ['option', 'PolicyOption', 1, 1],
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
