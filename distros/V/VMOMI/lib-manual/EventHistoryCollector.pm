package VMOMI::EventHistoryCollector;
use parent 'VMOMI::HistoryCollector';

use strict;
use warnings;

our @class_members = (
    ['latestPage', 'Event', 1, 0],
);

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;