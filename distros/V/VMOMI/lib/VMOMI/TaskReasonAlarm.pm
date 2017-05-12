package VMOMI::TaskReasonAlarm;
use parent 'VMOMI::TaskReason';

use strict;
use warnings;

our @class_ancestors = ( 
    'TaskReason',
    'DynamicData',
);

our @class_members = ( 
    ['alarmName', undef, 0, ],
    ['alarm', 'ManagedObjectReference', 0, ],
    ['entityName', undef, 0, ],
    ['entity', 'ManagedObjectReference', 0, ],
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
