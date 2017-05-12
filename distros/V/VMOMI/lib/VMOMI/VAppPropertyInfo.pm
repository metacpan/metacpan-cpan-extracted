package VMOMI::VAppPropertyInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['classId', undef, 0, 1],
    ['instanceId', undef, 0, 1],
    ['id', undef, 0, 1],
    ['category', undef, 0, 1],
    ['label', undef, 0, 1],
    ['type', undef, 0, 1],
    ['typeReference', undef, 0, 1],
    ['userConfigurable', 'boolean', 0, 1],
    ['defaultValue', undef, 0, 1],
    ['value', undef, 0, 1],
    ['description', undef, 0, 1],
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
