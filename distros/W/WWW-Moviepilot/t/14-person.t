use warnings;
use strict;

use Test::More;

use_ok( 'WWW::Moviepilot' );

BEGIN {
    plan skip_all => 'set WWW_MOVIEPILOT_APIKEY to enable this test'
        unless $ENV{WWW_MOVIEPILOT_APIKEY};
    plan tests => 6;
}

my $conninfo = { api_key => $ENV{WWW_MOVIEPILOT_APIKEY} };
$conninfo->{host} = $ENV{WWW_MOVIEPILOT_HOST} if $ENV{WWW_MOVIEPILOT_HOST};

my $m = WWW::Moviepilot->new($conninfo);
isa_ok( $m, 'WWW::Moviepilot' );

my $person = $m->person('paul-newman');
isa_ok( $person, 'WWW::Moviepilot::Person' );
is( $person->date_of_birth, '1925-01-26' );

# search paul newman
my @res = $m->search_person('Paul Newman');
my $paul = (grep { defined $_->date_of_birth && $_->date_of_birth eq '1925-01-26' } @res)[0];
isa_ok( $m, 'WWW::Moviepilot' );
is( $paul->first_name, 'Paul' );
