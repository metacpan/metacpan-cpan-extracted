package VMOMI::DistributedVirtualSwitchHostMemberPnicBacking;
use parent 'VMOMI::DistributedVirtualSwitchHostMemberBacking';

use strict;
use warnings;

our @class_ancestors = ( 
    'DistributedVirtualSwitchHostMemberBacking',
    'DynamicData',
);

our @class_members = ( 
    ['pnicSpec', 'DistributedVirtualSwitchHostMemberPnicSpec', 1, 1],
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
