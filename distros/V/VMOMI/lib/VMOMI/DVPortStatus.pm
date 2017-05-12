package VMOMI::DVPortStatus;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['linkUp', 'boolean', 0, ],
    ['blocked', 'boolean', 0, ],
    ['vlanIds', 'NumericRange', 1, 1],
    ['trunkingMode', 'boolean', 0, 1],
    ['mtu', undef, 0, 1],
    ['linkPeer', undef, 0, 1],
    ['macAddress', undef, 0, 1],
    ['statusDetail', undef, 0, 1],
    ['vmDirectPathGen2Active', 'boolean', 0, 1],
    ['vmDirectPathGen2InactiveReasonNetwork', undef, 1, 1],
    ['vmDirectPathGen2InactiveReasonOther', undef, 1, 1],
    ['vmDirectPathGen2InactiveReasonExtended', undef, 0, 1],
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
