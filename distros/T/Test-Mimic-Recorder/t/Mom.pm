package Mom;

use strict;
use warnings;

use Grandma;
use Grandpa;

our @ISA = qw( Grandma Grandpa );

sub mom {
    'mom';
}

1;
