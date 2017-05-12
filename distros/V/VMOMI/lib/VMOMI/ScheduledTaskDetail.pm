package VMOMI::ScheduledTaskDetail;
use parent 'VMOMI::TypeDescription';

use strict;
use warnings;

our @class_ancestors = ( 
    'TypeDescription',
    'Description',
    'DynamicData',
);

our @class_members = ( 
    ['frequency', undef, 0, ],
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
