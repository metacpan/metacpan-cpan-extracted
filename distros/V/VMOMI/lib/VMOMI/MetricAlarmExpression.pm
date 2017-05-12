package VMOMI::MetricAlarmExpression;
use parent 'VMOMI::AlarmExpression';

use strict;
use warnings;

our @class_ancestors = ( 
    'AlarmExpression',
    'DynamicData',
);

our @class_members = ( 
    ['operator', 'MetricAlarmOperator', 0, ],
    ['type', undef, 0, ],
    ['metric', 'PerfMetricId', 0, ],
    ['yellow', undef, 0, 1],
    ['yellowInterval', undef, 0, 1],
    ['red', undef, 0, 1],
    ['redInterval', undef, 0, 1],
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
