package VMOMI::OvfUnsupportedAttribute;
use parent 'VMOMI::OvfUnsupportedPackage';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfUnsupportedPackage',
    'OvfFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['elementName', undef, 0, ],
    ['attributeName', undef, 0, ],
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
