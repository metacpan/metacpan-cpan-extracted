
require 5;
use strict;
use Test;
BEGIN { plan tests => 25 }

#sub XML::RSS::Timing::DEBUG () {10}

use XML::RSS::Timing;
print "# I'm testing XML::RSS::Timing version $XML::RSS::Timing::VERSION\n";

ok 1;
print "# Required OK.\n";

use Time::Local;
my $E1970 = timegm(0,0,0,1,0,70);
ok 1;
print "# E1970 = $E1970 s  (", scalar(gmtime($E1970)), ")\n";

my $x = XML::RSS::Timing->new;

sub n ($) { XML::RSS::Timing->_iso_date_to_epoch( $_[0] ); }
sub between ($$$;$) {
  my($earlier, $later, $period, $freq) = @_;
  $earlier = n($earlier);
  $later   = n($later);
  $x->updatePeriod($period);
  $x->updateFrequency(  $freq || 1);
  my $then = $x->nextUpdate;
  print "# Testing 1980-01-27T00:00 < nextupdate < 1980-02-03T00:00\n";
  print "#  Earlier: ", scalar(gmtime($earlier)), "\n";
  print "#     Then: ", scalar(gmtime($then   )), "\n";
  print "#    Later: ", scalar(gmtime($later  )), "\n";
  ok( ( $earlier < $then ), 1, "$earlier should be less than $then" );
  ok( ( $then < $later   ), 1, "$then should be less than $later"   );
}

$x->updateBase(   '1980-01-01T00:00' );
$x->lastPolled( n('1980-01-01T00:15') );

between( '1980-01-27T00:00', '1980-02-04T00:00', 'monthly',     );
between( '1980-01-27T00:00', '1980-02-04T00:00', 'monthly', '1' );
between( '1980-01-12T00:00', '1980-01-17T00:00', 'monthly', '2' );
between( '1980-01-08T00:00', '1980-01-12T00:00', 'monthly', '3' );

between( '1980-12-10T00:00', '1981-01-20T00:00', 'yearly',     );
between( '1980-12-10T00:00', '1981-01-20T00:00', 'yearly', '1' );
between( '1980-06-10T00:00', '1980-07-10T00:00', 'yearly', '2' );

my $month = 28 * 24 * 60 * 60;
$x->maxAge( $month );

between( '1980-01-27T00:00', '1980-01-29T02:00', 'yearly',     );
between( '1980-01-27T00:00', '1980-01-29T02:00', 'yearly', '1' );
between( '1980-01-27T00:00', '1980-01-29T02:00', 'yearly', '2' );
between( '1980-01-27T00:00', '1980-01-29T02:00', 'yearly', '3' );


print "# That's it.\n";
ok 1;

