package VMOMI::HostFibreChannelOverEthernetTargetTransport;
use parent 'VMOMI::HostFibreChannelTargetTransport';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostFibreChannelTargetTransport',
    'HostTargetTransport',
    'DynamicData',
);

our @class_members = ( 
    ['vnportMac', undef, 0, ],
    ['fcfMac', undef, 0, ],
    ['vlanId', undef, 0, ],
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
