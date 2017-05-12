BEGIN
  {
    $| = 1;
    $^W = 1;

    eval { require Test; };
    if ($@)
      {
        $^W=0;
	print "1..0 # skip no Test module\n";
	CORE::exit(0);
      }
    Test->import;
  }

use strict;
use Tk;
##
## Test all widget classes:  load module, create, pack, and
## destory an instance. Check in configure does not return
## an error so (some) ConfigSpecs errors are uncovered
##

use vars '@class';
use vars '@tk_pod_modules';

my $tests;
BEGIN 
  {
    @class =
      qw(
	More
	PodText
	PodSearch
	PodTree
	Pod
      );
    @tk_pod_modules = qw(Cache FindPods Search_db Search SimpleBridge Styles
			 Util WWWBrowser);

    $tests = 10*@class+@tk_pod_modules;
    plan test => $tests;

  };

$ENV{TKPODDEBUG} = 0;

if (!defined $ENV{BATCH}) {
    $ENV{BATCH} = 1;
}

my $mw;
eval {$mw = Tk::MainWindow->new();};
if (!Tk::Exists($mw))
  {
    for (1..$tests) 
      {
	skip("Cannot create MainWindow", 1, 1);
      }
    CORE::exit(0);
  }
$mw->geometry("+1+1"); # for twm

my $w;
foreach my $class (@class)
  {
    print "# Testing $class\n";
    undef($w);

    if ($class =~ m{^Pod(Text|Search|Tree)$})
      {
	my $module = "Tk::Pod::$1";
	# Tks autoload does not find it.
	eval qq{ require $module; };
	ok($@, "", "loading $module module");
      }
    else
      {
	eval "require Tk::$class;";
	ok($@, "", "Error loading Tk::$class");
      }

    eval { $w = $mw->$class(); };
    ok($@, "", "can't create $class widget");
    skip($@, Tk::Exists($w), 1, "$class instance does not exist");

    if (Tk::Exists($w))
      {
        if ($w->isa('Tk::Wm'))
          {
	    # KDE-beta4 wm with policies:
	    #     'interactive placement'
	    #		 okay with geometry and positionfrom
	    #     'manual placement'
	    #		geometry and positionfrom do not help
	    eval { $w->positionfrom('user'); };
            #eval { $w->geometry('+10+10'); };
	    ok ($@, "", 'Problem set postitionform to user');

            eval { $w->Popup; };
	    ok ($@, "", "Can't Popup a $class widget")
          }
        else
          {
	    ok(1); # dummy for above positionfrom test
            eval { $w->pack; };
	    ok ($@, "", "Can't pack a $class widget")
          }
        eval { $mw->update; };
        ok ($@, "", "Error during 'update' for $class widget");

	if (!$ENV{BATCH}) {
	    $mw->messageBox(-icon => "info", -message => "Showing '$class'", -type => "Continue");
	}
 
        eval { my @dummy = $w->configure; };
        ok ($@, "", "Error: configure list for $class");
        eval { $mw->update; };
        ok ($@, "", "Error: 'update' after configure for $class widget");
        eval { $w->destroy; };
        ok($@, "", "can't destroy $class widget");
        ok(!Tk::Exists($w), 1, "$class: widget not really destroyed");
      }
    else
      { 
        # Widget $class couldn't be created:
	#	Popup/pack, update, destroy skipped
	for (1..5) { skip (1,1,1, "skipped because widget could not be created"); }
      }
  }

print "# Require all modules\n";
for my $base (@tk_pod_modules) {
    eval "require Tk::Pod::$base";
    if ($@ && $base eq 'Search_db') {
	ok($@ =~ m{locate Text.*English}, 1, "Could not require Tk::Pod::$base: $@");
    } else {
	ok($@, "", "Could not require Tk::Pod::$base: $@");
    }
}

1;
__END__
