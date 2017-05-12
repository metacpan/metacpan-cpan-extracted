package VMOMI::ClusterDasConfigInfo;
use parent 'VMOMI::DynamicData';

use strict;
use warnings;

our @class_ancestors = ( 
    'DynamicData',
);

our @class_members = ( 
    ['enabled', 'boolean', 0, 1],
    ['vmMonitoring', undef, 0, 1],
    ['hostMonitoring', undef, 0, 1],
    ['vmComponentProtecting', undef, 0, 1],
    ['failoverLevel', undef, 0, 1],
    ['admissionControlPolicy', 'ClusterDasAdmissionControlPolicy', 0, 1],
    ['admissionControlEnabled', 'boolean', 0, 1],
    ['defaultVmSettings', 'ClusterDasVmSettings', 0, 1],
    ['option', 'OptionValue', 1, 1],
    ['heartbeatDatastore', 'ManagedObjectReference', 1, 1],
    ['hBDatastoreCandidatePolicy', undef, 0, 1],
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
