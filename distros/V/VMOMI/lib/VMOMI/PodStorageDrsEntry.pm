package VMOMI::PodStorageDrsEntry;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['storageDrsConfig', 'StorageDrsConfigInfo', 0, ],
    ['recommendation', 'ClusterRecommendation', 1, 1],
    ['drsFault', 'ClusterDrsFaults', 1, 1],
    ['actionHistory', 'ClusterActionHistory', 1, 1],
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
