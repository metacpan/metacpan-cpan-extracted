package VMOMI::CustomizationPrefixName;
use parent 'VMOMI::CustomizationName';

use strict;
use warnings;

our @class_ancestors = ( 
    'CustomizationName',
    'DynamicData',
);

our @class_members = ( 
    ['base', undef, 0, ],
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
