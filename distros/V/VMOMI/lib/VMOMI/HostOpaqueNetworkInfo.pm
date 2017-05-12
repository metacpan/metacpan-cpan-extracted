package VMOMI::HostOpaqueNetworkInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['opaqueNetworkId', undef, 0, ],
    ['opaqueNetworkName', undef, 0, ],
    ['opaqueNetworkType', undef, 0, ],
    ['pnicZone', undef, 1, 1],
    ['capability', 'OpaqueNetworkCapability', 0, 1],
    ['extraConfig', 'OptionValue', 1, 1],
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
