package VMOMI::CreateTaskAction;
use parent 'VMOMI::Action';

use strict;
use warnings;

our @class_ancestors = ( 
    'Action',
    'DynamicData',
);

our @class_members = ( 
    ['taskTypeId', undef, 0, ],
    ['cancelable', 'boolean', 0, ],
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
