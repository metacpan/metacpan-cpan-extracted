package VMOMI::AlarmTriggeringAction;
use parent 'VMOMI::AlarmAction';

use strict;
use warnings;

our @class_ancestors = ( 
    'AlarmAction',
    'DynamicData',
);

our @class_members = ( 
    ['action', 'Action', 0, ],
    ['transitionSpecs', 'AlarmTriggeringActionTransitionSpec', 1, 1],
    ['green2yellow', 'boolean', 0, ],
    ['yellow2red', 'boolean', 0, ],
    ['red2yellow', 'boolean', 0, ],
    ['yellow2green', 'boolean', 0, ],
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
