package VMOMI::DVSTrafficShapingPolicy;
use parent 'VMOMI::InheritablePolicy';

use strict;
use warnings;

our @class_ancestors = ( 
    'InheritablePolicy',
    'DynamicData',
);

our @class_members = ( 
    ['enabled', 'BoolPolicy', 0, 1],
    ['averageBandwidth', 'LongPolicy', 0, 1],
    ['peakBandwidth', 'LongPolicy', 0, 1],
    ['burstSize', 'LongPolicy', 0, 1],
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
