package VMOMI::ResourcePool;
use parent 'VMOMI::ManagedEntity';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['childConfiguration', 'ResourceConfigSpec', 1, 0],
    ['config', 'ResourceConfigSpec', 0, 1],
    ['owner', 'ManagedObjectReference ', 0, 1],
    ['resourcePool', 'ManagedObjectReference', 1, 0],
    ['runtime', 'ResourcePoolRuntimeInfo', 0, 1],
    ['summary', 'ResourcePoolSummary', 0, 1],
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
