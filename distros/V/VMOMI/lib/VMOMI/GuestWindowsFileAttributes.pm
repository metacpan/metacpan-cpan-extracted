package VMOMI::GuestWindowsFileAttributes;
use parent 'VMOMI::GuestFileAttributes';

use strict;
use warnings;

our @class_ancestors = ( 
    'GuestFileAttributes',
    'DynamicData',
);

our @class_members = ( 
    ['hidden', 'boolean', 0, 1],
    ['readOnly', 'boolean', 0, 1],
    ['createTime', undef, 0, 1],
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
