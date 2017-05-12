package VMOMI::PhysicalNic;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, 1],
    ['device', undef, 0, ],
    ['pci', undef, 0, ],
    ['driver', undef, 0, 1],
    ['linkSpeed', 'PhysicalNicLinkInfo', 0, 1],
    ['validLinkSpecification', 'PhysicalNicLinkInfo', 1, 1],
    ['spec', 'PhysicalNicSpec', 0, ],
    ['wakeOnLanSupported', 'boolean', 0, ],
    ['mac', undef, 0, ],
    ['fcoeConfiguration', 'FcoeConfig', 0, 1],
    ['vmDirectPathGen2Supported', 'boolean', 0, 1],
    ['vmDirectPathGen2SupportedMode', undef, 0, 1],
    ['resourcePoolSchedulerAllowed', 'boolean', 0, 1],
    ['resourcePoolSchedulerDisallowedReason', undef, 1, 1],
    ['autoNegotiateSupported', 'boolean', 0, 1],
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
