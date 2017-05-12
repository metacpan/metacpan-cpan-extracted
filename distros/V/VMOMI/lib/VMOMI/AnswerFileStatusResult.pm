package VMOMI::AnswerFileStatusResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['checkedTime', undef, 0, ],
    ['host', 'ManagedObjectReference', 0, ],
    ['status', undef, 0, ],
    ['error', 'AnswerFileStatusError', 1, 1],
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
