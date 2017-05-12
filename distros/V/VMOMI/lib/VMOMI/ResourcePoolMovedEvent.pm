package VMOMI::ResourcePoolMovedEvent;
use parent 'VMOMI::ResourcePoolEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'ResourcePoolEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['oldParent', 'ResourcePoolEventArgument', 0, ],
    ['newParent', 'ResourcePoolEventArgument', 0, ],
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
