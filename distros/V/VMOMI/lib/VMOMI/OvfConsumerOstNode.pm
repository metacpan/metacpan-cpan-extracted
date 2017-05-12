package VMOMI::OvfConsumerOstNode;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['type', undef, 0, ],
    ['section', 'OvfConsumerOvfSection', 1, 1],
    ['child', 'OvfConsumerOstNode', 1, 1],
    ['entity', 'ManagedObjectReference', 0, 1],
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
