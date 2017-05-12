package VMOMI::MismatchedBundle;
use parent 'VMOMI::VimFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['bundleUuid', undef, 0, ],
    ['hostUuid', undef, 0, ],
    ['bundleBuildNumber', undef, 0, ],
    ['hostBuildNumber', undef, 0, ],
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
