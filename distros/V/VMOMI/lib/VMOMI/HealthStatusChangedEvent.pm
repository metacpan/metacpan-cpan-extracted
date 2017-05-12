package VMOMI::HealthStatusChangedEvent;
use parent 'VMOMI::Event';

use strict;
use warnings;

our @class_ancestors = ( 
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['componentId', undef, 0, ],
    ['oldStatus', undef, 0, ],
    ['newStatus', undef, 0, ],
    ['componentName', undef, 0, ],
    ['serviceId', undef, 0, 1],
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
