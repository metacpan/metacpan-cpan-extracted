package VMOMI::GatewayConnectFault;
use parent 'VMOMI::HostConnectFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostConnectFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['gatewayType', undef, 0, ],
    ['gatewayId', undef, 0, ],
    ['gatewayInfo', undef, 0, ],
    ['details', 'LocalizableMessage', 0, 1],
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
