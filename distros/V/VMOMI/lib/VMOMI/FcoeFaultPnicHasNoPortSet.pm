package VMOMI::FcoeFaultPnicHasNoPortSet;
use parent 'VMOMI::FcoeFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'FcoeFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['nicDevice', undef, 0, ],
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
