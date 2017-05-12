package VMOMI::OvfPropertyValue;
use parent 'VMOMI::OvfProperty';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfProperty',
    'OvfInvalidPackage',
    'OvfFault',
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
