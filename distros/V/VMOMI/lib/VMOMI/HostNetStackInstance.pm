package VMOMI::HostNetStackInstance;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['name', undef, 0, 1],
    ['dnsConfig', 'HostDnsConfig', 0, 1],
    ['ipRouteConfig', 'HostIpRouteConfig', 0, 1],
    ['requestedMaxNumberOfConnections', undef, 0, 1],
    ['congestionControlAlgorithm', undef, 0, 1],
    ['ipV6Enabled', 'boolean', 0, 1],
    ['routeTableConfig', 'HostIpRouteTableConfig', 0, 1],
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
