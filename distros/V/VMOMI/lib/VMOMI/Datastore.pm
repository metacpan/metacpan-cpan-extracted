package VMOMI::Datastore;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['browser', 'ManagedObjectReference', 0, 1],
    ['capability', 'DatastoreCapability', 0, 1],
    ['host', 'DatastoreHostMount ', 1, 0],
    ['info', 'ManagedObjectReference ', 0, 1],
    ['network', 'DatastoreInfo', 0, 1],
    ['iormConfiguration', 'StorageIORMInfo ', 0, 0],
    ['summary', 'DatastoreSummary ', 0, 1],
    ['vm', 'ManagedObjectReference ', 1, 0],
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
