package VMOMI::DVPortgroupSelection;
use parent 'VMOMI::SelectionSet';

use strict;
use warnings;

our @class_ancestors = ( 
    'SelectionSet',
    'DynamicData',
);

our @class_members = ( 
    ['dvsUuid', undef, 0, ],
    ['portgroupKey', undef, 1, ],
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
