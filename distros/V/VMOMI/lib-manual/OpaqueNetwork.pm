package VMOMI::OpaqueNetwork;
use parent 'VMOMI::Network';

use strict;
use warnings;

our @class_ancestors = (
    'Network',
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( );

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
