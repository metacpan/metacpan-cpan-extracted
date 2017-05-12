package VMOMI::NetDnsConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['dhcp', 'boolean', 0, ],
    ['hostName', undef, 0, ],
    ['domainName', undef, 0, ],
    ['ipAddress', undef, 1, 1],
    ['searchDomain', undef, 1, 1],
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
