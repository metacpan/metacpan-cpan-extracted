# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Xymon::Server::ExcelOutages' ); }

my $object = Xymon::Server::ExcelOutages->new ();
isa_ok ($object, 'Xymon::Server::ExcelOutages');


