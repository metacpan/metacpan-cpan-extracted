package VMOMI::PhysicalNicCdpDeviceCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['router', 'boolean', 0, ],
    ['transparentBridge', 'boolean', 0, ],
    ['sourceRouteBridge', 'boolean', 0, ],
    ['networkSwitch', 'boolean', 0, ],
    ['host', 'boolean', 0, ],
    ['igmpEnabled', 'boolean', 0, ],
    ['repeater', 'boolean', 0, ],
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
