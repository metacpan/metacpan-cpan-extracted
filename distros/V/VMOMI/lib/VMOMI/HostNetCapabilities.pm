package VMOMI::HostNetCapabilities;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['canSetPhysicalNicLinkSpeed', 'boolean', 0, ],
    ['supportsNicTeaming', 'boolean', 0, ],
    ['nicTeamingPolicy', undef, 1, 1],
    ['supportsVlan', 'boolean', 0, ],
    ['usesServiceConsoleNic', 'boolean', 0, ],
    ['supportsNetworkHints', 'boolean', 0, ],
    ['maxPortGroupsPerVswitch', undef, 0, 1],
    ['vswitchConfigSupported', 'boolean', 0, ],
    ['vnicConfigSupported', 'boolean', 0, ],
    ['ipRouteConfigSupported', 'boolean', 0, ],
    ['dnsConfigSupported', 'boolean', 0, ],
    ['dhcpOnVnicSupported', 'boolean', 0, ],
    ['ipV6Supported', 'boolean', 0, 1],
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
