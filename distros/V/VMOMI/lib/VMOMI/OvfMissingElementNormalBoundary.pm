package VMOMI::OvfMissingElementNormalBoundary;
use parent 'VMOMI::OvfMissingElement';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfMissingElement',
    'OvfElement',
    'OvfInvalidPackage',
    'OvfFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['boundary', undef, 0, ],
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
