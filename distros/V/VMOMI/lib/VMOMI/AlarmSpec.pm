package VMOMI::AlarmSpec;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['name', undef, 0, ],
    ['systemName', undef, 0, 1],
    ['description', undef, 0, ],
    ['enabled', 'boolean', 0, ],
    ['expression', 'AlarmExpression', 0, ],
    ['action', 'AlarmAction', 0, 1],
    ['actionFrequency', undef, 0, 1],
    ['setting', 'AlarmSetting', 0, 1],
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
