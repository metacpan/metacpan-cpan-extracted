package VMOMI::HostCertificateManagerCertificateInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['issuer', undef, 0, 1],
    ['notBefore', undef, 0, 1],
    ['notAfter', undef, 0, 1],
    ['subject', undef, 0, 1],
    ['status', undef, 0, ],
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
