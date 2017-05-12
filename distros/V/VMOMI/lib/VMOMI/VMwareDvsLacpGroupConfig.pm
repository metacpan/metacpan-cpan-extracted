package VMOMI::VMwareDvsLacpGroupConfig;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['name', undef, 0, 1],
    ['mode', undef, 0, 1],
    ['uplinkNum', undef, 0, 1],
    ['loadbalanceAlgorithm', undef, 0, 1],
    ['vlan', 'VMwareDvsLagVlanConfig', 0, 1],
    ['ipfix', 'VMwareDvsLagIpfixConfig', 0, 1],
    ['uplinkName', undef, 1, 1],
    ['uplinkPortKey', undef, 1, 1],
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
