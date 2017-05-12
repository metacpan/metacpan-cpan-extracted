package VMOMI::PhysicalNicHintInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['device', undef, 0, ],
    ['subnet', 'PhysicalNicIpHint', 1, 1],
    ['network', 'PhysicalNicNameHint', 1, 1],
    ['connectedSwitchPort', 'PhysicalNicCdpInfo', 0, 1],
    ['lldpInfo', 'LinkLayerDiscoveryProtocolInfo', 0, 1],
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
