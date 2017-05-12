package VMOMI::CustomFieldDef;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['name', undef, 0, ],
    ['type', undef, 0, ],
    ['managedObjectType', undef, 0, 1],
    ['fieldDefPrivileges', 'PrivilegePolicyDef', 0, 1],
    ['fieldInstancePrivileges', 'PrivilegePolicyDef', 0, 1],
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
