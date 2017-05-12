package VMOMI::IpPool;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, 1],
    ['name', undef, 0, 1],
    ['ipv4Config', 'IpPoolIpPoolConfigInfo', 0, 1],
    ['ipv6Config', 'IpPoolIpPoolConfigInfo', 0, 1],
    ['dnsDomain', undef, 0, 1],
    ['dnsSearchPath', undef, 0, 1],
    ['hostPrefix', undef, 0, 1],
    ['httpProxy', undef, 0, 1],
    ['networkAssociation', 'IpPoolAssociation', 1, 1],
    ['availableIpv4Addresses', undef, 0, 1],
    ['availableIpv6Addresses', undef, 0, 1],
    ['allocatedIpv4Addresses', undef, 0, 1],
    ['allocatedIpv6Addresses', undef, 0, 1],
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
