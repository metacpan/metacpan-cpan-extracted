package VMOMI::ScheduledTaskInfo;
use parent 'VMOMI::ScheduledTaskSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'ScheduledTaskSpec',
    'DynamicData',
);

our @class_members = ( 
    ['scheduledTask', 'ManagedObjectReference', 0, ],
    ['entity', 'ManagedObjectReference', 0, ],
    ['lastModifiedTime', undef, 0, ],
    ['lastModifiedUser', undef, 0, ],
    ['nextRunTime', undef, 0, 1],
    ['prevRunTime', undef, 0, 1],
    ['state', 'TaskInfoState', 0, ],
    ['error', 'LocalizedMethodFault', 0, 1],
    ['result', 'anyType', 0, 1],
    ['progress', undef, 0, 1],
    ['activeTask', 'ManagedObjectReference', 0, 1],
    ['taskObject', 'ManagedObjectReference', 0, 1],
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
