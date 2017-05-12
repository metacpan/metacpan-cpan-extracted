package VMOMI::HostPortGroup;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['port', 'HostPortGroupPort', 1, 1],
    ['vswitch', undef, 0, 1],
    ['computedPolicy', 'HostNetworkPolicy', 0, ],
    ['spec', 'HostPortGroupSpec', 0, ],
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
