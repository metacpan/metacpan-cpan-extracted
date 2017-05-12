package VMOMI::VMwareIpfixConfig;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['collectorIpAddress', undef, 0, 1],
    ['collectorPort', undef, 0, 1],
    ['observationDomainId', undef, 0, 1],
    ['activeFlowTimeout', undef, 0, ],
    ['idleFlowTimeout', undef, 0, ],
    ['samplingRate', undef, 0, ],
    ['internalFlowsOnly', 'boolean', 0, ],
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
