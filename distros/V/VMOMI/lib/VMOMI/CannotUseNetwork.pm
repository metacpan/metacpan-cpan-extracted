package VMOMI::CannotUseNetwork;
use parent 'VMOMI::VmConfigFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'VmConfigFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['device', undef, 0, ],
    ['backing', undef, 0, ],
    ['connected', 'boolean', 0, ],
    ['reason', undef, 0, ],
    ['network', 'ManagedObjectReference', 0, 1],
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
