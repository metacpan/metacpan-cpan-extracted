package VMOMI::FilterInUse;
use parent 'VMOMI::ResourceInUse';

use strict;
use warnings;

our @class_ancestors = ( 
    'ResourceInUse',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['disk', 'VirtualDiskId', 1, 1],
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
