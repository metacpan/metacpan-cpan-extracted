use Test::More tests => 8;  # -*- mode: cperl -*-

use lib qw(../lib lib ); # Test in-place

BEGIN {
use_ok( 'Web::SIVA' );
}

my $siva_provincia = new Web::SIVA "gr"; # two-letter acronym for provinces in Andalucía
is( ref $siva_provincia, "Web::SIVA", "Object OK" );


#Checks different formats
my $data_day = $siva_provincia->day( 1, 1, 1998 ); # Corner case
is (@$data_day, 0, "No data");
$data_day = $siva_provincia->day( 3, 3, 1998 ); # Corner case
is ($data_day->[0]{'SO2'}, 189, "Data text format 1 OK");
my $data_2003 = $siva_provincia->day( 3, 3, 2003 ); # Previous to 11-Jan-2004
is ( $data_2003->[575]{'CO'}, 1323, "Text data OK");
$data_2003 = $siva_provincia->day( 10, 1, 2004 ); # Previous to 11-Jan-2004
is ( $data_2003->[100]{'PART'}, 57, "HTML data OK");
$data_2003 = $siva_provincia->day( 11, 1, 2004 ); # After 11-Jan-2004
is ( $data_2003->[0]{'SO2'}, 13, "HTML data OK");
my $data_yesterday = $siva_provincia->day( 4, 3, 2017 ); # As in March 4th, 2017
is ( $data_yesterday->[574]{'CO'}, 146, "HTML data OK");

diag( "Testing Web::SIVA $Web::SIVA::VERSION" );
