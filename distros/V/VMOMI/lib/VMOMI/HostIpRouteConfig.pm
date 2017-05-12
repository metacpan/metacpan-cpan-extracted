package VMOMI::HostIpRouteConfig;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['defaultGateway', undef, 0, 1],
    ['gatewayDevice', undef, 0, 1],
    ['ipV6DefaultGateway', undef, 0, 1],
    ['ipV6GatewayDevice', undef, 0, 1],
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
