package VMOMI::TraversalSpec;
use parent 'VMOMI::SelectionSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'SelectionSpec',
    'DynamicData',
);

our @class_members = ( 
    ['type', undef, 0, ],
    ['path', undef, 0, ],
    ['skip', 'boolean', 0, 1],
    ['selectSet', 'SelectionSpec', 1, 1],
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
