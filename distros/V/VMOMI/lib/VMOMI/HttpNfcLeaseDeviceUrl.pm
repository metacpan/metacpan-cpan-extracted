package VMOMI::HttpNfcLeaseDeviceUrl;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['importKey', undef, 0, ],
    ['url', undef, 0, ],
    ['sslThumbprint', undef, 0, ],
    ['disk', 'boolean', 0, 1],
    ['targetId', undef, 0, 1],
    ['datastoreKey', undef, 0, 1],
    ['fileSize', undef, 0, 1],
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
