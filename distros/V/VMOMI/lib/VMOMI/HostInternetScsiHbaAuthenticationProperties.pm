package VMOMI::HostInternetScsiHbaAuthenticationProperties;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['chapAuthEnabled', 'boolean', 0, ],
    ['chapName', undef, 0, 1],
    ['chapSecret', undef, 0, 1],
    ['chapAuthenticationType', undef, 0, 1],
    ['chapInherited', 'boolean', 0, 1],
    ['mutualChapName', undef, 0, 1],
    ['mutualChapSecret', undef, 0, 1],
    ['mutualChapAuthenticationType', undef, 0, 1],
    ['mutualChapInherited', 'boolean', 0, 1],
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
