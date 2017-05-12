package VMOMI::HostVirtualSwitch;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['key', undef, 0, ],
    ['numPorts', undef, 0, ],
    ['numPortsAvailable', undef, 0, ],
    ['mtu', undef, 0, 1],
    ['portgroup', undef, 1, 1],
    ['pnic', undef, 1, 1],
    ['spec', 'HostVirtualSwitchSpec', 0, ],
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
