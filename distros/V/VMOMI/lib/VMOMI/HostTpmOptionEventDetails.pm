package VMOMI::HostTpmOptionEventDetails;
use parent 'VMOMI::HostTpmEventDetails';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostTpmEventDetails',
    'DynamicData',
);

our @class_members = ( 
    ['optionsFileName', undef, 0, ],
    ['bootOptions', undef, 1, 1],
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
