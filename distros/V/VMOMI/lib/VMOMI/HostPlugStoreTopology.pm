package VMOMI::HostPlugStoreTopology;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['adapter', 'HostPlugStoreTopologyAdapter', 1, 1],
    ['path', 'HostPlugStoreTopologyPath', 1, 1],
    ['target', 'HostPlugStoreTopologyTarget', 1, 1],
    ['device', 'HostPlugStoreTopologyDevice', 1, 1],
    ['plugin', 'HostPlugStoreTopologyPlugin', 1, 1],
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
