package VMOMI::HostDhcpServiceSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['virtualSwitch', undef, 0, ],
    ['defaultLeaseDuration', undef, 0, ],
    ['leaseBeginIp', undef, 0, ],
    ['leaseEndIp', undef, 0, ],
    ['maxLeaseDuration', undef, 0, ],
    ['unlimitedLease', 'boolean', 0, ],
    ['ipSubnetAddr', undef, 0, ],
    ['ipSubnetMask', undef, 0, ],
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
