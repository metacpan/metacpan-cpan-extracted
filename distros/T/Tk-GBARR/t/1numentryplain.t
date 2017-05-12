BEGIN
  {
    $^W = 1;
    $| = 1;

    eval { require Test; };
    if ($@)
      {
        $^W=0;
        print "1..0\n";
        print STDERR "\n\tTest.pm module not installed.\n\tGrab it from CPAN.\n\t";
        exit;
      }
    Test->import;
  }
use strict;
use Tk;

my $mw;
BEGIN 
  {
    if (!eval { $mw = Tk::MainWindow->new })
      {
	print "1..0 # skip cannot open DISPLAY\n";
	CORE::exit;
      }
  }

BEGIN { plan tests => 10 };

my $nep;
{
   eval { require Tk::NumEntryPlain; };
   ok($@, "", 'Problem loading Tk::NumEntryPlain');
   eval { $nep = $mw->NumEntryPlain(); };
   ok($@, "", 'Problem creating NumEntryPlain widget');
   ok( Tk::Exists($nep) );
   eval { $nep->grid; };
   ok($@, "", '$text->grid problem');
   eval { $nep->update; };
   ok($@, "", '$nep->update problem');
}
##
## Check that -textvariable works for reading
##	(set work but not supported)
##
{
    my $num = 0;
    my $e = $mw->NumEntryPlain(-textvariable=>\$num);
    eval { $e->value(6); };
    ok($@, "", 'Problem setting value');
    ok($num, "6", "Textvariable is not updated");

    eval { $e->update; };
    ok($@, "", 'Problem in update after setting value');
}

##
## Check -increment, -bigincrement, -command and -browsecmd options
{
    my $command = 0;
    my $browsecmd = 0;
    my $e = $mw->NumEntryPlain(-increment    => 0.1,
			       -bigincrement => 50,
			       -command => sub { $command++ },
			       -browsecmd => sub { $browsecmd++ },
			      );
    ok($e->cget(-increment), 0.1);
    ok($e->cget(-bigincrement), 50);

    if (0) {
	# XXX eventGenerate does not work
	if ($Tk::VERSION < 800.017) {
	    skip("No -warp option for eventGenerate", 1) for (1..3);
	} else {
	    $e->update;
	    my $x = $e->width/2;
	    my $y = $e->height/2;
	    $e->eventGenerate("<Motion>", '-x' => $x, '-y' => $y, -warp => 1);
	    $e->eventGenerate("<Up>");
	    ok($e->get, "1");
	    ok($browsecmd, 1);
	    $e->eventGenerate("<Return>",
			      '-x' => $x, '-y' => $y,
			      -warp => 1);
	    ok($command, 1);
	}
    }
}

