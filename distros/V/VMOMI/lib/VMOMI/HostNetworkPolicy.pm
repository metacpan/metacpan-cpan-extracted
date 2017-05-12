package VMOMI::HostNetworkPolicy;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['security', 'HostNetworkSecurityPolicy', 0, 1],
    ['nicTeaming', 'HostNicTeamingPolicy', 0, 1],
    ['offloadPolicy', 'HostNetOffloadCapabilities', 0, 1],
    ['shapingPolicy', 'HostNetworkTrafficShapingPolicy', 0, 1],
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
