package VMOMI::Network;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['host', 'ManagedObjectReference', 1, 0],
    ['name', undef, 0, 1],
    ['summary', 'NetworkSummary', 0, 1],
    ['vm', 'ManagedObjectReference', 1, 0],
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
