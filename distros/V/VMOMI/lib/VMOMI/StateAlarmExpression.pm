package VMOMI::StateAlarmExpression;
use parent 'VMOMI::AlarmExpression';

use strict;
use warnings;

our @class_ancestors = ( 
    'AlarmExpression',
    'DynamicData',
);

our @class_members = ( 
    ['operator', 'StateAlarmOperator', 0, ],
    ['type', undef, 0, ],
    ['statePath', undef, 0, ],
    ['yellow', undef, 0, 1],
    ['red', undef, 0, 1],
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
