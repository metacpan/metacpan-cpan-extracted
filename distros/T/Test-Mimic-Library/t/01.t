use Test::More 'no_plan';

use Cwd qw<abs_path>;
BEGIN {
    use_ok( 'Test::Mimic::Library', qw<

        SCALAR_CONTEXT
        LIST_CONTEXT
        VOID_CONTEXT
        STABLE
        VOLATILE
        NESTED
        RETURN
        EXCEPTION
        ARBITRARY
        CODE_E
        SCALAR_E
        ARRAY_E
        HASH_E
        ENCODE_TYPE
        DATA
        DATA_TYPE
        HISTORY
        CLASS
 
        encode
        decode
        monitor
        play
        monitor_args
        monitor_args_by
        play_args
        play_args_by
        gen_arg_key
        gen_arg_key_by
        stringify
        stringify_by
        destringify
        destringify_by
        init_records
        load_records
        write_records
        get_references
        load_preferences
        execute
        descend
    > );
}

init_records();

is_deeply( get_references(), [], 'a get_references() call after init_records() suggests that initialization'
    . ' occurred properly.' );

ok( Test::Mimic::Library::_is_pattern( qr/foo/ ), 'positive pattern identification' );
ok( ! Test::Mimic::Library::_is_pattern( 4 ), 'negative pattern identification' );

my $key_gen_output;
if ( $INC{'Data/Dump/Streamer.pm'} ) {
    $key_gen_output = "\$TML_destringify_val = [\n" .
                      "                         200,\n" .
                      "                         4\n" .
                      "                       ];\n";

}
else {
    $key_gen_output = "\$VAR1 = [\n" .
                      "          200,\n" . 
                      "          4\n" .
                      "        ];\n";
}

is( gen_arg_key( 'Foo::Bar', 'foo', 4 ), $key_gen_output, 'testing default key generator' );  

gen_arg_key_by( {
    'key' => sub { 5 },
    'packages' => {
        'Foo::Bar' => {
            'key' => sub { 6 },
            'subs' => {
                'foo' => {
                    'key' => sub { 7 },
                }
            },
        },
    },
} );

my @args = ('dummy_val');
is( gen_arg_key( 'Bar::Foo', 'foo', \@args ), 5, 'testing gen_arg_key preferences, generic' );
is( gen_arg_key( 'Foo::Bar', 'bar', \@args ), 6, 'testing gen_arg_key preferences, package specific' );
is( gen_arg_key( 'Foo::Bar', 'foo', \@args ), 7, 'testing gen_arg_key preferences, subroutine specific' );


my $light_encode_io_pairs = [
    [
        4,
        [ STABLE, 4 ]
    ],
    [
        'hello',
        [ STABLE, 'hello' ]
    ],
    [
        [ 'a', 2, 'b' ],
        [ NESTED, [ ARRAY, [ [ STABLE, 'a' ], [ STABLE, 2 ], [ STABLE, 'b' ] ] ] ]
    ],
    [
        [ [ [ 'foo' ] ] ],
        [ NESTED, [ ARRAY, [ [ NESTED, [ ARRAY , [ [ NESTED, [ ARRAY  ] ] ] ] ] ] ] ]
    ],
    [
        [ [ 'foo' ] ],
        [ NESTED, [ ARRAY , [ [ NESTED, [ ARRAY, [ [ STABLE, 'foo' ] ]  ] ] ] ] ]
    ],
    [
        sub {},
        [ NESTED, [ CODE ] ]
    ],
    [
        { 'x' => 'y', 'a' => 'b' },
        [ NESTED, [ HASH, { 'x' => [ STABLE, 'y' ], 'a' => [ STABLE, 'b' ] } ] ]
    ],
    [
        \\\'a',
        [ NESTED, [ SCALAR, [ NESTED, [ SCALAR, [ NESTED, [ SCALAR ] ] ] ] ] ]
    ],
    [
        \\'a',
        [ NESTED, [ SCALAR, [ NESTED, [ SCALAR, [ STABLE, 'a' ] ] ] ] ]
    ],
];

my $i = 1;
for my $pair ( @{$light_encode_io_pairs} ) {
    my ( $input, $output ) = @{$pair};

    is_deeply( Test::Mimic::Library::_light_encode( $input, 2 ), $output , "basic _light_encode test number $i" );
    $i++;
}

my $default_string_destring_vals = [
    4,
    'a string',
    [ 'an', 'array', 'ref' ],
    { 'a' => 'hash', 'ref' => 17 },
    { [ 'nested' ], { 'stuff' => 43 } },
];

$i = 1;
for my $val ( @{$default_string_destring_vals} ) {
    is_deeply( $val, destringify( stringify($val) ), "default stringify/destringify test number $i" );
}

stringify_by( sub { 'string' } );
is( stringify( [10] ), 'string', 'stringify_by okay' );

destringify_by( sub { [10] } );
is_deeply( destringify( 'string'), [10], 'destringify_by okay' );

my $dummy;
is_deeply( monitor_args( 'Nothing', 'Nope',
    [ 'string', $dummy ] ), [ 2, { 0 => [ 201, 0 ], 1 => [ 201, 1 ] } ]
); 

monitor_args_by( {
    'monitor_args' => sub { 5 },
    'packages' => {
        'Foo::Bar' => {
            'monitor_args' => sub { 6 },
            'subs' => {
                'foo' => {
                    'monitor_args' => sub { 7 },
                }
            },
        },
    },
} );


@args = ('dummy_val');
is( monitor_args( 'Bar::Foo', 'foo', \@args ), 5, 'testing gen_arg_key preferences, generic' );
is( monitor_args( 'Foo::Bar', 'bar', \@args ), 6, 'testing gen_arg_key preferences, package specific' );
is( monitor_args( 'Foo::Bar', 'foo', \@args ), 7, 'testing gen_arg_key preferences, subroutine specific' );


play_args_by( {
    'play_args' => sub { 5 },
    'packages' => {
        'Foo::Bar' => {
            'play_args' => sub { 6 },
            'subs' => {
                'foo' => {
                    'play_args' => sub { 7 },
                }
            },
        },
    },
} );


@args = ('dummy_val');
is( play_args( 'Bar::Foo', 'foo', \@args ), 5, 'testing gen_arg_key preferences, generic' );
is( play_args( 'Foo::Bar', 'bar', \@args ), 6, 'testing gen_arg_key preferences, package specific' );
is( play_args( 'Foo::Bar', 'foo', \@args ), 7, 'testing gen_arg_key preferences, subroutine specific' );
