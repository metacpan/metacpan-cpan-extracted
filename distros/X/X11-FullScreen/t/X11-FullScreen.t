# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl X11-FullScreen.t'

#########################

use strict;
use warnings;

use FindBin '$Bin';

use Test::More;
BEGIN { use_ok('X11::FullScreen') };

#########################

our $Image = "$Bin/2003stephencentauri.png";


my $display_str = $ENV{'DISPLAY'};
my $display = X11::FullScreen->new($display_str // ':0');
isa_ok($display, 'X11::FullScreen');

my $continue = 0;

SKIP: {
  skip 'No DISPLAY variable set in env', 1 unless $display_str;

  eval {
  	$display->show();
  	ok(1,  "show called");
  	$continue = 1;
  };
  if ( $@ =~ /^Display not initialized/ ) {
  	ok(1, "show called (no connection)");
  }

}

SKIP: {
  skip 'No connection', 2 unless $continue;
      
  $display->sync();
  $display->display_still($Image);
  ok( defined $display->display, "Display is defined" );
  
  our $running = 1;
  $SIG{ALRM} = sub { $running = 0 };
  alarm(5);
  while ($running) {
    my $event = $display->check_event()
      or next;
    if ($event->get_type() == 12) {
      $display->display_still($Image);
    }
  }

  $display->close();
  ok(1, "Displayed images");
}

done_testing();