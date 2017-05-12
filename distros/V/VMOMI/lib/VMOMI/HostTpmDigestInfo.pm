package VMOMI::HostTpmDigestInfo;
use parent 'VMOMI::HostDigestInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostDigestInfo',
    'DynamicData',
);

our @class_members = ( 
    ['pcrNumber', undef, 0, ],
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
