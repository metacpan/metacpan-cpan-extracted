package VMOMI::StoragePerformanceSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['interval', undef, 0, ],
    ['percentile', undef, 1, ],
    ['datastoreReadLatency', undef, 1, ],
    ['datastoreWriteLatency', undef, 1, ],
    ['datastoreVmLatency', undef, 1, ],
    ['datastoreReadIops', undef, 1, ],
    ['datastoreWriteIops', undef, 1, ],
    ['siocActivityDuration', undef, 0, ],
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
