package VMOMI::ServiceInstance;
use parent 'VMOMI::ManagedObject';

use strict;
use warnings;

our @class_ancestors = (
    'ManagedObject',
);

our @class_members = (
    ['capability', 'Capability', 0, 1],
    ['content', 'ServiceContent', 0, 1],
    ['serverClock', undef, 0, 1],
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