package VMOMI::HostNetworkSystem;
use parent 'VMOMI::ExtensibleManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = (
    ['capabilities', 'HostNetCapabilities', 0, 0],
    ['consoleIpRouteConfig', 'HostIpRouteConfig', 0, 0],
    ['dnsConfig', 'HostDnsConfig', 0, 0],
    ['ipRouteConfig', 'HostIpRouteConfig', 0, 0],
    ['networkConfig', 'HostNetworkConfig', 0, 0],
    ['networkInfo', 'HostNetworkInfo', 0, 0],
    ['offloadCapabilities', 'HostNetOffloadCapabilities', 0, 0],
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