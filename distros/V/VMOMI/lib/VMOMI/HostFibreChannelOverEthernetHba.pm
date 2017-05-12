package VMOMI::HostFibreChannelOverEthernetHba;
use parent 'VMOMI::HostFibreChannelHba';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostFibreChannelHba',
    'HostHostBusAdapter',
    'DynamicData',
);

our @class_members = ( 
    ['underlyingNic', undef, 0, ],
    ['linkInfo', 'HostFibreChannelOverEthernetHbaLinkInfo', 0, ],
    ['isSoftwareFcoe', 'boolean', 0, ],
    ['markedForRemoval', 'boolean', 0, ],
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
