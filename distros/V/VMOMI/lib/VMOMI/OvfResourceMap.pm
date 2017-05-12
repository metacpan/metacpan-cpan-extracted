package VMOMI::OvfResourceMap;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['source', undef, 0, ],
    ['parent', 'ManagedObjectReference', 0, 1],
    ['resourceSpec', 'ResourceConfigSpec', 0, 1],
    ['datastore', 'ManagedObjectReference', 0, 1],
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
