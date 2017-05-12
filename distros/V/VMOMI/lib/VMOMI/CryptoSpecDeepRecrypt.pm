package VMOMI::CryptoSpecDeepRecrypt;
use parent 'VMOMI::CryptoSpec';

use strict;
use warnings;

our @class_ancestors = ( 
    'CryptoSpec',
    'DynamicData',
);

our @class_members = ( 
    ['newKeyId', 'CryptoKeyId', 0, ],
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
