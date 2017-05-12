package VMOMI::EntityBackupConfig;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entityType', undef, 0, ],
    ['configBlob', undef, 0, ],
    ['key', undef, 0, 1],
    ['name', undef, 0, 1],
    ['container', 'ManagedObjectReference', 0, 1],
    ['configVersion', undef, 0, 1],
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
