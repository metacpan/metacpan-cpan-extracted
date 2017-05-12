package VMOMI::ProfileCompositeExpression;
use parent 'VMOMI::ProfileExpression';

use strict;
use warnings;

our @class_ancestors = ( 
    'ProfileExpression',
    'DynamicData',
);

our @class_members = ( 
    ['operator', undef, 0, ],
    ['expressionName', undef, 1, ],
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
