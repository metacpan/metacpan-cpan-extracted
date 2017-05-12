# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use Test;
use strict;

my ($testcount, $widget, $mw, $foo);
BEGIN { $testcount = 16;  plan tests => $testcount };

eval { require Tk; };
ok($@, "", "loading Tk module");

eval {$mw = MainWindow->new() };
if ($mw) {
	#--------------------------------------------------------------
	my $class = 'DTree';
	$foo = 'i01';
	my $bar = 'DummyProject';
	my $result;
	my %bar = ('txt1' => 'data1', 'txt2' => 'data2', 'txt3' => 'data3' );
	#--------------------------------------------------------------
	print "Testing $class\n";

	eval "require Tk::$class;";
	ok($@, "", "Error loading Tk::$class");

	eval { $widget = $mw->$class(); };
	ok($@, "", "can't create $class widget");
	skip($@, Tk::Exists($widget), 1, "$class instance does not exist");

	if (Tk::Exists($widget)) {
    	eval { $widget->pack; };

    	ok ($@, "", "Can't pack a $class widget");
    	eval { $mw->update; };
    	ok ($@, "", "Error during 'update' for $class widget");
		#------------------------------------------------------------------
		my $style = $mw->ItemStyle ('text' ,
								-anchor => 'e',
								#-justify => 'right',
								#-wraplength => '6',
								-background => 'yellow',	);
    	eval { $widget->configure( -datastyle => $style ); };
    	ok ($@, "", "Error: can't configure  '-datastyle' for $class widget");
    	eval { $widget->configure( -sizecmd => \&test_cb ); };
    	ok ($@, "", "Error: can't configure  '-sizecmd' for $class widget");
		#
    	eval { $widget->add('i01', -data => 'i01',
					-itemtype => 'text',
					-text => 'DummyProject',
					#-image => $xpms{project_icon},
					-datastyle => $style); };
    	ok ($@, "", "Error: can't add text/data for $class widget");
    	eval { $widget->add('i02', -data => 'i02',
					-itemtype => 'text',
					-text => 'DummyTask',
					#-image => $xpms{task_icon},
					-datastyle => $style,); };
    	ok ($@, "", "Error: can't add text/data for $class widget");
    	eval { $result = $widget->get_item('i01'); };
		ok($result, $bar, "can't get scalar from $class widget");
    	$result = $widget->get_item_value('i01');
		ok($result, $foo, "$result, $bar can't get data of scalar from $class widget");

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
