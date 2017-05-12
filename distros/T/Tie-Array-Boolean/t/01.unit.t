use Test::More 'tests' => 86;

use Tie::Array::Boolean;

my $ta = tie my @t, 'Tie::Array::Boolean';

isa_ok( $ta, 'Tie::Array::Boolean' );

can_ok( $ta, qw( TIEARRAY FETCH STORE FETCHSIZE STORESIZE
                 POP PUSH SHIFT UNSHIFT SPLICE DELETE EXISTS
                 get_truth_count ) );

is( scalar @t, 0, '@t has no elements' );
is( $#t, -1, '$#t is -1' );

push @t, 'foo';

is( scalar @t, 1, '@t has 1 element' );
is( $t[0], 1, '$t[0] is 1' );
is( $#t, 0, '$#t is 0' );

shift @t;

is( scalar @t, 0, '@t has no elements' );
is( $#t, -1, '$#t is -1' );

unshift @t, 0;

is( scalar @t, 1, '@t has 1 element' );
is( $#t, 0, '$#t is 0' );
ok( ! $t[0], '$t[0] is false' );

pop @t;

is( scalar @t, 0, '@t has no elements' );
is( $#t, -1, '$#t is -1' );

@t = ( 1, 0, 1, 0 );

is_deeply( \@t, [ 1, 0, 1, 0 ], 'assignment works' );
is( scalar @t, 4, '@t has 4 elements' );
is( $ta->get_truth_count(), 2, 'truth count = 2' );

$#t = 0;

is_deeply( \@t, [ 1 ], 'assign to $#x works' );
is( scalar @t, 1, '@t has 1 element' );
is( $#t, 0, '$#t is 0' );
is( $ta->get_truth_count(), 1, 'truth count = 1' );

$t[0] = '0 but true';
is( $t[0], 1, '"0 but true" becomes 1' );

foreach my $false ( 0, undef, '', '0' ) {
    no warnings 'uninitialized';
    $t[0] = $false;
    is( $t[0], 0, "false value, '$false', is 0" );
}

{
    my $len = 10;
    @t = ( 1 ) x $len;
    while ( $len-- ) {
        shift @t;
        is( scalar @t, $len, "array shrinks to $len" );
        is( $ta->get_truth_count(), $len, "truth count right at length $len" );
        is_deeply( \@t, [ ( 1 ) x $len ], "array right at length $len" );
    }
}

{
    my $len = 10;
    @t = ( 0 ) x $len;
    while ( $len-- ) {
        shift @t;
        is( scalar @t, $len, "array shrinks to $len" );
        is_deeply( \@t, [ ( 0 ) x $len ], "array right at length $len" );
    }
}

is( scalar @t, 0, 'array is empty' );
ok( ! exists $t[0], 'element [0] does not exist' );
is( $t[0], undef, 'value that does not exist is undef' );
is( scalar @t, 0, 'array is still empty' );

@t = ( 1, 1 );
is( scalar @t, 2, 'array has two elements' );
delete $t[1];
is( scalar @t, 1, 'delete shortens array' );

@t = ( 1, 1 );
is( scalar @t, 2, 'array has two elements' );
delete $t[0];
is( scalar @t, 2, 'array still has two elements after deleting first' );

TODO: {
    local $TODO = q{Can't tell deleted from 0};

    is( $t[0], undef, 'deleted element is undef' );

    delete $t[1];
    is( scalar @t, 0, 'array has no elements after last is deleted' );
}

# not testing splice
