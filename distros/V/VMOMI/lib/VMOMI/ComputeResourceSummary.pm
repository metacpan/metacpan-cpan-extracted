package VMOMI::ComputeResourceSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['totalCpu', undef, 0, ],
    ['totalMemory', undef, 0, ],
    ['numCpuCores', undef, 0, ],
    ['numCpuThreads', undef, 0, ],
    ['effectiveCpu', undef, 0, ],
    ['effectiveMemory', undef, 0, ],
    ['numHosts', undef, 0, ],
    ['numEffectiveHosts', undef, 0, ],
    ['overallStatus', 'ManagedEntityStatus', 0, ],
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
