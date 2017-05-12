package VMOMI::DistributedVirtualSwitchPortStatistics;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['packetsInMulticast', undef, 0, ],
    ['packetsOutMulticast', undef, 0, ],
    ['bytesInMulticast', undef, 0, ],
    ['bytesOutMulticast', undef, 0, ],
    ['packetsInUnicast', undef, 0, ],
    ['packetsOutUnicast', undef, 0, ],
    ['bytesInUnicast', undef, 0, ],
    ['bytesOutUnicast', undef, 0, ],
    ['packetsInBroadcast', undef, 0, ],
    ['packetsOutBroadcast', undef, 0, ],
    ['bytesInBroadcast', undef, 0, ],
    ['bytesOutBroadcast', undef, 0, ],
    ['packetsInDropped', undef, 0, ],
    ['packetsOutDropped', undef, 0, ],
    ['packetsInException', undef, 0, ],
    ['packetsOutException', undef, 0, ],
    ['bytesInFromPnic', undef, 0, 1],
    ['bytesOutToPnic', undef, 0, 1],
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
