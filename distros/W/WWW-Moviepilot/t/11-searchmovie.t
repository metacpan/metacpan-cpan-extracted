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

# no query provided
eval { $m->search_movie() };
like( $@, qr/400 Bad Request/ );

# no results
my @res = $m->search_movie('doesnotexist');
is( scalar @res, 0 );

# valid query returns at 20 results
@res = $m->search_movie('matrix');
is( scalar @res, 20 );

# one result
@res = $m->search_movie('Brust oder Keule');
is( scalar @res, 1 );

# special characters
@res = $m->search_movie('?&/');
is( scalar @res, 0 );
