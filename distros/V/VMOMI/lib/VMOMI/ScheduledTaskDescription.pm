package VMOMI::ScheduledTaskDescription;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['action', 'TypeDescription', 1, ],
    ['schedulerInfo', 'ScheduledTaskDetail', 1, ],
    ['state', 'ElementDescription', 1, ],
    ['dayOfWeek', 'ElementDescription', 1, ],
    ['weekOfMonth', 'ElementDescription', 1, ],
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
