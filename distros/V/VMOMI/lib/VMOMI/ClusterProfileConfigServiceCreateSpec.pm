package VMOMI::ClusterProfileConfigServiceCreateSpec;
use parent 'VMOMI::ClusterProfileConfigSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'ClusterProfileConfigSpec',
    'ClusterProfileCreateSpec',
    'ProfileCreateSpec',
    'DynamicData',
);

our @class_members = ( 
    ['serviceType', undef, 1, 1],
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
