package VMOMI::HostCpuPackage;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['index', undef, 0, ],
    ['vendor', undef, 0, ],
    ['hz', undef, 0, ],
    ['busHz', undef, 0, ],
    ['description', undef, 0, ],
    ['threadId', undef, 1, ],
    ['cpuFeature', 'HostCpuIdInfo', 1, 1],
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
