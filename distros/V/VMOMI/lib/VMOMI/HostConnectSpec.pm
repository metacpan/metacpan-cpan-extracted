package VMOMI::HostConnectSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['hostName', undef, 0, 1],
    ['port', undef, 0, 1],
    ['sslThumbprint', undef, 0, 1],
    ['userName', undef, 0, 1],
    ['password', undef, 0, 1],
    ['vmFolder', 'ManagedObjectReference', 0, 1],
    ['force', 'boolean', 0, ],
    ['vimAccountName', undef, 0, 1],
    ['vimAccountPassword', undef, 0, 1],
    ['managementIp', undef, 0, 1],
    ['lockdownMode', 'HostLockdownMode', 0, 1],
    ['hostGateway', 'HostGatewaySpec', 0, 1],
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
