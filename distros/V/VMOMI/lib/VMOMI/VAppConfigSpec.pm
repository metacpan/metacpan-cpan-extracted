package VMOMI::VAppConfigSpec;
use parent 'VMOMI::VmConfigSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmConfigSpec',
    'DynamicData',
);

our @class_members = ( 
    ['entityConfig', 'VAppEntityConfigInfo', 1, 1],
    ['annotation', undef, 0, 1],
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
