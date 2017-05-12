package VMOMI::CannotAccessVmDevice;
use parent 'VMOMI::CannotAccessVmComponent';

use strict;
use warnings;

our @class_ancestors = ( 
    'CannotAccessVmComponent',
    'VmConfigFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['device', undef, 0, ],
    ['backing', undef, 0, ],
    ['connected', 'boolean', 0, ],
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
