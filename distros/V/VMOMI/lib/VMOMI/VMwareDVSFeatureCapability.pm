package VMOMI::VMwareDVSFeatureCapability;
use parent 'VMOMI::DVSFeatureCapability';

use strict;
use warnings;

our @class_ancestors = ( 
    'DVSFeatureCapability',
    'DynamicData',
);

our @class_members = ( 
    ['vspanSupported', 'boolean', 0, 1],
    ['lldpSupported', 'boolean', 0, 1],
    ['ipfixSupported', 'boolean', 0, 1],
    ['ipfixCapability', 'VMwareDvsIpfixCapability', 0, 1],
    ['multicastSnoopingSupported', 'boolean', 0, 1],
    ['vspanCapability', 'VMwareDVSVspanCapability', 0, 1],
    ['lacpCapability', 'VMwareDvsLacpCapability', 0, 1],
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
