package VMOMI::DistributedVirtualSwitchPortCriteria;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['connected', 'boolean', 0, 1],
    ['active', 'boolean', 0, 1],
    ['uplinkPort', 'boolean', 0, 1],
    ['scope', 'ManagedObjectReference', 0, 1],
    ['portgroupKey', undef, 1, 1],
    ['inside', 'boolean', 0, 1],
    ['portKey', undef, 1, 1],
    ['host', 'ManagedObjectReference', 1, 1],
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
