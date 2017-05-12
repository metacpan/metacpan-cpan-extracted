package VMOMI::HostIpRouteConfigSpec;
use parent 'VMOMI::HostIpRouteConfig';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostIpRouteConfig',
    'DynamicData',
);

our @class_members = ( 
    ['gatewayDeviceConnection', 'HostVirtualNicConnection', 0, 1],
    ['ipV6GatewayDeviceConnection', 'HostVirtualNicConnection', 0, 1],
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
