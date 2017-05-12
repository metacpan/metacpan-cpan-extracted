package VMOMI::MountError;
use parent 'VMOMI::CustomizationFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'CustomizationFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['vm', 'ManagedObjectReference', 0, ],
    ['diskIndex', undef, 0, ],
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
