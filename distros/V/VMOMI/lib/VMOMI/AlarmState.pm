package VMOMI::AlarmState;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['entity', 'ManagedObjectReference', 0, ],
    ['alarm', 'ManagedObjectReference', 0, ],
    ['overallStatus', 'ManagedEntityStatus', 0, ],
    ['time', undef, 0, ],
    ['acknowledged', 'boolean', 0, 1],
    ['acknowledgedByUser', undef, 0, 1],
    ['acknowledgedTime', undef, 0, 1],
    ['eventKey', undef, 0, 1],
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
