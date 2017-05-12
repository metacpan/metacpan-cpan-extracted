package VMOMI::DistributedVirtualPortgroup;
use parent 'VMOMI::Network';

use strict;
use warnings;

our @class_ancestors = (
    'Network',
    'ManagedEntity',
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['config', 'DVPortgroupConfigInfo', 0, 1],
    ['key', undef, 0, 1],
    ['portKeys', undef, 1, 0],
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
