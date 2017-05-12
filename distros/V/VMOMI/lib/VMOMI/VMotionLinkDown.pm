package VMOMI::VMotionLinkDown;
use parent 'VMOMI::VMotionInterfaceIssue';

use strict;
use warnings;

our @class_ancestors = ( 
    'VMotionInterfaceIssue',
    'MigrationFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['network', undef, 0, ],
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
