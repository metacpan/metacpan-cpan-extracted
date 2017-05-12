#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 14;

my @GOT;

sub debug ($) { push @GOT, shift }

{
    use autobox
        DEFAULT  => 'MyDefault',
        DEBUG    => \&debug;

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
    use autobox
        INTEGER => 'MyInteger',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyInteger', 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        FLOAT   => 'MyFloat',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyFloat', 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        STRING  => 'MyString',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyString', 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        ARRAY   => 'MyArray',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyArray' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        HASH    => 'MyHash',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyHash' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        CODE    => 'MyCode',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyCode' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        INTEGER => 'MyInteger',
        NUMBER  => 'MyNumber',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyInteger', 'MyNumber', 'MyDefault' ],
        FLOAT   => [ 'MyNumber', 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        INTEGER => 'MyInteger',
        NUMBER  => 'MyNumber',
        SCALAR  => 'MyScalar',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyInteger', 'MyNumber', 'MyScalar' ],
        FLOAT   => [ 'MyNumber', 'MyScalar' ],
        STRING  => [ 'MyScalar' ],
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        INTEGER   => 'MyInteger',
        NUMBER    => 'MyNumber',
        SCALAR    => 'MyScalar',
        UNIVERSAL => 'MyUniversal',
        DEFAULT   => 'MyDefault',
        DEBUG     => \&debug;

    my $want = {
        INTEGER => [ 'MyInteger', 'MyNumber', 'MyScalar', 'MyUniversal' ],
        FLOAT   => [ 'MyNumber', 'MyScalar', 'MyUniversal' ],
        STRING  => [ 'MyScalar', 'MyUniversal' ],
        ARRAY   => [ 'MyDefault', 'MyUniversal' ],
        HASH    => [ 'MyDefault', 'MyUniversal' ],
        CODE    => [ 'MyDefault', 'MyUniversal' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        SCALAR  => 'MyScalar',
        ARRAY   => 'MyArray',
        HASH    => 'MyHash',
        CODE    => 'MyCode',
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyScalar' ],
        FLOAT   => [ 'MyScalar' ],
        STRING  => [ 'MyScalar' ],
        ARRAY   => [ 'MyArray' ],
        HASH    => [ 'MyHash' ],
        CODE    => [ 'MyCode' ]
    };

    is_deeply(shift(@GOT), $want);
}

# test undef
{
    use autobox
        DEFAULT => undef,
        DEBUG   => \&debug;

    my $want = { };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        SCALAR  => undef,
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        ARRAY   => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}

{
    use autobox
        ARRAY   => undef,
        DEFAULT => 'MyDefault',
        DEBUG   => \&debug;

    my $want = {
        INTEGER => [ 'MyDefault' ],
        FLOAT   => [ 'MyDefault' ],
        STRING  => [ 'MyDefault' ],
        HASH    => [ 'MyDefault' ],
        CODE    => [ 'MyDefault' ]
    };

    is_deeply(shift(@GOT), $want);
}
