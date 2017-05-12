package VMOMI::DVSCapability;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dvsOperationSupported', 'boolean', 0, 1],
    ['dvPortGroupOperationSupported', 'boolean', 0, 1],
    ['dvPortOperationSupported', 'boolean', 0, 1],
    ['compatibleHostComponentProductInfo', 'DistributedVirtualSwitchHostProductSpec', 1, 1],
    ['featuresSupported', 'DVSFeatureCapability', 0, 1],
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
