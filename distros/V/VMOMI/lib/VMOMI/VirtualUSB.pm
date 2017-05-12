package VMOMI::VirtualUSB;
use parent 'VMOMI::VirtualDevice';

use strict;
use warnings;

our @class_ancestors = ( 
    'VirtualDevice',
    'DynamicData',
);

our @class_members = ( 
    ['connected', 'boolean', 0, ],
    ['vendor', undef, 0, 1],
    ['product', undef, 0, 1],
    ['family', undef, 1, 1],
    ['speed', undef, 1, 1],
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
