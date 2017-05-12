package VMOMI::VMwareDVSPortSetting;
use parent 'VMOMI::DVPortSetting';

use strict;
use warnings;

our @class_ancestors = ( 
    'DVPortSetting',
    'DynamicData',
);

our @class_members = ( 
    ['vlan', 'VmwareDistributedVirtualSwitchVlanSpec', 0, 1],
    ['qosTag', 'IntPolicy', 0, 1],
    ['uplinkTeamingPolicy', 'VmwareUplinkPortTeamingPolicy', 0, 1],
    ['securityPolicy', 'DVSSecurityPolicy', 0, 1],
    ['ipfixEnabled', 'BoolPolicy', 0, 1],
    ['txUplink', 'BoolPolicy', 0, 1],
    ['lacpPolicy', 'VMwareUplinkLacpPolicy', 0, 1],
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
