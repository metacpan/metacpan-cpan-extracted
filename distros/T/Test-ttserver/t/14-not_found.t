use strict;
use warnings;
use Test::More 'tests' => 3;
use Test::ttserver;

undef $ENV{'PATH'};
@Test::ttserver::SearchPaths = ();

ok( !defined $Test::ttserver::errstr, 'no error' );
ok( !defined Test::ttserver->new, 'can not instantiate' );
like( $Test::ttserver::errstr, qr/could not find/, 'has error' );
