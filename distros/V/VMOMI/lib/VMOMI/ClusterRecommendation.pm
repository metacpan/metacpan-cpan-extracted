package VMOMI::ClusterRecommendation;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['type', undef, 0, ],
    ['time', undef, 0, ],
    ['rating', undef, 0, ],
    ['reason', undef, 0, ],
    ['reasonText', undef, 0, ],
    ['warningText', undef, 0, 1],
    ['warningDetails', 'LocalizableMessage', 0, 1],
    ['prerequisite', undef, 1, 1],
    ['action', 'ClusterAction', 1, 1],
    ['target', 'ManagedObjectReference', 0, 1],
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
