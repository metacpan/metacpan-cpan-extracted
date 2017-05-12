#!/usr/bin/perl

use strict;
use warnings;

use WWW::PIDS;
use Test::More tests => 6;

my $p = WWW::PIDS->new();

ok( defined $p				, 'Invoked constructor'						);
ok( $p->isa( 'WWW::PIDS' )		, 'Returned object isa WWW::PIDS'				);
ok( $p->can('GetNextPredictedRoutesCollection'), 'WWW::PIDS can ->GetNextPredictedRoutesCollection()'	);
my @d = $p->GetNextPredictedRoutesCollection( stopNo => 3101, routeNo => '3a', lowFloor => 0 );
cmp_ok( ~~@d, '>=', 1
	, 'GetNextPredictedRoutesCollection() returned at least one result object'			);
use Data::Dumper; print Dumper( @d );
ok( $d[0]->isa('WWW::PIDS::ScheduledTime'), 'Result object 1 is a WWW:PIDS::RouteNo object'		);
ok( $d[0] =~ /\d+\w*/			, 'Result object stringifies to a value of expected format'	);
