package VMOMI::TaskFilterSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entity', 'TaskFilterSpecByEntity', 0, 1],
    ['time', 'TaskFilterSpecByTime', 0, 1],
    ['userName', 'TaskFilterSpecByUsername', 0, 1],
    ['activationId', undef, 1, 1],
    ['state', 'TaskInfoState', 1, 1],
    ['alarm', 'ManagedObjectReference', 0, 1],
    ['scheduledTask', 'ManagedObjectReference', 0, 1],
    ['eventChainId', undef, 1, 1],
    ['tag', undef, 1, 1],
    ['parentTaskKey', undef, 1, 1],
    ['rootTaskKey', undef, 1, 1],
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
