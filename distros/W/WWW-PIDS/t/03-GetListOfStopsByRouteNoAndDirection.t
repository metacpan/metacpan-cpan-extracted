#!/usr/bin/perl

use strict;
use warnings;

use WWW::PIDS;
use Test::More tests => 8;


my $p = WWW::PIDS->new();

ok( defined $p						, 'Invoked constructor'						);
ok( $p->isa( 'WWW::PIDS' )				, 'Returned object isa WWW::PIDS'				);
ok( $p->can('GetMainRoutes')				, 'WWW::PIDS can ->GetMainRoutes() (required to get a valid routeNo parameter)');
ok( $p->can('GetListOfStopsByRouteNoAndDirection')	, 'WWW::PIDS can ->GetListOfStopsByRouteNoAndDirection()'	);
my @d = $p->GetMainRoutes();
cmp_ok( ~~@d, '>=', 1					, 'Invoked GetMainRoutes() and got at least one result object'	);
ok( $d[0]->isa('WWW::PIDS::RouteNo')			, 'Result object 1 is a WWW:PIDS::RouteNo object'		);
ok( $d[0] =~ /\d+\w*/					, 'Result object stringifies to a value of expected format'	);
@d = $p->GetListOfStopsByRouteNoAndDirection( routeNo => "$d[0]", isUpDirection => 0 );
cmp_ok( ~~@d, '>=', 1					, 'Invoked GetListOfStopsByRouteNoAndDirection() and got at least one result object');
