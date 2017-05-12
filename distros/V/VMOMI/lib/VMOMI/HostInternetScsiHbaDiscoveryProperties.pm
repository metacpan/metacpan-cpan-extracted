package VMOMI::HostInternetScsiHbaDiscoveryProperties;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['iSnsDiscoveryEnabled', 'boolean', 0, ],
    ['iSnsDiscoveryMethod', undef, 0, 1],
    ['iSnsHost', undef, 0, 1],
    ['slpDiscoveryEnabled', 'boolean', 0, ],
    ['slpDiscoveryMethod', undef, 0, 1],
    ['slpHost', undef, 0, 1],
    ['staticTargetDiscoveryEnabled', 'boolean', 0, ],
    ['sendTargetsDiscoveryEnabled', 'boolean', 0, ],
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
