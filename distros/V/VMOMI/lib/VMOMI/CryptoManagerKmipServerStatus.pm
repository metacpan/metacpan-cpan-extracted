package VMOMI::CryptoManagerKmipServerStatus;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['status', 'ManagedEntityStatus', 0, ],
    ['connectionStatus', undef, 0, ],
    ['certInfo', 'CryptoManagerKmipCertificateInfo', 0, 1],
    ['clientTrustServer', 'boolean', 0, 1],
    ['serverTrustClient', 'boolean', 0, 1],
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
