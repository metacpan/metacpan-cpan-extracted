#!perl -T

use Test::More tests => 2;

use TryCatch::Error;

my $e = TryCatch::Error->new;

ok( defined $e, 'New object created' );
isa_ok( $e, 'TryCatch::Error' );
