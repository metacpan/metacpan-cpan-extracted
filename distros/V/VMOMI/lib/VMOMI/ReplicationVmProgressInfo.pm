package VMOMI::ReplicationVmProgressInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['progress', undef, 0, ],
    ['bytesTransferred', undef, 0, ],
    ['bytesToTransfer', undef, 0, ],
    ['checksumTotalBytes', undef, 0, 1],
    ['checksumComparedBytes', undef, 0, 1],
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
