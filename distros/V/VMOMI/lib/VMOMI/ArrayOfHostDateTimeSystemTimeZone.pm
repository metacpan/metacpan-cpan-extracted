package VMOMI::ArrayOfHostDateTimeSystemTimeZone;
use parent 'VMOMI::ComplexType';

use strict;
use warnings;

our @class_ancestors = ( );

our @class_members = ( 
    ['HostDateTimeSystemTimeZone', 'HostDateTimeSystemTimeZone', 1, 1],
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
