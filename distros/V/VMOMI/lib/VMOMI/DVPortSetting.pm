package VMOMI::DVPortSetting;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['blocked', 'BoolPolicy', 0, 1],
    ['vmDirectPathGen2Allowed', 'BoolPolicy', 0, 1],
    ['inShapingPolicy', 'DVSTrafficShapingPolicy', 0, 1],
    ['outShapingPolicy', 'DVSTrafficShapingPolicy', 0, 1],
    ['vendorSpecificConfig', 'DVSVendorSpecificConfig', 0, 1],
    ['networkResourcePoolKey', 'StringPolicy', 0, 1],
    ['filterPolicy', 'DvsFilterPolicy', 0, 1],
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
