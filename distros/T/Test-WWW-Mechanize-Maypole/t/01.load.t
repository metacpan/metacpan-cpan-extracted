use Test::More tests => 1;

BEGIN {
use lib 'ex'; # Where BeerDB should live
use_ok( 'Test::WWW::Mechanize::Maypole', qw(BeerDB) );
}

diag( "Testing Test::WWW::Mechanize::Maypole $Test::WWW::Mechanize::Maypole::VERSION, Perl 5.008006, /usr/local/bin/perl" );
