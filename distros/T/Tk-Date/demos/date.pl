# A date/time widget demonstration.

use Tk;
use Tk::Date;
use Tk::ROText;

use vars qw($f $black
	    $i $row
	    @w @l1 @l2 @var @date);

sub date {
    my($demo) = @_;
    my $demo_widget = $MW->WidgetDemo
      (
       -name             => $demo,
       -text             => 'A date/time widget demonstration.',
       -title            => 'Date/Time Example',
       -iconname         => 'Date/Time',
      );
    my $top = $demo_widget->Top;   # get geometry master

    # bitmaps for left/right arrows
    my $HINCBITMAP = __PACKAGE__ . "::hinc";
    my $HDECBITMAP = __PACKAGE__ . "::hdec";

    my $hbits = pack("b8"x5,
		     ".....11.",
		     "...11.1.",
		     ".11...1.",
		     "...11.1.",
		     ".....11.");
    eval {
	$top->DefineBitmap($HDECBITMAP => 8,5, $hbits);
	$top->DefineBitmap($HINCBITMAP => 8,5,
			   pack("B8"x5, unpack("b8"x5, $hbits)));
    };

    $black = $top->cget(-foreground);
    $f = $top->Frame->pack(-side => 'left', -expand => 1, -fill => 'both');
    $i = 0;
    $row = 0;
    @w = @l1 = @l2 = ();

    $f->Frame(-background => $black, -height => 1
	     )->grid(-row => $row++, -column => 0,
		     -columnspan => 7, -sticky => 'ew');

    $f->Label(-text => 'Description')->grid(-row => $row, -column => 0,
					    -sticky => 'w');
    $f->Frame(-background => $black, -width => 0,
	     )->grid(-row => $row, -column => 1, -sticky => 'ns');
    $f->Label(-text => 'Widget')->grid(-row => $row, -column => 2,
				       -sticky => 'w');
    $f->Frame(-background => $black, -width => 0,
	     )->grid(-row => $row, -column => 3, -sticky => 'ns');
    $f->Label(-text => 'Value')->grid(-row => $row, -column => 4,
				      -sticky => 'w');
    $f->Frame(-background => $black, -width => 0,
	     )->grid(-row => $row, -column => 5, -sticky => 'ns');
    $f->Label(-text => 'Tie')->grid(-row => $row, -column => 6,
				    -sticky => 'w');

    $f->Frame(-background => $black, -height => 1
	     )->grid(-row => ++$row, -column => 0,
		     -columnspan => 7, -sticky => 'ew');
    $f->Frame(-height => 1
	     )->grid(-row => ++$row, -column => 0,
		     -columnspan => 7, -sticky => 'ew');
    $f->Frame(-background => $black, -height => 1
	     )->grid(-row => ++$row, -column => 0,
		     -columnspan => 7, -sticky => 'ew');
    $row++;

    single_widget('Empty date/time widget');

    single_widget('Only date', -fields => 'date');

    single_widget('Only time', -fields => 'time');

    my $i1 = single_widget('Non-editable', -editable => 0, -value => 'now');
    my $timer;
    $timer = $w[$i1]->repeat(999, sub {
				 if (Tk::Exists($w[$i1])) {
				     $w[$i1]->configure(-value => 'now');
				 } else {
				     $timer->cancel;
				 }
			     });

    single_widget('US format, choices',
		  -datefmt => "%2m/%2d/%4y",
		  -timefmt => "%2H.%2M.%2S",
		  -value => 'now',
		  -choices => ['today', 'reset'],
		  -command => sub { print STDERR join(" ", @_), "\n" },
		 );

    single_widget('All arrows',
		  -value => 'now',
		  -allarrows => 1,
		  -state => 'normal',#'disabled',
		  -command => sub { print STDERR join(" ", @_), "\n" },
		 );

    single_widget('All arrows, readonly',
		  -value => 'now',
		  -allarrows => 1,
		  -readonly => 1,
		  -command => sub { print STDERR join(" ", @_), "\n" },
		 );

    single_widget('Horizontal arrows',
		  -value => 'now',
		  -orient => "horiz",
		 );

    single_widget('With weekday',
		  -datefmt => "%12A, %2d.%2m.%4y",
		  -fields => 'date',
		  -value => 'now',
		 );

    single_widget('Only parts',
		  -datefmt => "%2d.%2m",
		  -timefmt => "%2H.%2M",
		  -value => 'now',
		  -choices => ['today', 'reset'],
		 );

    my $i2;
    $i2 = single_widget
      ('All options set',
       -choices => ['today', 'yesterday', 'tomorrow',
		    ['new year\'s eve' => { 'm' => 12,
					    'd' => 31 }],
		    ['christmas' => { 'm' => 12,
				      'd' => 25 }],
		    'reset'],
       -selectlabel => 'Wähle:',
       -bell => 0,
       -repeatinterval => 10,
       -repeatdelay => 300,
       -borderwidth => 2,
       -relief => 'raised',
       -innerbg => 'white',
       -innerfg => 'red',
       -orient => 'horiz',
       -weekdays => ['nedjelja', 'ponedjeljak', 'utorak', 'srijeda',
		     'cetvrtak', 'petak', 'subota'],
       -monthnames =>
       ["sije\x{010D}anj", "velja\x{010D}a", "o\x{017E}ujak", "travanj",
	"svibanj", "lipanj", "srpanj", "kolovoz", "rujan",
	"listopad", "studeni", "prosinac"],
       -monthmenu => 1,
       -incbitmap => $HINCBITMAP,
       -decbitmap => $HDECBITMAP,
       -command => sub {
	   warn $w[$i2]->get("%x, %X");
# segfaults... why?
#	   $l1[$i2]->configure(-text => $w[$i2]->get("%+"));
       },
       -check => 1,
      );


    my $getvalb = $f->Button
      (-text => 'Get values',
       -command => sub {
	   warn "Tie values:\n";
	   for(my $i = 0; $i <= $#w; $i++) {
	       $date[$i] = $w[$i]->get("%x, %X");
	       if (defined $w[$i]->cget(-variable)) {
		   warn "  $i: " . $ {$w[$i]->cget(-variable)} . "\n";
	       }
	   }
       })->grid(-row => $row, -column => 0,
		-columnspan => 7, -sticky => 'ew');
    $getvalb->invoke();
}

sub single_widget {
    my($desc, %args) = @_;
    $args{-variable} = \$var[$i];
    $f->Label(-text => $desc,
	     )->grid(-row => $row, -column => 0, -sticky => 'w');
    $f->Frame(-background => $black, -width => 0,
	     )->grid(-row => $row, -column => 1, -sticky => 'ns');
    $w[$i] = $f->Date(%args)->grid(-row => $row, -column => 2,
					   -sticky => 'w');
    $f->Frame(-background => $black, -width => 0,
	     )->grid(-row => $row, -column => 3, -sticky => 'ns');
    $l1[$i] = $f->Label(-textvariable => \$date[$i]
		       )->grid(-row => $row, -column => 4, -sticky => 'w');
    $f->Frame(-background => $black, -width => 0,
	     )->grid(-row => $row, -column => 5, -sticky => 'ns');
    $l2[$i] = $f->Label(-textvariable => \$var[$i]
		       )->grid(-row => $row, -column => 6, -sticky => 'w');
    $f->Frame(-background => $black, -height => 1
	     )->grid(-row => ++$row, -column => 0,
		     -columnspan => 7, -sticky => 'ew');
    my $index = $i;
    $i++; $row++;
    $index;
}

return 1 if caller();

require WidgetDemo;

$MW = new MainWindow;
$MW->geometry("+0+0");
$MW->Button(-text => 'Close',
	    -command => sub { $MW->destroy })->pack;
date('date');
MainLoop;
