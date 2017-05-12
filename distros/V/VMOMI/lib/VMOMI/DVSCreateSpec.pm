package VMOMI::DVSCreateSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['configSpec', 'DVSConfigSpec', 0, ],
    ['productInfo', 'DistributedVirtualSwitchProductSpec', 0, 1],
    ['capability', 'DVSCapability', 0, 1],
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
