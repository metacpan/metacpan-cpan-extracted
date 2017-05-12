BEGIN
  {
    $| = 1;
    $^W = 1;

    eval { require Test; };
    if ($@)
      {
        $^W=0;
	print "1..0\n";
	print STDERR "\n\tTest.pm module not installed.\n\tGrab it from CPAN to run this test.\n\t";
	exit;
      }
    Test->import;
  }
use strict;
##
## Test all widget classes:  load module, create, pack, and
## destory an instance. Check in configure does not return
## an error so (some) ConfigSpecs errors are uncovered
##

use vars '@class';

BEGIN 
  {
    @class =
      qw(
	Cloth
	FireButton
	NumEntryPlain
	NumEntry
	TFrame
      );

  };

my $mw;
BEGIN {
    if (!eval {
	require Tk;
	$mw = Tk::MainWindow->new();
	Tk::Exists($mw);
    }) {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
    }
}

plan test => 10*@class;

my $w;
foreach my $class (@class)
  {
    print "Testing $class\n";
    undef($w);

    eval "require Tk::$class;";
    ok($@, "", "Error loading Tk::$class");

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

1;
__END__
