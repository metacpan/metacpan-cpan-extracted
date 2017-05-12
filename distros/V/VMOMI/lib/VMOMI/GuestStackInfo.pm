package VMOMI::GuestStackInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dnsConfig', 'NetDnsConfigInfo', 0, 1],
    ['ipRouteConfig', 'NetIpRouteConfigInfo', 0, 1],
    ['ipStackConfig', 'KeyValue', 1, 1],
    ['dhcpConfig', 'NetDhcpConfigInfo', 0, 1],
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
