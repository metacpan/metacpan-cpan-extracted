package VMOMI::DrsExitedStandbyModeEvent;
use parent 'VMOMI::ExitedStandbyModeEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'ExitedStandbyModeEvent',
    'HostEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( );

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
