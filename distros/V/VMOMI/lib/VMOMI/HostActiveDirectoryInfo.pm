package VMOMI::HostActiveDirectoryInfo;
use parent 'VMOMI::HostDirectoryStoreInfo';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostDirectoryStoreInfo',
    'HostAuthenticationStoreInfo',
    'DynamicData',
);

our @class_members = ( 
    ['joinedDomain', undef, 0, 1],
    ['trustedDomain', undef, 1, 1],
    ['domainMembershipStatus', undef, 0, 1],
    ['smartCardAuthenticationEnabled', 'boolean', 0, 1],
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
