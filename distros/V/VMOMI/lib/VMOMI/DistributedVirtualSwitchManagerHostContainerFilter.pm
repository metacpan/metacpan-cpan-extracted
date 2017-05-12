package VMOMI::DistributedVirtualSwitchManagerHostContainerFilter;
use parent 'VMOMI::DistributedVirtualSwitchManagerHostDvsFilterSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'DistributedVirtualSwitchManagerHostDvsFilterSpec',
    'DynamicData',
);

our @class_members = ( 
    ['hostContainer', 'DistributedVirtualSwitchManagerHostContainer', 0, ],
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
