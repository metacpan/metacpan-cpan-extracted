package VMOMI::HostApplyProfile;
use parent 'VMOMI::ApplyProfile';

use strict;
use warnings;

our @class_ancestors = ( 
    'ApplyProfile',
    'DynamicData',
);

our @class_members = ( 
    ['memory', 'HostMemoryProfile', 0, 1],
    ['storage', 'StorageProfile', 0, 1],
    ['network', 'NetworkProfile', 0, 1],
    ['datetime', 'DateTimeProfile', 0, 1],
    ['firewall', 'FirewallProfile', 0, 1],
    ['security', 'SecurityProfile', 0, 1],
    ['service', 'ServiceProfile', 1, 1],
    ['option', 'OptionProfile', 1, 1],
    ['userAccount', 'UserProfile', 1, 1],
    ['usergroupAccount', 'UserGroupProfile', 1, 1],
    ['authentication', 'AuthenticationProfile', 0, 1],
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
