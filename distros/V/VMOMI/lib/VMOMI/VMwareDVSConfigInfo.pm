package VMOMI::VMwareDVSConfigInfo;
use parent 'VMOMI::DVSConfigInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'DVSConfigInfo',
    'DynamicData',
);

our @class_members = ( 
    ['vspanSession', 'VMwareVspanSession', 1, 1],
    ['pvlanConfig', 'VMwareDVSPvlanMapEntry', 1, 1],
    ['maxMtu', undef, 0, ],
    ['linkDiscoveryProtocolConfig', 'LinkDiscoveryProtocolConfig', 0, 1],
    ['ipfixConfig', 'VMwareIpfixConfig', 0, 1],
    ['lacpGroupConfig', 'VMwareDvsLacpGroupConfig', 1, 1],
    ['lacpApiVersion', undef, 0, 1],
    ['multicastFilteringMode', undef, 0, 1],
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
