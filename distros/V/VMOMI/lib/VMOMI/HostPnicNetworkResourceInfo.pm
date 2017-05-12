package VMOMI::HostPnicNetworkResourceInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['pnicDevice', undef, 0, ],
    ['availableBandwidthForVMTraffic', undef, 0, 1],
    ['unusedBandwidthForVMTraffic', undef, 0, 1],
    ['placedVirtualNics', 'HostPlacedVirtualNicIdentifier', 1, 1],
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
