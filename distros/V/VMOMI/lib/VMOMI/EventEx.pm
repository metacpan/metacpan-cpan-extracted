package VMOMI::EventEx;
use parent 'VMOMI::Event';

use strict;
use warnings;

our @class_ancestors = ( 
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['eventTypeId', undef, 0, ],
    ['severity', undef, 0, 1],
    ['message', undef, 0, 1],
    ['arguments', 'KeyAnyValue', 1, 1],
    ['objectId', undef, 0, 1],
    ['objectType', undef, 0, 1],
    ['objectName', undef, 0, 1],
    ['fault', 'LocalizedMethodFault', 0, 1],
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
