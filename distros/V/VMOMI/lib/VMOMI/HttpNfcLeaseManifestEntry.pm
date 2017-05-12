package VMOMI::HttpNfcLeaseManifestEntry;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['sha1', undef, 0, ],
    ['size', undef, 0, ],
    ['disk', 'boolean', 0, ],
    ['capacity', undef, 0, 1],
    ['populatedSize', undef, 0, 1],
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
