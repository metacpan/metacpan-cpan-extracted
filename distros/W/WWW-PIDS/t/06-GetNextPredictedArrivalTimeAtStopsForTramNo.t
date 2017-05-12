#!/usr/bin/perl

use strict;
use warnings;

use WWW::PIDS;
use Test::More tests => 3;

my $p = WWW::PIDS->new();

ok( defined $p				, 'Invoked constructor'						);
ok( $p->isa( 'WWW::PIDS' )		, 'Returned object isa WWW::PIDS'				);
ok( $p->can('GetNextPredictedArrivalTimeAtStopsForTramNo')
		, 'WWW::PIDS can ->GetNextPredictedArrivalTimeAtStopsForTramNo()'			);
#my @d = $p->GetNextPredictedArrivalTimeAtStopsForTramNo( tramNo => 64 );
#cmp_ok( ~~@d, '>=', 1			
#		, 'GetNextPredictedArrivalTimeAtStopsForTramNo() returned at least one result object'	);
