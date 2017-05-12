package VMOMI::FloatOption;
use parent 'VMOMI::OptionType';

use strict;
use warnings;

our @class_ancestors = ( 
    'OptionType',
    'DynamicData',
);

our @class_members = ( 
    ['min', undef, 0, ],
    ['max', undef, 0, ],
    ['defaultValue', undef, 0, ],
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
