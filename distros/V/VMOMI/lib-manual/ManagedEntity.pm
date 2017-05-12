package VMOMI::ManagedEntity;
use parent 'VMOMI::ExtensibleManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ExtensibleManagedObject',
    'ManagedObject',
);

our @class_members = ( 
    ['parent', 'ManagedEntity', 0, 0],
    ['customValue', 'CustomFieldValue', 1, 0],
    ['overallStatus', undef, 0, 0],
    ['configStatus', undef, 0, 0],
    ['configIssue', 'Event', 1, 0],
    ['effectiveRole', undef, 1, 0],
    ['permission', 'Permission', 1, 0],
    ['name', undef, 1, 0],
    ['disabledMethod', undef, 1, 0],
    ['recentTask', 'Task', 1, 0],
    ['declaredAlarmState', 'AlarmState', 1, 0],
    ['triggeredAlarmState', 'AlarmState', 1, 0],
    ['alarmActionsEnabled', undef, 0, 1],
    ['tag', 'Tag', 1, 0],
);

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

sub TO_JSON {
    my $self = shift;
    my $this = { };
    my @ancestors = $self->get_class_ancestors();
    
    return $self->{'moref'};
}

1;
