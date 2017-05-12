use strict;
use Test::More;

use Tk;
use Tk::ContextHelp;
use Tk::LabFrame;

my $top = eval { new MainWindow };
if (!$top) {
    plan skip_all => 'MainWindow cannot be created';
}
plan tests => 2;

$top->geometry("+1+1"); # for twm

if (!defined $ENV{BATCH}) { $ENV{BATCH} = 1 }

$top->bind('<Escape>' => sub { warn "This is the original binding for Esc\n"});

$top->optionAdd("*LabFrame*padX", 3, "userDefault");

my $ch = $top->ContextHelp(-widget => 'Message',
			   -width => 400, -justify => 'right',
			   -podfile => $INC{"Tk/ContextHelp.pm"},
			   -helpkey => 'F1',
			  );
isa_ok $ch, 'Tk::ContextHelp';

{
    my $chf = $top->LabFrame(-label => "ContextHelp button",
			     -labelside => "acrosstop")->pack(-anchor => "w",
							      -fill => "x");

    {
	my $f = $chf->Frame->pack(-anchor => "w");
	$ch->HelpButton($f)->pack(-side => "left");
	$f->Label(-justify => "left",
		  -text => "Click <1> for single mode\nClick <3> for permanent mode")->pack(-side => "left");
    }

    my $cb = $chf->Checkbutton(-text => "Use Tk::Pod fallback",
			       -variable => \$Tk::ContextHelp::NO_TK_POD,
			       -onvalue => 1,
			       -offvalue => 0)->pack(-anchor => "w");
    $ch->attach($cb, -msg => "If activated, then the internal Tk::Pod fallback with a simple pod viewer is used");

    my $bn_text = 'Change to Tk::Pod Pod';
    my $bn = $chf->Button(-text => $bn_text)->pack(-anchor => "w");
    $bn->configure(-command => sub {
		       if ($bn->cget(-text) eq $bn_text) {
			   $bn->configure(-text => 'Change to Tk::ContextHelp Pod');
			   $ch->configure(-podfile => 'Tk::Pod');
		       } else {
			   $bn->configure(-text => $bn_text);
			   $ch->configure(-podfile => $INC{"Tk/ContextHelp.pm"});
		       }
		   }
		  );
    $ch->attach($bn, -msg => "Changes the active pod to Tk::Pod's or Tk::ContextHelp's Pod");
}

{
    my $widf = $top->LabFrame(-label => "Test widgets",
			      -labelside => "acrosstop")->pack(-anchor => "w",
							       -fill => "x");

    {
	my $f2 = $widf->Frame(-relief => 'raised',
			      -bd => 2)->grid(-row => 0, -column => 0,
					      -rowspan => 6);
	$f2->Label(-text => 'POD sections', -fg => 'red')->pack;
	my $pod1 = $f2->Label(-text => 'Name',
			      -bg => '#ffc0c0')->pack(-anchor => 'w');
	my $pod2 = $f2->Label(-text => 'Synopsis')->pack(-anchor => 'w');
	my $pod3 = $f2->Label(-text => 'Description')->pack(-anchor => 'w');
	my $pod30 = $f2->Label(-text => 'Methods')->pack(-anchor => 'w');
	my $pod31 = $f2->Label(-text => '  attach')->pack(-anchor => 'w');
	my $pod32 = $f2->Label(-text => '  detach')->pack(-anchor => 'w');
	my $pod33 = $f2->Label(-text => '  activate')->pack(-anchor => 'w');
	my $pod34 = $f2->Label(-text => '  deactivate')->pack(-anchor => 'w');
	my $pod35 = $f2->Label(-text => '  HelpButton')->pack(-anchor => 'w');
	my $pod4 = $f2->Label(-text => 'Author')->pack(-anchor => 'w');
	my $pod5 = $f2->Label(-text => 'See also')->pack(-anchor => 'w');

	$ch->attach($pod1, -pod => '^NAME');
	$ch->attach($pod2, -pod => '^SYNOPSIS');
	$ch->attach($pod3, -pod => '^DESCRIPTION');
	$ch->attach($pod30, -pod => '^METHODS');
	$ch->attach($pod31, -pod => '^\s*attach');
	$ch->attach($pod32, -pod => '^\s*detach');
	$ch->attach($pod33, -pod => '^\s*activate');
	$ch->attach($pod34, -pod => '^\s*deactivate');
	$ch->attach($pod35, -pod => '^\s*HelpButton');
	$ch->attach($pod4, -pod => '^AUTHOR');
	$ch->attach($pod5, -pod => '^SEE ALSO');
    }

    my $row = 0;

    {
	my $f = $widf->Frame(-relief => 'raised',
			     -bg => '#ffc0c0',
			     -bd => 2)->grid(-row => $row++, -column => 1,
					     -sticky => "ew");
	$ch->attach($f, -msg => 'Frame test');

	$f->Label(-text => 'Labels')->pack;

	$f->Label(-text => 'in')->pack;

	my $fl1 = $f->Label(-text => 'a')->pack;
	$ch->attach($fl1, -command => sub {
			my $t = $top->Toplevel;
			$t->Label(-text => 'user-defined command')->pack;
			$t->Popup(-popover => 'cursor');
		    });

	$f->Label(-text => 'frame')->pack;
    }

    {
	my $entrytest = "Entry test...";
	my $te = $widf->Entry(-textvariable => \$entrytest
			     )->grid(-row => $row++, -column => 1);
	$ch->attach($te, -msg => "Type something in");
    }

    {
	my $l1 = $widf->Label(-text => 'Hello'
			     )->grid(-row => $row++, -column => 1);
	$ch->attach($l1, -msg => 'This is the word "Hello"');

	my $l2 = $widf->Label(-text => 'World'
			     )->grid(-row => $row++, -column => 1);
	$ch->attach($l2, -msg => 'This is the word "World"');
    }

    {
	$widf->Button(-text => 'No context help here',
		      -command => sub { warn "Ouch!\n"},
		     )->grid(-row => $row++, -column => 1);
    }

    {
	if (eval { require Tk::FireButton }) {
	    my $l3 = $widf->FireButton(-text => 'a fire button'
				      )->grid(-row => $row++, -column => 1);
	    $ch->attach($l3, -msg => 'There seem to be problems with FireButtons
not checking for an empty my_save_relief.');
	}
    }
}

{
    my $f = $top->LabFrame(-label => "That's it!",
			   -labelside => "acrosstop"
			  )->pack(-anchor => "w", -fill => "x");

    my $qb = $f->Button(-text => 'OK',
			-command => sub { $top->destroy },
		       )->pack;
    $ch->attach($qb, -msg => "Click here if you are tired of this demo.");
}

######################################################################

my $top2;
if (0) {
    $top2 = new MainWindow;
    my $icon_frame = $top2->Frame(-relief => 'ridge',
				  -bd => 2)->pack(-fill => 'x', -expand => 1);
    my $main_frame = $top2->Frame->pack(-fill => 'both', -expand => 1);
    my $ch2 = $main_frame->ContextHelp(-podfile => 'Tk::ContextHelp');
    $icon_frame->Button(-text => 'click here',
			-command => [$ch2, 'activate'],
		       )->pack(-side => 'right');
    my $stay_active = 0;
    $icon_frame->Checkbutton
	(-text => 'stay active',
	 -variable => \$stay_active,
	 -command => sub { $ch2->configure(-stayactive => $stay_active) },
	)->pack(-side => 'right');

    my $l20 = $main_frame->Label(-text => 'This is a test label'
				)->pack(-expand => 1,
					-fill => 'both');
    my $l21 = $main_frame->Label(-text => 'And another test label'
				)->pack(-expand => 1,
					-fill => 'both');

    $ch2->attach($l20, -msg => 'blah blah blah');
    $ch2->attach($l21, -msg => 'bla blubber foo');

    my $f3 = $main_frame->Frame(-relief => 'raised',
				-bd => 2)->pack;
    $f3->Label(-text => 'POD sections', -fg => 'red')->pack;
    my $pod1 = $f3->Label(-text => 'Name')->pack(-anchor => 'w');
    my $pod2 = $f3->Label(-text => 'Synopsis')->pack(-anchor => 'w');
    my $pod3 = $f3->Label(-text => 'Description')->pack(-anchor => 'w');
    my $pod30 = $f3->Label(-text => 'Methods')->pack(-anchor => 'w');
    my $pod31 = $f3->Label(-text => '  attach')->pack(-anchor => 'w');
    my $pod32 = $f3->Label(-text => '  detach')->pack(-anchor => 'w');
    my $pod33 = $f3->Label(-text => '  activate')->pack(-anchor => 'w');
    my $pod34 = $f3->Label(-text => '  deactivate')->pack(-anchor => 'w');
    my $pod35 = $f3->Label(-text => '  HelpButton')->pack(-anchor => 'w');
    my $pod4 = $f3->Label(-text => 'Author')->pack(-anchor => 'w');
    my $pod5 = $f3->Label(-text => 'See also')->pack(-anchor => 'w');
    $ch2->attach($pod1, -pod => '^NAME');
    $ch2->attach($pod2, -pod => '^SYNOPSIS');
    $ch2->attach($pod3, -pod => '^DESCRIPTION');
    $ch2->attach($pod30, -pod => '^METHODS');
    $ch2->attach($pod31, -pod => '^\s*attach');
    $ch2->attach($pod32, -pod => '^\s*detach');
    $ch2->attach($pod33, -pod => '^\s*activate');
    $ch2->attach($pod34, -pod => '^\s*deactivate');
    $ch2->attach($pod35, -pod => '^\s*HelpButton');
    $ch2->attach($pod4, -pod => '^AUTHOR');
    $ch2->attach($pod5, -pod => '^SEE ALSO');
}

if ($ENV{BATCH}) {
    $top->after(500, sub {
		    $top->destroy if Tk::Exists($top);
		    $top2->destroy if Tk::Exists($top2);
		});
} else {
    diag 'Please play with the contexthelp window and close the mainwindow yourself.';
}

#$top->WidgetDump;
MainLoop;

pass 'no errors';
