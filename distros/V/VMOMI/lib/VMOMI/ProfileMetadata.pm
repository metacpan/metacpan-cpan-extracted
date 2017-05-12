package VMOMI::ProfileMetadata;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['profileTypeName', undef, 0, 1],
    ['description', 'ExtendedDescription', 0, 1],
    ['sortSpec', 'ProfileMetadataProfileSortSpec', 1, 1],
    ['profileCategory', undef, 0, 1],
    ['profileComponent', undef, 0, 1],
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
