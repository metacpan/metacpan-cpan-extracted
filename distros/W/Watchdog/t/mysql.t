# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN {
  my $have_dbi = eval { require DBI; };
  my $have_dbd = eval { require DBD::mysql; };
  unless ( $have_dbi && $have_dbd ) {
    print "1..0\n";
    exit 0;
  }
  plan tests => 2
}

use Watchdog::Mysql;

my @service = ( new Watchdog::Mysql,
		new Watchdog::Mysql(undef,'contentdev'),
	      );

for ( @service ) {
  print $_->id, ' is ... ';
  my($alive,$error) = $_->is_alive;
  if ( $alive == 0 || $alive == 1 ) {
    print $alive ? "alive\n" : "dead: $error\n";
    ok(1);
  } else {
    ok(0);
  }
}
