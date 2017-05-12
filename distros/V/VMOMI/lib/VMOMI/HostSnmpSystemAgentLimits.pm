package VMOMI::HostSnmpSystemAgentLimits;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['maxReadOnlyCommunities', undef, 0, ],
    ['maxTrapDestinations', undef, 0, ],
    ['maxCommunityLength', undef, 0, ],
    ['maxBufferSize', undef, 0, ],
    ['capability', 'HostSnmpAgentCapability', 0, 1],
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
