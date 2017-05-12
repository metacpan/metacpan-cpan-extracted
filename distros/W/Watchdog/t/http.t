# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { plan tests => 2 }

use Watchdog::HTTP;

my @service = ( new Watchdog::HTTP,
		new Watchdog::HTTP(undef,'www.microsoft.com'),
	      );

for ( @service ) {
  print $_->id, ' is ... ';
  my $alive = $_->is_alive;
  if ( $alive == 0 || $alive == 1 ) {
    print $alive ? "alive\n" : "dead\n";
    ok(1);
  } else {
    ok(0);
  }
}
