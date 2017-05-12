package VMOMI::VAppConfigInfo;
use parent 'VMOMI::VmConfigInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmConfigInfo',
    'DynamicData',
);

our @class_members = ( 
    ['entityConfig', 'VAppEntityConfigInfo', 1, 1],
    ['annotation', undef, 0, ],
    ['instanceUuid', undef, 0, 1],
    ['managedBy', 'ManagedByInfo', 0, 1],
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
