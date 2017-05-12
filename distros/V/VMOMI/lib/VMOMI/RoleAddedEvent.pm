package VMOMI::RoleAddedEvent;
use parent 'VMOMI::RoleEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'RoleEvent',
    'AuthorizationEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['privilegeList', undef, 1, 1],
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
