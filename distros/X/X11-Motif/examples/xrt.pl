#!../xperl -w

use blib;

use strict;
use X11::XRT qw(:XRT);

print "Using X11::XRT version $X11::XRT::VERSION (which uses X11::Motif version $X11::Motif::VERSION)\n";

print "Using Motif version ", X::Motif::XmVersion, " (",
      join('.', X::Motif::XmVERSION, X::Motif::XmREVISION, X::Motif::XmUPDATE_LEVEL), ")\n";

print "Using XRT version ", X::XRT::XRT_RELEASE, " (",
      join('.', X::XRT::XRT_VERSION, X::XRT::XRT_REVISION, X::XRT::XRT_POINT), ")\n";

print "This is beta #", X11::XRT::beta_version(), "\n" if (X11::XRT::beta_version());

my $toplevel = X::Toolkit::initialize("XRTDemo");

my $form = give $toplevel -Form;
my $menubar = give $form -MenuBar;
my $menu = give $menubar -Menu, -name => 'File';
	give $menu -Button, -text => 'Exit', -command => sub { exit 0 };

my $pie_graph = give $form -Graph,
	-xrtType => XRT_TYPE_PIE,
	-xrtGraphBackgroundColor => 'tan',
	-xrtForegroundColor => 'black',
	-xrtBackgroundColor => 'white',
	-xrtDoubleBuffer => X::True,
	-xrtData => XrtDataCreateFromFile('data/cpu_utilization.dat'),
	-xrtSetLabels => [ 'User', 'System', 'Idle' ],
	-xrtPointLabels => [ 'Current', 'Historical' ],
	-xrtHeaderStrings => 'CPU Usage';

my $bar_graph = give $form -Graph,
	-xrtType => XRT_TYPE_BAR,
	-xrtYMin => -10,
	-xrtYMax => 60,
	-xrtGraphBackgroundColor => 'tan',
	-xrtForegroundColor => 'black',
	-xrtBackgroundColor => 'white',
	-xrtDoubleBuffer => X::True,
	-xrtData => XrtDataCreateFromFile('data/cpu_utilization.dat'),
	-xrtSetLabels => [ 'User', 'System', 'Idle' ],
	-xrtHeaderStrings => 'CPU Usage',
	-xrtXTitle => 'This is the X title',
	-xrtYTitle => 'This is the Y title',
	-xrtYTitleRotation => XRT_ROTATE_90;

constrain $menubar -top => -form, -left => -form, -right => -form;
constrain $pie_graph -top => $menubar, -bottom => $bar_graph, -left => -form, -right => -form;
constrain $bar_graph -bottom => -form, -left => -form, -right => -form;

handle $toplevel;
