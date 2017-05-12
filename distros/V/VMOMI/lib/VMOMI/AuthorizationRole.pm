package VMOMI::AuthorizationRole;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['roleId', undef, 0, ],
    ['system', 'boolean', 0, ],
    ['name', undef, 0, ],
    ['info', 'Description', 0, ],
    ['privilege', undef, 1, 1],
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
