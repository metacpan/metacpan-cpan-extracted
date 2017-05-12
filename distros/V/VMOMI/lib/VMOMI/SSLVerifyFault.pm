package VMOMI::SSLVerifyFault;
use parent 'VMOMI::HostConnectFault';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostConnectFault',
    'VimFault',
    'MethodFault',
);

our @class_members = ( 
    ['selfSigned', 'boolean', 0, ],
    ['thumbprint', undef, 0, ],
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
