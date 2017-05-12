package VMOMI::HostVFlashManagerVFlashCacheConfigInfoVFlashModuleConfigOption;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['vFlashModule', undef, 0, ],
    ['vFlashModuleVersion', undef, 0, ],
    ['minSupportedModuleVersion', undef, 0, ],
    ['cacheConsistencyType', 'ChoiceOption', 0, ],
    ['cacheMode', 'ChoiceOption', 0, ],
    ['blockSizeInKBOption', 'LongOption', 0, ],
    ['reservationInMBOption', 'LongOption', 0, ],
    ['maxDiskSizeInKB', undef, 0, ],
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
