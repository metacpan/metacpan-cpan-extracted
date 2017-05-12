package VMOMI::KernelModuleInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['id', undef, 0, ],
    ['name', undef, 0, ],
    ['version', undef, 0, ],
    ['filename', undef, 0, ],
    ['optionString', undef, 0, ],
    ['loaded', 'boolean', 0, ],
    ['enabled', 'boolean', 0, ],
    ['useCount', undef, 0, ],
    ['readOnlySection', 'KernelModuleSectionInfo', 0, ],
    ['writableSection', 'KernelModuleSectionInfo', 0, ],
    ['textSection', 'KernelModuleSectionInfo', 0, ],
    ['dataSection', 'KernelModuleSectionInfo', 0, ],
    ['bssSection', 'KernelModuleSectionInfo', 0, ],
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
