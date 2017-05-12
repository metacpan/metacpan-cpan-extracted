package VMOMI::PatchMetadataCorrupted;
use parent 'VMOMI::PatchMetadataInvalid';

use strict;
use warnings;

our @class_ancestors = ( 
    'PatchMetadataInvalid',
    'VimFault',
    'MethodFault',
);

our @class_members = ( );

sub get_class_ancestors {
    return @class_ancestors;
}

sub get_class_members {
    my $class = shift;
    my @super_members = $class->SUPER::get_class_members();
    return (@super_members, @class_members);
}

1;
