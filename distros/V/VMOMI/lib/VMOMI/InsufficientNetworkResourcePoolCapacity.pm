package VMOMI::InsufficientNetworkResourcePoolCapacity;
use parent 'VMOMI::InsufficientResourcesFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'InsufficientResourcesFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['dvsName', undef, 0, ],
    ['dvsUuid', undef, 0, ],
    ['resourcePoolKey', undef, 0, ],
    ['available', undef, 0, ],
    ['requested', undef, 0, ],
    ['device', undef, 1, ],
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
