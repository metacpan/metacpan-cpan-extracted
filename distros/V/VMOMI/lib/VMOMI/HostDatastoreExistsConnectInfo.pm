package VMOMI::HostDatastoreExistsConnectInfo;
use parent 'VMOMI::HostDatastoreConnectInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostDatastoreConnectInfo',
    'DynamicData',
);

our @class_members = ( 
    ['newDatastoreName', undef, 0, ],
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
