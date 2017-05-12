#!/usr/bin/perl

use strict;
use warnings;

use WWW::PIDS;
use Test::More tests => 11;


my $p = WWW::PIDS->new();

ok( defined $p						, 'Invoked constructor'						);

ok( $p->isa( 'WWW::PIDS' )				, 'Returned object isa WWW::PIDS'				);

ok( $p->can('GetDestinationsForAllRoutes')		, 'WWW::PIDS can ->GetDestinationsForAllRoutes()'		);

my @d = $p->GetDestinationsForAllRoutes();

cmp_ok( ~~@d, '>=', 2					, 'Got at least two result objects'				);

ok( $d[ int rand $#d ]->isa('WWW::PIDS::Destination')	, 'Randomly selected result object is a WWW:PIDS::Destination'	);

my ( %r, %d, %u ) = ();

map { $r{ $_->{RouteNo} }++; $d{ $_->{Destination} }++; $u{ $_->{UpStop} }++ } @d;

for ( qw(Destination RouteNo UpStop) ) { 
	ok( $d[ int rand $#d ]->can($_)			, "Randomly selected result object can ->$_()"			);
}

ok( ( keys %r ) >= 2					, 'At least two different routes defined in results'		);

ok( ( keys %d ) >= 2					, 'At least two different destinations defined in results'	);

ok( (grep { !/^(false|true)$/ } keys %u) eq 0		, 'UpStop attribute contains booleans only'			);
