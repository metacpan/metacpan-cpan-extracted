#!/usr/bin/env perl

use Modern::Perl '2015';

use Test::More;
use Test::Exception;

BEGIN {
    require_ok('WG::API') || say "WG::API loaded";
}

diag $WG::API::VERSION;

my $wg;
lives_ok { $wg = WG::API->new( application_id => $ENV{'WG_KEY'} || 'demo' ) } 'create obj';

isa_ok( $wg,       'WG::API' );
isa_ok( $wg->net,  'WG::API::NET' );
isa_ok( $wg->wot,  'WG::API::WoT' );
isa_ok( $wg->wowp, 'WG::API::WoWp' );
isa_ok( $wg->wows, 'WG::API::WoWs' );
isa_ok( $wg->auth, 'WG::API::Auth' );

isa_ok( $wg->net->ua, 'HTTP::Tiny' );

done_testing();
