package VMOMI::GuestOperationsManager;
use parent 'VMOMI::ManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedObject',
);

our @class_members = (
    ['aliasManager', 'ManagedObjectReference', 0, 0],
    ['authManager', 'ManagedObjectReference', 0, 0],
    ['fileManager', 'ManagedObjectReference', 0, 0],
    ['guestWindowsRegistryManager', 'ManagedObjectReference', 0, 0],
    ['processManager', 'ManagedObjectReference', 0, 0],   
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
