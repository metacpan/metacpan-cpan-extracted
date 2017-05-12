package VMOMI::VAppPropertyFault;
use parent 'VMOMI::VmConfigFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmConfigFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['category', undef, 0, ],
    ['label', undef, 0, ],
    ['type', undef, 0, ],
    ['value', undef, 0, ],
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
