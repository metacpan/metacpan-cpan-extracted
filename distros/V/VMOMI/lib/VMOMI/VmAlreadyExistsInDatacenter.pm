package VMOMI::VmAlreadyExistsInDatacenter;
use parent 'VMOMI::InvalidFolder';

use strict;
use warnings;

our @class_ancestors = ( 
    'InvalidFolder',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['host', 'ManagedObjectReference', 0, ],
    ['hostname', undef, 0, ],
    ['vm', 'ManagedObjectReference', 1, ],
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
