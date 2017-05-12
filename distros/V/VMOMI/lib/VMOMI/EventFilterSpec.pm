package VMOMI::EventFilterSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['entity', 'EventFilterSpecByEntity', 0, 1],
    ['time', 'EventFilterSpecByTime', 0, 1],
    ['userName', 'EventFilterSpecByUsername', 0, 1],
    ['eventChainId', undef, 0, 1],
    ['alarm', 'ManagedObjectReference', 0, 1],
    ['scheduledTask', 'ManagedObjectReference', 0, 1],
    ['disableFullMessage', 'boolean', 0, 1],
    ['category', undef, 1, 1],
    ['type', undef, 1, 1],
    ['tag', undef, 1, 1],
    ['eventTypeId', undef, 1, 1],
    ['maxCount', undef, 0, 1],
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
