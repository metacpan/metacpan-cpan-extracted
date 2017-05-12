package VMOMI::HostNasVolume;
use parent 'VMOMI::HostFileSystemVolume';

use strict;
use warnings;

our @class_ancestors = ( 
    'HostFileSystemVolume',
    'DynamicData',
);

our @class_members = ( 
    ['remoteHost', undef, 0, ],
    ['remotePath', undef, 0, ],
    ['userName', undef, 0, 1],
    ['remoteHostNames', undef, 1, 1],
    ['securityType', undef, 0, 1],
    ['protocolEndpoint', 'boolean', 0, 1],
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
