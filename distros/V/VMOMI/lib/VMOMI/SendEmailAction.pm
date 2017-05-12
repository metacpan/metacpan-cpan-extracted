package VMOMI::SendEmailAction;
use parent 'VMOMI::Action';

use strict;
use warnings;

our @class_ancestors = ( 
    'Action',
    'DynamicData',
);

our @class_members = ( 
    ['toList', undef, 0, ],
    ['ccList', undef, 0, ],
    ['subject', undef, 0, ],
    ['body', undef, 0, ],
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
