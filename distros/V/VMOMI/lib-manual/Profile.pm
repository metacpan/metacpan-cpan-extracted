package VMOMI::Profile;
use parent 'VMOMI::ManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedObject',
);

our @class_members = (
    ['complianceStatus', undef, 0, 1],
    ['config', 'rofileConfigInfo', 0, 1],
    ['createdTime', undef, 0, 1],
    ['description', 'ProfileDescription', 0, 0],
    ['entity', 'ManagedObjectReference', 1, 0],
    ['modifiedTime', undef, 0, 1],
    ['name', undef, 0, 1],
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