#!/usr/bin/env perl

# confirm that:
#
#     use autobox { TYPE => 'Class', ... };
#
# works the same as:
#
#     use autobox TYPE => 'Class', ...;
#
# Note: these are tested without hashrefs in t/default.t

use strict;
use warnings;

use Test::More tests => 2;

my @GOT;

sub debug ($) { push @GOT, shift }

{
    use autobox {
        DEFAULT  => 'MyDefault',
        DEBUG    => \&debug
    };

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox {
        SCALAR  => 'MyScalar',
        ARRAY   => 'MyArray',
        HASH    => 'MyHash',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug
    };

    my $want = {
        INTEGER => [ 'MyScalar' ],
        FLOAT   => [ 'MyScalar' ],
        STRING  => [ 'MyScalar' ],
        ARRAY   => [ 'MyArray' ],
        HASH    => [ 'MyHash' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}
