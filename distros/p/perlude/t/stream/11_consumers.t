use strict;
use warnings;
use 5.10.0;
use Test::More;
use Perlude;

my $limit = 10_000;

my @tests =
( [ takeWhile => sub { $_ < 10 }, unfold( 1, 10, 4 ), [1] ]
, [ takeWhile => sub { $_ < 10 }, unfold(),   [] ]
, [ takeWhile => sub { $_ < 10 }, unfold(10), [] ]
, [ take => 2, unfold( 1 .. 30 ), [ 1, 2 ] ]
, [ take => 2, unfold( 0, 1 ), [ 0, 1 ] ]
, [ take => 2, unfold( 0, 1, 2 ), [ 0, 1 ] ]
, [ take => 3, unfold(),  [] ]
, [ take => 3, unfold(1), [1] ]
, [ take => 3, unfold( undef, 2 ), [ undef, 2 ] ]
, [ take => 0, unfold( undef, 2 ), [] ]
, [ take => -1, unfold( undef, 2 ), [] ]
, [ take => 'ABC', sub { state $n; $n++ }, [] ]
, [ take => 0.5, sub { state $n; $n++ }, [ 0 ] ]
, [ drop => 2, unfold( 1 .. 30 ), [ 3 .. 30 ] ]
, [ drop => 2, unfold( 0, 1 ), [] ]
, [ drop => 2, unfold( 0, 1, 2 ), [2] ]
, [ drop => 3, unfold(),  [] ]
, [ drop => 3, unfold(1), [] ]
, [ drop => 3, unfold( undef, 2 ), [] ]
, [ drop => 0, unfold( undef, 2 ), [ undef, 2 ] ]
, [ drop => -1, unfold( undef, 2 ), [ undef, 2 ] ]
, [ drop => "ABC", unfold( 1 .. 3 ), [ 1 .. 3 ] ]
, [ drop => 0.1, unfold( 1 .. 3 ), [ 2, 3 ] ]
, [ filter => sub { $_ % 2 }, unfold( 1, 2, 3 ), [1,3] ]
, [ filter => sub { $_ % 2 }, sub { state $n = 0; $n++ }
  , [ grep { $_ % 2 } 0 .. ( 2 * $limit ) ]
  ]
, [ apply  => sub { $_ % 2 }, unfold( 1, 2, 3 ), [1,0,1] ]
, [ apply  => sub { $_ % 2 }, sub { state $n = 0; $n++ }
  , [ fold take $limit, cycle 0, 1 ]
  ]
);

plan tests => 0+ @tests;

for my $t (@tests) {
    my ( $name, $arg, $i, $out ) = @$t;
    no strict 'refs';
    my @r = ref $arg eq 'CODE'
        ? fold take $limit, &$name( \&$arg, $i )
        : fold take $limit, &$name( $arg, $i );
    is_deeply( \@r, $out, $name);
}

