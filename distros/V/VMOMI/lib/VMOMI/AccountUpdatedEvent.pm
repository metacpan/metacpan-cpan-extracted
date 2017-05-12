package VMOMI::AccountUpdatedEvent;
use parent 'VMOMI::HostEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['spec', 'HostAccountSpec', 0, ],
    ['group', 'boolean', 0, ],
    ['prevDescription', undef, 0, 1],
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
