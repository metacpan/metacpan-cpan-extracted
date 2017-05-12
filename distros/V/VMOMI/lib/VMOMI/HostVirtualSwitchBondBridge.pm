package VMOMI::HostVirtualSwitchBondBridge;
use parent 'VMOMI::HostVirtualSwitchBridge';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostVirtualSwitchBridge',
    'DynamicData',
);

our @class_members = ( 
    ['nicDevice', undef, 1, ],
    ['beacon', 'HostVirtualSwitchBeaconConfig', 0, 1],
    ['linkDiscoveryProtocolConfig', 'LinkDiscoveryProtocolConfig', 0, 1],
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
