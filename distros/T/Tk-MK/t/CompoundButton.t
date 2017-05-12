# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use Test;
use strict;

my ($testcount, $widget, $mw);
BEGIN { $testcount = 11;  plan tests => $testcount };

eval { require Tk; };
ok($@, "", "loading Tk module");

eval {$mw = MainWindow->new() };
if ($mw) {
	#--------------------------------------------------------------
	my $class = 'CompoundButton';
	my $downangle = <<'downangle_EOP';
    	/* XPM */
    	static char *arrow[] = {
    	"14 9 2 1",
    	". c none",
    	"X c black",
    	"..............",
    	"..............",
    	".XXXXXXXXXXXX.",
    	"..XXXXXXXXXX..",
    	"...XXXXXXXX...",
    	"....XXXXXX....",
    	".....XXXX.....",
    	"......XX......",
    	"..............",
    	};
downangle_EOP
	#--------------------------------------------------------------
	print "Testing $class\n";

	eval "require Tk::$class;";
	ok($@, "", "Error loading Tk::$class");

	eval { $widget = $mw->$class(-text => 'test', -bitmap => 'error', -side => 'bottom'); };
	ok($@, "", "can't create $class widget");
	skip($@, Tk::Exists($widget), 1, "$class instance does not exist");

	if (Tk::Exists($widget)) {
    	eval { $widget->pack; };

    	ok ($@, "", "Can't pack a $class widget");
    	eval { $mw->update; };
    	ok ($@, "", "Error during 'update' for $class widget");
		#------------------------------------------------------------------
    	eval { $widget->configure( -command  => \&test_cb ); };
    	ok ($@, "", "Error: can't configure  '-command' for $class widget");

		# here we need some more tests
		#...

		#------------------------------------------------------------------

    	eval { my @dummy = $widget->configure; };
    	ok ($@, "", "Error: configure list for $class");
    	eval { $mw->update; };
    	ok ($@, "", "Error: 'update' after configure for $class widget");

    	eval { $widget->destroy; };
    	ok($@, "", "can't destroy $class widget");
    	ok(!Tk::Exists($widget), 1, "$class: widget not really destroyed");
	} else  { 
    	for (1..5) { skip (1,1,1, "skipped because widget couldn't be created"); }
	}
}
else {
	# Until very recently, Tk wouldn't build without a display. 
	# As a result, the testing software would look at the test 
	# failures for your module and think "ah well, one of his
	# pre-requisites failed to build, so it's not his fault"
	# and throw the report away. The most recent versions of Tk,
	# however, *will* build without a display - 
	# it just skips all the tests.
	skip ("Skip  (No local X11 environment for Tk available) ") for (2 .. $testcount);
}
sub test_cb
{
	print "test_cb called with [@_].\n";
}

1;
