package VMOMI::HostActiveDirectorySpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['domainName', undef, 0, 1],
    ['userName', undef, 0, 1],
    ['password', undef, 0, 1],
    ['camServer', undef, 0, 1],
    ['thumbprint', undef, 0, 1],
    ['smartCardAuthenticationEnabled', 'boolean', 0, 1],
    ['smartCardTrustAnchors', undef, 1, 1],
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
