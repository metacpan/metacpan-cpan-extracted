use warnings;
use strict;

use Test::More;

use_ok( 'WWW::Moviepilot' );

BEGIN {
    plan skip_all => 'set WWW_MOVIEPILOT_APIKEY to enable this test'
        unless $ENV{WWW_MOVIEPILOT_APIKEY};
    plan tests => 7;
}

my $conninfo = { api_key => $ENV{WWW_MOVIEPILOT_APIKEY} };
$conninfo->{host} = $ENV{WWW_MOVIEPILOT_HOST} if $ENV{WWW_MOVIEPILOT_HOST};

my $m = WWW::Moviepilot->new($conninfo);
isa_ok( $m, 'WWW::Moviepilot' );

my @cast = $m->cast('brust-oder-keule');
is( scalar @cast, 13 );

my $first = $cast[0];
isa_ok( $first, 'WWW::Moviepilot::Person' );

# search Louis de Funes
my $louis = (grep { $_->restful_url =~ /louis-de-funs/ } @cast)[0];
isa_ok( $louis, 'WWW::Moviepilot::Person' );

# character
is( $louis->character, 'Charles Duchemin' );

# field
is( $louis->date_of_birth, '1914-07-31' );
