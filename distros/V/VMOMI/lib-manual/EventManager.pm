package VMOMI::EventManager;
use parent 'VMOMI::ManagedObject';

use strict;
use warnings;

our @class_members = (
    ['description', 'EventDescription', 0, 1],
    ['latestEvent', 'Event', 0, 0],
    ['maxCollector', undef, 0, 1],
);

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;