package VMOMI::NoPermissionOnNasVolume;
use parent 'VMOMI::NasConfigFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'NasConfigFault',
    'HostConfigFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['userName', undef, 0, 1],
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
