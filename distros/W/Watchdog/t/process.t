# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
BEGIN { 
  eval { require Proc::ProcessTable; };
  if ( $@ ) {
    print "1..0\n";
    exit 0;
  }
  plan tests => 3
}

#my $skip = eval "require Proc::ProcessTablea" ? 0 : 1;
#die "\$skip = $skip";
use Watchdog::Process;

my @service = ( new Watchdog::Process('cron','cron'),
		new Watchdog::Process('sendmail','sendmail'),	
		new Watchdog::Process('foobar','foobar'),
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
