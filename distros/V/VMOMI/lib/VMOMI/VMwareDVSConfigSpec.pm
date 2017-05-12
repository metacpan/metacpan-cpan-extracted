package VMOMI::VMwareDVSConfigSpec;
use parent 'VMOMI::DVSConfigSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'DVSConfigSpec',
    'DynamicData',
);

our @class_members = ( 
    ['pvlanConfigSpec', 'VMwareDVSPvlanConfigSpec', 1, 1],
    ['vspanConfigSpec', 'VMwareDVSVspanConfigSpec', 1, 1],
    ['maxMtu', undef, 0, 1],
    ['linkDiscoveryProtocolConfig', 'LinkDiscoveryProtocolConfig', 0, 1],
    ['ipfixConfig', 'VMwareIpfixConfig', 0, 1],
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
