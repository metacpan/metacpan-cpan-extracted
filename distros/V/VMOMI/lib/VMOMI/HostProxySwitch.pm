package VMOMI::HostProxySwitch;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dvsUuid', undef, 0, ],
    ['dvsName', undef, 0, ],
    ['key', undef, 0, ],
    ['numPorts', undef, 0, ],
    ['configNumPorts', undef, 0, 1],
    ['numPortsAvailable', undef, 0, ],
    ['uplinkPort', 'KeyValue', 1, 1],
    ['mtu', undef, 0, 1],
    ['pnic', undef, 1, 1],
    ['spec', 'HostProxySwitchSpec', 0, ],
    ['hostLag', 'HostProxySwitchHostLagConfig', 1, 1],
    ['networkReservationSupported', 'boolean', 0, 1],
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
