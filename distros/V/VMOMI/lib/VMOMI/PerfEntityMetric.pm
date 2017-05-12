package VMOMI::PerfEntityMetric;
use parent 'VMOMI::PerfEntityMetricBase';

use strict;
use warnings;

our @class_ancestors = ( 
    'PerfEntityMetricBase',
    'DynamicData',
);

our @class_members = ( 
    ['sampleInfo', 'PerfSampleInfo', 1, 1],
    ['value', 'PerfMetricSeries', 1, 1],
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
