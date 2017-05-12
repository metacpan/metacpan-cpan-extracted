package VMOMI::VmBeingMigratedEvent;
use parent 'VMOMI::VmEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['destHost', 'HostEventArgument', 0, ],
    ['destDatacenter', 'DatacenterEventArgument', 0, 1],
    ['destDatastore', 'DatastoreEventArgument', 0, 1],
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
