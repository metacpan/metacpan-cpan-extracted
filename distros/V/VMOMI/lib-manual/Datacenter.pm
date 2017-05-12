package VMOMI::Datacenter;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['configuration', 'DatacenterConfigInfo', 0, 1],
    ['datastore', 'ManagedObjectReference', 1, 0],
    ['datastoreFolder', 'ManagedObjectReference ', 0, 1],
    ['hostFolder', 'ManagedObjectReference ', 0, 1],
    ['network', 'ManagedObjectReference', 1, 0],
    ['networkFolder', 'ManagedObjectReference ', 0, 1],
    ['vmFolder', 'ManagedObjectReference ', 0, 1],
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
