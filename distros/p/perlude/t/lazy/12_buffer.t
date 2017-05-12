use Test::More;
use strict;
use warnings;
use Perlude::Lazy;

ok 1,"some old tests to restore if someone wants to maintain lazy";
done_testing;

__END__

my @tests =
( [ fold => ( apply {@$_} tuple 3, unfold 1 .. 7 ), [ 1 .. 7 ] ]
, [ takeWhile =>
        ( takeWhile { $_ % 2 } apply {@$_} tuple 3, unfold 1, 3, 5, 2, 7, 9 )
  , [ 1, 3, 5 ]
  ]
, [ filter => ( filter { $_ % 2 } apply {@$_} tuple 3, unfold 1 .. 7 )
  , [ 1, 3, 5, 7 ]
  ]
, [ take => ( take 5, apply {@$_} tuple 3, unfold 1 .. 100 ), [ 1 .. 5 ] ]
, [ drop => ( drop 5, apply {@$_} tuple 3, unfold 1 .. 100 ), [ 6 .. 100 ] ]
, [ apply => ( apply {@$_} tuple 17, unfold 1 .. 100 ), [ 1 .. 100 ] ]
, [ traverse => sub { # the state variable ensure the sub runs once only
        ( state $i++ ) ? () : traverse { -$_ } apply {@$_} tuple 5,
            unfold 1 .. 10;
    }
  , [-10]
  ]
, [ tuple => ( tuple 2, apply {@$_} tuple 3, unfold 0 .. 10 ),
  , [ [ 0, 1 ], [ 2, 3 ], [ 4, 5 ], [ 6, 7 ], [ 8, 9 ], [10] ]
  ]
);

plan tests => @tests + 1;

$TODO = '_buffer removed';

# generate the todo list
my %todo = do {
    no strict 'refs';
    map { ( $_ => 1 ) }

        # exception list
        grep { !/^(?:import|carp|confess|croak|_.*|[A-Z_]+|unfold|cycle)$/ }

        # functions in the Perlude:: namespace
        grep { defined ${'Perlude::'}{$_} } keys %Perlude::;
};

# run the tests
for my $t (@tests) {
    my ( $name, $i, $out ) = @$t;
    my $got = [ fold $i ];
    my $ok = is_deeply( $got, $out, $name );
    delete $todo{$name};
}

# check all sub in Perlude:: have been tested
ok( !keys %todo, 'All Perlude functions tested for buffering' )
    or diag "Untested functions: @{[sort keys %todo]}";

