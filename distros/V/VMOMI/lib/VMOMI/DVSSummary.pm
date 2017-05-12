package VMOMI::DVSSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['uuid', undef, 0, ],
    ['numPorts', undef, 0, ],
    ['productInfo', 'DistributedVirtualSwitchProductSpec', 0, 1],
    ['hostMember', 'ManagedObjectReference', 1, 1],
    ['vm', 'ManagedObjectReference', 1, 1],
    ['host', 'ManagedObjectReference', 1, 1],
    ['portgroupName', undef, 1, 1],
    ['description', undef, 0, 1],
    ['contact', 'DVSContactInfo', 0, 1],
    ['numHosts', undef, 0, 1],
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
