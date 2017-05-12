package VMOMI::SessionManagerHttpServiceRequestSpec;
use parent 'VMOMI::SessionManagerServiceRequestSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'SessionManagerServiceRequestSpec',
    'DynamicData',
);

our @class_members = ( 
    ['method', undef, 0, 1],
    ['url', undef, 0, ],
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
