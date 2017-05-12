package VMOMI::Event;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['chainId', undef, 0, ],
    ['createdTime', undef, 0, ],
    ['userName', undef, 0, ],
    ['datacenter', 'DatacenterEventArgument', 0, 1],
    ['computeResource', 'ComputeResourceEventArgument', 0, 1],
    ['host', 'HostEventArgument', 0, 1],
    ['vm', 'VmEventArgument', 0, 1],
    ['ds', 'DatastoreEventArgument', 0, 1],
    ['net', 'NetworkEventArgument', 0, 1],
    ['dvs', 'DvsEventArgument', 0, 1],
    ['fullFormattedMessage', undef, 0, 1],
    ['changeTag', undef, 0, 1],
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
