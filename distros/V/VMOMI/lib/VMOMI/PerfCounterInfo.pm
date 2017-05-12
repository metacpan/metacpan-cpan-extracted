package VMOMI::PerfCounterInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['nameInfo', 'ElementDescription', 0, ],
    ['groupInfo', 'ElementDescription', 0, ],
    ['unitInfo', 'ElementDescription', 0, ],
    ['rollupType', 'PerfSummaryType', 0, ],
    ['statsType', 'PerfStatsType', 0, ],
    ['level', undef, 0, 1],
    ['perDeviceLevel', undef, 0, 1],
    ['associatedCounterId', undef, 1, 1],
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
