package VMOMI::DVPortgroupPolicy;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['blockOverrideAllowed', 'boolean', 0, ],
    ['shapingOverrideAllowed', 'boolean', 0, ],
    ['vendorConfigOverrideAllowed', 'boolean', 0, ],
    ['livePortMovingAllowed', 'boolean', 0, ],
    ['portConfigResetAtDisconnect', 'boolean', 0, ],
    ['networkResourcePoolOverrideAllowed', 'boolean', 0, 1],
    ['trafficFilterOverrideAllowed', 'boolean', 0, 1],
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
