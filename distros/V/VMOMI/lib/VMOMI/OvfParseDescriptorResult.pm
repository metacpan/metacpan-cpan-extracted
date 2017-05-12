package VMOMI::OvfParseDescriptorResult;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['eula', undef, 1, 1],
    ['network', 'OvfNetworkInfo', 1, 1],
    ['ipAllocationScheme', undef, 1, 1],
    ['ipProtocols', undef, 1, 1],
    ['property', 'VAppPropertyInfo', 1, 1],
    ['productInfo', 'VAppProductInfo', 0, 1],
    ['annotation', undef, 0, ],
    ['approximateDownloadSize', undef, 0, 1],
    ['approximateFlatDeploymentSize', undef, 0, 1],
    ['approximateSparseDeploymentSize', undef, 0, 1],
    ['defaultEntityName', undef, 0, ],
    ['virtualApp', 'boolean', 0, ],
    ['deploymentOption', 'OvfDeploymentOption', 1, 1],
    ['defaultDeploymentOption', undef, 0, ],
    ['entityName', 'KeyValue', 1, 1],
    ['annotatedOst', 'OvfConsumerOstNode', 0, 1],
    ['error', 'LocalizedMethodFault', 1, 1],
    ['warning', 'LocalizedMethodFault', 1, 1],
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
