package VMOMI::GatewayToHostAuthFault;
use parent 'VMOMI::GatewayToHostConnectFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'GatewayToHostConnectFault',
    'GatewayConnectFault',
    'HostConnectFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['invalidProperties', undef, 1, ],
    ['missingProperties', undef, 1, ],
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
