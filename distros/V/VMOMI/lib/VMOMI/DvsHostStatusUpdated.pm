package VMOMI::DvsHostStatusUpdated;
use parent 'VMOMI::DvsEvent';

use strict;
use warnings;

our @class_ancestors = ( 
    'DvsEvent',
    'Event',
    'DynamicData',
);

our @class_members = ( 
    ['hostMember', 'HostEventArgument', 0, ],
    ['oldStatus', undef, 0, 1],
    ['newStatus', undef, 0, 1],
    ['oldStatusDetail', undef, 0, 1],
    ['newStatusDetail', undef, 0, 1],
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
