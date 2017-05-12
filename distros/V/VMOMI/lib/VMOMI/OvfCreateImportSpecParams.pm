package VMOMI::OvfCreateImportSpecParams;
use parent 'VMOMI::OvfManagerCommonParams';

use strict;
use warnings;

our @class_ancestors = ( 
    'OvfManagerCommonParams',
    'DynamicData',
);

our @class_members = ( 
    ['entityName', undef, 0, ],
    ['hostSystem', 'ManagedObjectReference', 0, 1],
    ['networkMapping', 'OvfNetworkMapping', 1, 1],
    ['ipAllocationPolicy', undef, 0, 1],
    ['ipProtocol', undef, 0, 1],
    ['propertyMapping', 'KeyValue', 1, 1],
    ['resourceMapping', 'OvfResourceMap', 1, 1],
    ['diskProvisioning', undef, 0, 1],
    ['instantiationOst', 'OvfConsumerOstNode', 0, 1],
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
