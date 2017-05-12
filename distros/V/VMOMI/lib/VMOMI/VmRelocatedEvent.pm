package VMOMI::VmRelocatedEvent;
use parent 'VMOMI::VmRelocateSpecEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmRelocateSpecEvent',
    'VmEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['sourceHost', 'HostEventArgument', 0, ],
    ['sourceDatacenter', 'DatacenterEventArgument', 0, 1],
    ['sourceDatastore', 'DatastoreEventArgument', 0, 1],
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
