package VMOMI::DistributedVirtualSwitchPortConnectee;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['connectedEntity', 'ManagedObjectReference', 0, 1],
    ['nicKey', undef, 0, 1],
    ['type', undef, 0, 1],
    ['addressHint', undef, 0, 1],
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
