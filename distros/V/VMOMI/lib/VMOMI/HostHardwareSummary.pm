package VMOMI::HostHardwareSummary;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vendor', undef, 0, ],
    ['model', undef, 0, ],
    ['uuid', undef, 0, ],
    ['otherIdentifyingInfo', 'HostSystemIdentificationInfo', 1, 1],
    ['memorySize', undef, 0, ],
    ['cpuModel', undef, 0, ],
    ['cpuMhz', undef, 0, ],
    ['numCpuPkgs', undef, 0, ],
    ['numCpuCores', undef, 0, ],
    ['numCpuThreads', undef, 0, ],
    ['numNics', undef, 0, ],
    ['numHBAs', undef, 0, ],
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
