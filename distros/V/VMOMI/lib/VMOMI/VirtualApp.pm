package VMOMI::VirtualApp;
use parent 'VMOMI::ResourcePool';

use strict;
use warnings;

our @class_ancestors = (
    'ResourcePool',
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);


our @class_members = ( 
    ['childLink', 'VirtualAppLinkInfo', 1, 0],
    ['datastore', 'ManagedObjectReference', 1, 0],
    ['network', 'ManagedObjectReference', 1, 0],
    ['parentFolder', 'ManagedObjectReference', 0, 0],
    ['parentVApp', 'ManagedObjectReference', 0, 0],
    ['vAppConfig', 'VAppConfigInfo', 0, 0],
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
