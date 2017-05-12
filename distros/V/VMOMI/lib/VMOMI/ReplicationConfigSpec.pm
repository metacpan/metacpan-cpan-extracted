package VMOMI::ReplicationConfigSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['generation', undef, 0, ],
    ['vmReplicationId', undef, 0, ],
    ['destination', undef, 0, ],
    ['port', undef, 0, ],
    ['rpo', undef, 0, ],
    ['quiesceGuestEnabled', 'boolean', 0, ],
    ['paused', 'boolean', 0, ],
    ['oppUpdatesEnabled', 'boolean', 0, ],
    ['netCompressionEnabled', 'boolean', 0, 1],
    ['disk', 'ReplicationInfoDiskSettings', 1, 1],
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
