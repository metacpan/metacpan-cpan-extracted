package VMOMI::CryptoManagerKmipCertificateInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['subject', undef, 0, ],
    ['issuer', undef, 0, ],
    ['serialNumber', undef, 0, ],
    ['notBefore', undef, 0, ],
    ['notAfter', undef, 0, ],
    ['fingerprint', undef, 0, ],
    ['checkTime', undef, 0, ],
    ['secondsSinceValid', undef, 0, 1],
    ['secondsBeforeExpire', undef, 0, 1],
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
