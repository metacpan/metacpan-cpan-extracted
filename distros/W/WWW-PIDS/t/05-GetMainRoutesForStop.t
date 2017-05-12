#!/usr/bin/perl

use strict;
use warnings;

use WWW::PIDS;
use Test::More tests => 7;

my $p = WWW::PIDS->new();

ok( defined $p				, 'Invoked constructor'						);
ok( $p->isa( 'WWW::PIDS' )		, 'Returned object isa WWW::PIDS'				);
ok( $p->can('GetMainRoutes')		, 'WWW::PIDS can ->GetMainRoutes()'				);
ok( $p->can('GetMainRoutesForStop')	, 'WWW::PIDS can ->GetMainRoutesForStop()'			);
my @d = $p->GetMainRoutes();
cmp_ok( ~~@d, '>=', 1			, 'GetMainRoutes() returned at least one result object'		);
ok( $d[0]->isa('WWW::PIDS::RouteNo')	, 'Result object 1 is a WWW:PIDS::RouteNo object'		);
ok( $d[0] =~ /\d+\w*/			, 'Result object stringifies to a value of expected format'	);
