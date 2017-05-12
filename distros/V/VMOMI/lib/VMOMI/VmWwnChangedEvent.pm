package VMOMI::VmWwnChangedEvent;
use parent 'VMOMI::VmEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['oldNodeWwns', undef, 1, 1],
    ['oldPortWwns', undef, 1, 1],
    ['newNodeWwns', undef, 1, 1],
    ['newPortWwns', undef, 1, 1],
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
