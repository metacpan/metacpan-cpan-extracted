package VMOMI::HostNatServiceNameServiceSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dnsAutoDetect', 'boolean', 0, ],
    ['dnsPolicy', undef, 0, ],
    ['dnsRetries', undef, 0, ],
    ['dnsTimeout', undef, 0, ],
    ['dnsNameServer', undef, 1, 1],
    ['nbdsTimeout', undef, 0, ],
    ['nbnsRetries', undef, 0, ],
    ['nbnsTimeout', undef, 0, ],
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
