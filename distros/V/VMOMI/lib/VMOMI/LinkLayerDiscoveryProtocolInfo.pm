package VMOMI::LinkLayerDiscoveryProtocolInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['chassisId', undef, 0, ],
    ['portId', undef, 0, ],
    ['timeToLive', undef, 0, ],
    ['parameter', 'KeyAnyValue', 1, 1],
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
