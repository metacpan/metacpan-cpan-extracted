package VMOMI::HostNatServiceSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['virtualSwitch', undef, 0, ],
    ['activeFtp', 'boolean', 0, ],
    ['allowAnyOui', 'boolean', 0, ],
    ['configPort', 'boolean', 0, ],
    ['ipGatewayAddress', undef, 0, ],
    ['udpTimeout', undef, 0, ],
    ['portForward', 'HostNatServicePortForwardSpec', 1, 1],
    ['nameService', 'HostNatServiceNameServiceSpec', 0, 1],
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
