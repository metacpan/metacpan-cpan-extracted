package VMOMI::IpPoolIpPoolConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['subnetAddress', undef, 0, 1],
    ['netmask', undef, 0, 1],
    ['gateway', undef, 0, 1],
    ['range', undef, 0, 1],
    ['dns', undef, 1, 1],
    ['dhcpServerAvailable', 'boolean', 0, 1],
    ['ipPoolEnabled', 'boolean', 0, 1],
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
