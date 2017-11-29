#!perl -T

use Modern::Perl;
use Test::Spec;

plan tests => 41;

use Validator::Lazy;

describe 'Internal roles' => sub {

    it 'MinMax1' => sub {
        my $v = Validator::Lazy->new();

        # 0-64 is a default for string length
        # 0-1000 is a default for numeric
        # default type is autodetect
        ok(  $v->check( MinMax => ''        ), 'default 1' );
        ok(  $v->check( MinMax => 'value'   ), 'default 2' );
        ok( !$v->check( MinMax => 'x' x 100 ), 'default 3' );
    };

    it 'MinMax2' => sub {
        my $v = Validator::Lazy->new( { minmax => { MinMax => { type => 'Int' } } } );
        ok(  $v->check( minmax => 0         ), 'default 1' );
        ok( !$v->check( minmax => 1   x 100 ), 'default 2' );
        ok( !$v->check( minmax => 1001      ), 'default 3' );
    };

    it 'MinMax3' => sub {
        my $config = {
            minmax => [
                {
                    MinMax => {
                        min => 10,
                        max => 100,
                    },
                },
            ],
        };

        my $v = Validator::Lazy->new( $config );

        ok(  $v->check( minmax => 'x' x 99  ), 'declared 4' );
        ok( !$v->check( minmax => ''        ), 'declared 5' );
        ok( !$v->check( minmax => 'value'   ), 'declared 6' );
        ok( !$v->check( minmax => 'x' x 101 ), 'declared 8' );

        $config->{minmax}->[0]->{MinMax}->{type} = 'Int';

        $v = Validator::Lazy->new( $config );
        ok(  $v->check( minmax => 10        ), 'declared 1' );
        ok(  $v->check( minmax => 50        ), 'declared 2' );
        ok(  $v->check( minmax => 100       ), 'declared 3' );
        ok( !$v->check( minmax => 0         ), 'declared 7' );
        ok( !$v->check( minmax => 1   x 100 ), 'declared 9' );
        ok( !$v->check( minmax => 1001      ), 'declared 10' );
    };

    it 'MinMax4' => sub {
        my $config = {
            minmax => [
                {
                    MinMax => {
                        min => 0,
                        max => 0,
                    },
                },
            ],
        };

        my $v = Validator::Lazy->new( config => $config );

        ok(  !$v->check( minmax => 0        ), 'zero 1' );
        ok(   $v->check( minmax => ''       ), 'zero 2' );
        ok(  !$v->check( minmax => 10       ), 'zero 3' );
        ok(  !$v->check( minmax => -10      ), 'zero 4' );
    };

    it 'MinMax5' => sub {
        my $config = {
            minmax => [
                {
                    MinMax => {
                        min  => -10,
                        max  => -5,
                        type => 'Int',
                    },
                },
            ],
        };

        my $v = Validator::Lazy->new( config => $config );

        ok(  !$v->check( minmax =>  -100    ), 'minus 1' );
        is_deeply( $v->error_codes, [ 'TOO_SMALL' ], 'minus errcodes' );

        ok(   $v->check( minmax =>   -10    ), 'minus 2' );
        ok(   $v->check( minmax =>    -7    ), 'minus 3' );
        ok(   $v->check( minmax =>    -5    ), 'minus 4' );
        ok(  !$v->check( minmax =>     0    ), 'minus 5' );
        is_deeply( $v->error_codes, [ 'TOO_BIG' ], 'minus errcodes' );
    };

    it 'MinMax6' => sub {
        my $config = {
            minmax => {
                MinMax => {
                    min  => -10,
                    max  => -5,
                    type => 'Int',
                },
            },
        };

        my $v = Validator::Lazy->new( config => $config );

        ok(  !$v->check( minmax =>  -100    ), 'minus 1 hashconfig' );
        is_deeply( $v->error_codes, [ 'TOO_SMALL' ], 'minus errcodes hashconfig' );

        ok(   $v->check( minmax =>   -10    ), 'minus 2 hashconfig' );
        ok(   $v->check( minmax =>    -7    ), 'minus 3 hashconfig' );
        ok(   $v->check( minmax =>    -5    ), 'minus 4 hashconfig' );
        ok(  !$v->check( minmax =>     0    ), 'minus 5 hashconfig' );
        is_deeply( $v->error_codes, [ 'TOO_BIG' ], 'minus errcodes hashconfig' );
    };

    it 'MinMax7' => sub {
        my $config = {
            minmax => {
                MinMax => [ -10, -5, 'Int' ],
            },
        };

        my $v = Validator::Lazy->new( config => $config );

        ok(  !$v->check( minmax =>  -100    ), 'minus 1 hashconfig' );
        is_deeply( $v->error_codes, [ 'TOO_SMALL' ], 'minus errcodes hashconfig' );

        ok(   $v->check( minmax =>   -10    ), 'minus 2 hashconfig' );
        ok(   $v->check( minmax =>    -7    ), 'minus 3 hashconfig' );
        ok(   $v->check( minmax =>    -5    ), 'minus 4 hashconfig' );
        ok(  !$v->check( minmax =>     0    ), 'minus 5 hashconfig' );
        is_deeply( $v->error_codes, [ 'TOO_BIG' ], 'minus errcodes hashconfig' );
    };
};

runtests unless caller;
