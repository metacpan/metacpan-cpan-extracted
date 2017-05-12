# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use Test;
use strict;

my ($testcount, $widget, $mw, $foo);
BEGIN { $testcount = 14;  plan tests => $testcount };

eval { require Tk; };
ok($@, "", "loading Tk module");

eval {$mw = MainWindow->new() };
if ($mw) {
	#--------------------------------------------------------------
	my $class = 'HListplus';
	$foo = 'i01';
	my $bar = 'DummyProject';
	my $result;
	#--------------------------------------------------------------
	print "Testing $class\n";

	eval "require Tk::$class;";
	ok($@, "", "Error loading Tk::$class");

	eval { $widget = $mw->$class(-columns => 3, -header => 1); };
	ok($@, "", "can't create $class widget");
	skip($@, Tk::Exists($widget), 1, "$class instance does not exist");

	if (Tk::Exists($widget)) {
    	eval { $widget->pack; };

    	ok ($@, "", "Can't pack a $class widget");
    	eval { $mw->update; };
    	ok ($@, "", "Error during 'update' for $class widget");
		#------------------------------------------------------------------
		my $headerstyle = $mw->ItemStyle ('window', -padx => 0, -pady => 0);
    	eval { $widget->header('create', 0, 
        	  -itemtype => 'resizebutton',
        	  -style => $headerstyle,
        	  -text => 'Test Name1', );
		};
    	ok ($@, "", "Error: can't set header  '-itemtype => resizebutton' for $class widget");
    	eval { $widget->header('create', 1, 
        	  -itemtype => 'resizebutton',
        	  -style => $headerstyle,
        	  -text => 'Test Name2', 
			  -activeforeground => 'blue',);
		};
    	ok ($@, "", "Error: can't set header  '-activeforeground' for $class widget");
		#
    	eval { $widget->header('create', 1, 
        	  -itemtype => 'resizebutton',
        	  -style => $headerstyle,
        	  -text => 'Test Name2', 
			  -activebackground => 'orange',);
		};
    	ok ($@, "", "Error: can't set header  '-activebackground' for $class widget");
		#
    	eval { $widget->header('create', 1, 
        	  -itemtype => 'resizebutton',
        	  -style => $headerstyle,
        	  -text => 'Test Name2', 
			  -command => \&test_cb);
		};
    	ok ($@, "", "Error: can't set header  '-activebackground' for $class widget");
		#

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
	print "test_cb called with [@_], \$foo = >$foo<\n";
}

1;
