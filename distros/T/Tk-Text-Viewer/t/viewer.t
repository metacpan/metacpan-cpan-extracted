# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More qw(no_plan);
use Tk::Text::Viewer;
use Tk;
ok(1); # If we made it this far, were ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
my $mw; 

SKIP: {
   eval { $mw = MainWindow->new; };
   # Some automatic testing hosts are not confured to allow 
   # access to X-termianl
   skip "Failure to access X-terminal, bad host configuration assumed", 3 
      if $@ =~ /couldn't connect to display/;

   ok(1,"Connected to X-terminal we may proceed testing");


   ok($mw,"Main window defined"); #2

   # $t1 = $mw->Scrolled('Viewer', -wrap => 'none');
   $t1 = $mw->Viewer();

   ok($t1->pack(-side => 'right', -fill => 'both', -expand => 'yes'),"pack"); #3
   ok($t1->Load("$0"),"load $0"); #4
}
