package VMOMI::InvalidProfileReferenceHost;
use parent 'VMOMI::RuntimeFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'RuntimeFault',
    'MethodFault',
);

our @class_members = ( 
    ['reason', undef, 0, 1],
    ['host', 'ManagedObjectReference', 0, 1],
    ['profile', 'ManagedObjectReference', 0, 1],
    ['profileName', undef, 0, 1],
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
