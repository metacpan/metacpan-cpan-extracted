print "1..1\n";

use strict;
use Unicode::Map;

my $Map = new Unicode::Map ( "ISO-8859-1" );
my @errors = @{$Map->_system_test()};
if ( @errors ) {
   printf ( STDERR "(err @errors) " );
   print "not ";
}
print "ok 1";
