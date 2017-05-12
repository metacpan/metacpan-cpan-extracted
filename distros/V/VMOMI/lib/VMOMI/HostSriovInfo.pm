package VMOMI::HostSriovInfo;
use parent 'VMOMI::HostPciPassthruInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostPciPassthruInfo',
    'DynamicData',
);

our @class_members = ( 
    ['sriovEnabled', 'boolean', 0, ],
    ['sriovCapable', 'boolean', 0, ],
    ['sriovActive', 'boolean', 0, ],
    ['numVirtualFunctionRequested', undef, 0, ],
    ['numVirtualFunction', undef, 0, ],
    ['maxVirtualFunctionSupported', undef, 0, ],
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
