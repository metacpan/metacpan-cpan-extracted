package VMOMI::GuestRegistryValueNotFound;
use parent 'VMOMI::GuestRegistryValueFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'GuestRegistryValueFault',
    'GuestRegistryFault',
    'GuestOperationsFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( );

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
