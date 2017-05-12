package VMOMI::HostFirewallRule;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['port', undef, 0, ],
    ['endPort', undef, 0, 1],
    ['direction', 'HostFirewallRuleDirection', 0, ],
    ['portType', 'HostFirewallRulePortType', 0, 1],
    ['protocol', undef, 0, ],
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
