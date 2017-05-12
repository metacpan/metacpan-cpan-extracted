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

my @filmography = $m->filmography('louis-de-funs');
is( scalar @filmography, 20 );

my $first = $filmography[0];
isa_ok( $first, 'WWW::Moviepilot::Movie' );

# search Brust oder Keule
my $bok = (grep { $_->restful_url =~ /brust-oder-keule/ } @filmography)[0];
isa_ok( $bok, 'WWW::Moviepilot::Movie' );

# character
is( $bok->character, 'Charles Duchemin' );

# field
is( $bok->display_title, 'Brust oder Keule' );
