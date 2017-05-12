#!perlg 

use Test::More tests => 3;
use Modern::Perl;
use Data::Dumper;
use Set::Scalar;
use VANAMBURG::SEMPROG::SimpleGraph;

my $g = VANAMBURG::SEMPROG::SimpleGraph->new();

diag("loading movie data...");

$g->load("data/movies.csv");

diag("load done.  finding path");

my ( $distance, $path ) = find_path( "Val Kilmer", "Kevin Bacon", $g );

ok( $distance == 2, '2 links separate Val and Kevin' );

diag( "path=" . join ", ", @$path );

( $distance, $path ) = find_path( "Bruce Lee", "Kevin Bacon", $g );

ok( $distance == 3, '3 links separate Bruce and Kevin' );

diag( "path=" . join ", ", @$path );

( $distance, $path ) = find_path( "Harrison Ford", "Kevin Bacon", $g );

ok( $distance == 2, '2 links separate Harrison and Kevin' );

diag( "path=" . join ", ", @$path );

exit(0);

=head2 movie_breadth_first_search

Given and starting and and ending actor id, finds
the shortest path from one to the other in the graph.

Returns the number of links required, and the path of names
leading from start to end.


=cut 

sub movie_breadth_first_search {
    my ( $startId, $endId, $graph ) = @_;

    my @actorIds   = ( [ $startId, undef ] );
    my $foundIds   = Set::Scalar->new();
    my $iterations = 0;

    while (@actorIds) {
        $iterations++;
        my @movieIds;

        # get adjacent movies
        for my $x (@actorIds) {
            my ( $actorId, $parent ) = @$x;
            for my $triple ( $graph->triples( undef, 'starring', $actorId ) ) {
                my $movieId = $triple->[0];
                if ( !$foundIds->has($movieId) ) {
                    $foundIds->insert($movieId);
                    push @movieIds, [ $movieId, [ $actorId, $parent ] ];
                }
            }
        }    # while actorId, parent

        # get adjacent actors
        my @nextActorIds;

        for my $mId (@movieIds) {
            my ( $movieId, $parent ) = @$mId;
            for my $t ( $graph->triples( $movieId, 'starring', undef ) ) {
                my $actorId = $t->[2];
                if ( !$foundIds->has($actorId) ) {
                    $foundIds->insert($actorId);
                    if ( $actorId eq $endId ) {
                        return ( $iterations,
                            [ $actorId, [ $movieId, $parent ] ] );
                    }
                    else {
                        push @nextActorIds, [ $actorId, [ $movieId, $parent ] ];
                    }
                }
            }
        }    # while movieId, parent

        @actorIds = @nextActorIds;
    }    # while actorIds > 0

    #We have run out of actors
    return ( undef, undef );
}    # end movie_breadth_first_search

=head2 find_path

Converts actor name to id and calls movie_breadth_first_search.

=cut

sub find_path {
    my ( $start, $end, $graph ) = @_;

    my $startId = $graph->value(undef, 'name', $start);

    my $endId = $graph->value(undef, 'name', $end);

    my ( $distance, $path ) =
      movie_breadth_first_search( $startId, $endId, $graph );
    my @names;
    while ( defined($path) ) {
        my ( $id, $nextPath ) = @{$path};
        push @names,
          $graph->value($id, 'name', undef);
        $path = $nextPath;
    }
    return ( $distance, \@names );

}

