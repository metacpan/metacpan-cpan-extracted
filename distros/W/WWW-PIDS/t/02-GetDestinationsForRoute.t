#!/usr/bin/perl

use strict;
use warnings;

use WWW::PIDS;
use Test::More tests => 13;

my $p = WWW::PIDS->new();

ok( defined $p						, 'Invoked constructor'						);
ok( $p->isa( 'WWW::PIDS' )				, 'Returned object isa WWW::PIDS'				);
ok( $p->can('GetDestinationsForAllRoutes')		, 'WWW::PIDS can ->GetDestinationsForAllRoutes() (required to retrieve a routeNo)');
ok( $p->can('GetDestinationsForRoute')			, 'WWW::PIDS can ->GetDestinationsForRoute()'			);
my @d = $p->GetDestinationsForAllRoutes();
cmp_ok( ~~@d, '>=', 1                                   , 'Got at least one result from invoking GetDestinationsForAllRoutes()');
ok( $d[0]->isa('WWW::PIDS::Destination')		, 'Result isa WWW:PIDS::Destination object'			);
ok( $d[0]->can('RouteNo')				, 'Object can RouteNo() - using as parameter for GetDestinationsForRoute()');
my $d = $p->GetDestinationsForRoute( routeNo => $d[0]->{RouteNo} );
ok( defined $d						, 'Invoked GetDestinationsForRoute() and got a result'		);
ok( $d->isa('WWW::PIDS::RouteDestination')		, 'Result object type isa WWW::PIDS::RouteDestination'		);
ok( $d->can('DownDestination')				, 'Object can ->DownDestination()'				);
ok( $d->can('UpDestination')				, 'Object can ->UpDestination()'				);
ok( $d->DownDestination =~ /\w+/			, 'DownDestination() returns a string'				);
ok( $d->UpDestination =~ /\w+/				, 'UpDestination() returns a string'				);
