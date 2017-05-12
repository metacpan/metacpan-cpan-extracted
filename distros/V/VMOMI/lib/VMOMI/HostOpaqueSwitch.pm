package VMOMI::HostOpaqueSwitch;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['name', undef, 0, 1],
    ['pnic', undef, 1, 1],
    ['pnicZone', 'HostOpaqueSwitchPhysicalNicZone', 1, 1],
    ['status', undef, 0, 1],
    ['vtep', 'HostVirtualNic', 1, 1],
    ['extraConfig', 'OptionValue', 1, 1],
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
