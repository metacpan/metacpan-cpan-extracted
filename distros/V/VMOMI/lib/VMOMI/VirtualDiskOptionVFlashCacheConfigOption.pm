package VMOMI::VirtualDiskOptionVFlashCacheConfigOption;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['cacheConsistencyType', 'ChoiceOption', 0, ],
    ['cacheMode', 'ChoiceOption', 0, ],
    ['reservationInMB', 'LongOption', 0, ],
    ['blockSizeInKB', 'LongOption', 0, ],
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
