package VMOMI::CustomFieldDefEvent;
use parent 'VMOMI::CustomFieldEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'CustomFieldEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['fieldKey', undef, 0, ],
    ['name', undef, 0, ],
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
