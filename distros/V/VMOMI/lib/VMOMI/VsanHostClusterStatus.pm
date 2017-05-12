package VMOMI::VsanHostClusterStatus;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['uuid', undef, 0, 1],
    ['nodeUuid', undef, 0, 1],
    ['health', undef, 0, ],
    ['nodeState', 'VsanHostClusterStatusState', 0, ],
    ['memberUuid', undef, 1, 1],
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
