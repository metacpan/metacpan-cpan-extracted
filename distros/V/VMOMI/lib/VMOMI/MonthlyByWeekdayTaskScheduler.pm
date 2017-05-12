package VMOMI::MonthlyByWeekdayTaskScheduler;
use parent 'VMOMI::MonthlyTaskScheduler';

use strict;
use warnings;

our @class_ancestors = ( 
    'MonthlyTaskScheduler',
    'DailyTaskScheduler',
    'HourlyTaskScheduler',
    'RecurrentTaskScheduler',
    'TaskScheduler',
    'DynamicData',
);

our @class_members = ( 
    ['offset', 'WeekOfMonth', 0, ],
    ['weekday', 'DayOfWeek', 0, ],
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
