package VMOMI::UserNotFound;
use parent 'VMOMI::VimFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['principal', undef, 0, ],
    ['unresolved', 'boolean', 0, ],
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
