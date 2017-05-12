package VMOMI::VAppCloneSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['location', 'ManagedObjectReference', 0, ],
    ['host', 'ManagedObjectReference', 0, 1],
    ['resourceSpec', 'ResourceConfigSpec', 0, 1],
    ['vmFolder', 'ManagedObjectReference', 0, 1],
    ['networkMapping', 'VAppCloneSpecNetworkMappingPair', 1, 1],
    ['property', 'KeyValue', 1, 1],
    ['resourceMapping', 'VAppCloneSpecResourceMap', 1, 1],
    ['provisioning', undef, 0, 1],
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
