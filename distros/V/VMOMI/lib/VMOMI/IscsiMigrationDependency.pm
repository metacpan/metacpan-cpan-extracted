package VMOMI::IscsiMigrationDependency;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['migrationAllowed', 'boolean', 0, ],
    ['disallowReason', 'IscsiStatus', 0, 1],
    ['dependency', 'IscsiDependencyEntity', 1, 1],
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
