package VMOMI::ManagedObjectView;
use parent 'VMOMI::View';

use strict;
use warnings;

our @class_ancestors = (
    'View',
    'ManagedObject',
);

our @class_members = (
    ['view', 'ManagedObjectReference', 1, 0], 
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