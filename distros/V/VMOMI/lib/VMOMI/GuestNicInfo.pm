package VMOMI::GuestNicInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['network', undef, 0, 1],
    ['ipAddress', undef, 1, 1],
    ['macAddress', undef, 0, 1],
    ['connected', 'boolean', 0, ],
    ['deviceConfigId', undef, 0, ],
    ['dnsConfig', 'NetDnsConfigInfo', 0, 1],
    ['ipConfig', 'NetIpConfigInfo', 0, 1],
    ['netBIOSConfig', 'NetBIOSConfigInfo', 0, 1],
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
