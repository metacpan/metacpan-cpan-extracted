### tests for perl/Tk FcyEntry widget

# About the tests:  Biggest miss is that only simple flow is checked.
#		    But this means only that the code is not verified
#		    to work for any non trival usage :-(

use strict;
use lib '../lib'; # silence Komodo IDE debuger warnings
use Tk;
use Tk::FcyEntry;	# replace std entry
use Test::More;
use Carp;

my $mw;
eval{ $mw = Tk::MainWindow->new(); };
if (! $mw) {

  # there seems to be no x-server available or something else went wrong
  # .. skip all tests
  plan skip_all => 'No display found';
  exit 0;

}else{

	my $counter = 0;
	my $mw;
	my $msg;
	my $bye;
	
	sub testarea {
		my $num = shift;
		diag("1..$num");
		$mw = MainWindow->new();
		$mw->title($0);
		$mw->iconname($0);
		$mw->protocol('WM_DELETE_WINDOW' => sub {$mw->destroy});
	
		my $work = $mw->Frame(-width=>4,-height=>4,-borderwidth=>2,-relief=>'sunken')
		->pack(-fill=>'both', -expand=>'yes');
	
		if (@ARGV) {
		$msg = $mw->Entry(-width=> 20)->pack();
		$msg->insert(0,'Running...');
		$bye = $mw->Button(-text=>'Exit', -command=>sub{$mw->destroy})->pack;
		}
		$work;
	};
	
	sub testend {
		 diag("# Done");
		 if (@ARGV) {
			 $msg->delete(0,'end');
			 $msg->insert(0,'All tests done.');
			 $bye->focus;
			 MainLoop;
		 }
	}


	$| = 1;
	my $verbose = 1;

	my $parent = testarea('8');


	######## creation ########

	my $xe = $parent->Entry();
	ok(defined $xe);
	ok(defined $xe->pack(-fill=>'x'));

	######## methods ##########

	{
	  print "# method tests...\n" if $verbose;

	  $xe->delete(0,'end');
	  ok("" eq $xe->get);
	  $xe->insert(0,'foo');
	  ok("foo" eq $xe->get);
	  $xe->insert(0, 'a');
	  ok("afoo" eq $xe->get);
	  $xe->insert('end','bar');
	  ok("afoobar" eq $xe->get);
	}

	######## options ##########

	{
	  print "# -color tests...\n" if $verbose;

	  eval { $xe->cget('-editcolor') };
	  ok (not $@);
	  ok ( $xe->cget('-editcolor') ne $xe->cget('-background') );

	#  print "# -status tests...\n" if $verbose;
	#  print STDERR "failure of next test is a known misfeature :-(\n";
	#  ###  -background (and -editcolor) return same regardless of
	#  ### -state same value.  So semantic to query 'real' back
	#  ### ground is not known
	#
	#  $xe->configure(-state => 'disabled');
	#  my $d_bg = $xe->cget('-background');
	#  $xe->configure(-state => 'normal');
	#  my $n_bg = $xe->cget('-background');
	#  if ($n_bg ne $d_bg) {
	#	ok(1);
	#  } else {
	#	print "# Why bg color '$n_bg' same for 'normal' and disabled'??\n";
	#	ok(0)
	#  }

	}

	testend();
	done_testing();
}


