package VMOMI::UnexpectedFault;
use parent 'VMOMI::RuntimeFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'RuntimeFault',
    'MethodFault',
);

our @class_members = ( 
    ['faultName', undef, 0, ],
    ['fault', 'LocalizedMethodFault', 0, 1],
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
