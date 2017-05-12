package VMOMI::ComputeResource;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['configurationEx', 'ComputeResourceConfigInfo', 0, 1],
    ['datastore', 'ManagedObjectReference', 1, 0],
    ['environmentBrowser', 'ManagedObjectReference', 0, 0],
    ['host', 'ManagedObjectReference', 1, 0],
    ['network', 'ManagedObjectReference', 1, 0],
    ['resourcePool', 'ManagedObjectReference', 0, 0],
    ['summary', 'ComputeResourceSummary', 0, 1],
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
