package VMOMI::EventDescriptionEventDetail;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['key', undef, 0, ],
    ['description', undef, 0, 1],
    ['category', undef, 0, ],
    ['formatOnDatacenter', undef, 0, ],
    ['formatOnComputeResource', undef, 0, ],
    ['formatOnHost', undef, 0, ],
    ['formatOnVm', undef, 0, ],
    ['fullFormat', undef, 0, ],
    ['longDescription', undef, 0, 1],
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
