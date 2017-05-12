package VMOMI::MigrationHostErrorEvent;
use parent 'VMOMI::MigrationEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'MigrationEvent',
    'VmEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['dstHost', 'HostEventArgument', 0, ],
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
