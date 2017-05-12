package VMOMI::InsufficientVFlashResourcesFault;
use parent 'VMOMI::InsufficientResourcesFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'InsufficientResourcesFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['freeSpaceInMB', undef, 0, 1],
    ['freeSpace', undef, 0, ],
    ['requestedSpaceInMB', undef, 0, 1],
    ['requestedSpace', undef, 0, ],
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
