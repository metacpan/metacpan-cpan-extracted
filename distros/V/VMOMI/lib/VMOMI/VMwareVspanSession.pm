package VMOMI::VMwareVspanSession;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['name', undef, 0, 1],
    ['description', undef, 0, 1],
    ['enabled', 'boolean', 0, ],
    ['sourcePortTransmitted', 'VMwareVspanPort', 0, 1],
    ['sourcePortReceived', 'VMwareVspanPort', 0, 1],
    ['destinationPort', 'VMwareVspanPort', 0, 1],
    ['encapsulationVlanId', undef, 0, 1],
    ['stripOriginalVlan', 'boolean', 0, ],
    ['mirroredPacketLength', undef, 0, 1],
    ['normalTrafficAllowed', 'boolean', 0, ],
    ['sessionType', undef, 0, 1],
    ['samplingRate', undef, 0, 1],
    ['encapType', undef, 0, 1],
    ['erspanId', undef, 0, 1],
    ['erspanCOS', undef, 0, 1],
    ['erspanGraNanosec', 'boolean', 0, 1],
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
