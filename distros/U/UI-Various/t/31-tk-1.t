# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 31-tk-1.t".
#
# Without "Build" file it could be called with "perl -I../lib 31-tk-1.t"
# or "perl -Ilib t/31-tk-1.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

# Note that the original sole test script had to be split up into one part
# per running UI::Various::Tk::mainloop due to sporadic (11%) segmentation
# violations in Tk's internal code.
# An additional forced initialisation did not help as it blocked the
# mainloop.

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More;
use Test::Output;

BEGIN {
    $ENV{DISPLAY}  or  plan skip_all => 'DISPLAY not found';
    eval { require Tk; };
    $@  and  plan skip_all => 'Perl/Tk not found';
    plan tests => 35;

    # define fixed environment for unit tests:
    delete $ENV{UI};
}

use UI::Various({use => ['Tk']});
diag('UI::Various::Tk has been initialised');	# TODO: temporary diagnostics

#########################################################################
# specific check for problematic configuration, is sub-test as the
# additional check otherwise might affect further tests in some Perl and/or
# Tk versions:
use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/sub_perl.pl');
$_ = _sub_perl('require Tk;
		$_ = MainWindow->new();
		$_->fontActual("", "-size");
		$_->destroy;');
if ($_)
{
    diag('Your ', $^O,
	 ' apparently has a strange font configuration (no default font?).',
	 '  This will hurt!');
}
# TODO: temporary check for specific CPAN smoker:
if ($ENV{DISPLAY} =~ m/:121$/)
{
    diag 'extended check for DISPLAY == ', $ENV{DISPLAY};
    diag 'TK has version ', $Tk::VERSION;
    my ($countdown, $pid) = (10, 0);
    while (--$countdown > 0)
    {
	sleep 7  if $countdown < 10;
	open my $ps, '-|', 'ps', 'auxww'  or  die "can't PS: $!\n";
	my $found = 0;
	while (<$ps>)
	{
	    next unless m/[X][a-z].* :121\b/;
	    m/^[^ ]+\s+(\d+).*/  and  $pid = $1;
	    $found++;
	}
	close $ps;
	last if $found > 0;
	diag 'X server not yet running - ', $countdown;
    }
    if ($countdown > 0)
    {   diag 'X server seems to be running with PID ', $pid;   }
    else
    {   diag 'no X server - we will fail';   }
}

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

my $main = UI::Various::Main->new();
is(ref($main), 'UI::Various::Tk::Main', '$main is UI::Various::Tk::Main');

####################################
# bad behaviour:

eval {   UI::Various::Tk::Main::_init(1);   };
like($@,
     qr/^UI::Various::Tk::Main may only be called from itself$re_msg_tail/,
     'forbidden call to UI::Various::Tk::Main::_init should fail');

####################################
# test standard behaviour:

my $text1 = UI::Various::Text->new(text => 'Hello World!');
is(ref($text1), 'UI::Various::Tk::Text',
   'type UI::Various::Tk::Text is correct');
my $button1 = UI::Various::Button->new(text => 'OK',
				       code => sub { print "OK!\n"; });
is(ref($button1), 'UI::Various::Tk::Button',
   'type UI::Various::Tk::Button is correct');
my $ivar = 'thing';
my $input = UI::Various::Input->new(textvar => \$ivar);
is(ref($input), 'UI::Various::Tk::Input',
   'type UI::Various::Tk::Input is correct');
my $cvar = 0;
my $check = UI::Various::Check->new(text => 'on/off', var => \$cvar);
is(ref($check), 'UI::Various::Tk::Check',
   'type UI::Various::Tk::Check is correct');
my $text2 = UI::Various::Text->new(text => \$ivar);
is(ref($text2), 'UI::Various::Tk::Text',
   'type UI::Various::Tk::Text is correct again');
my $rvar = 'r';
my $radio =
    UI::Various::Radio->new(buttons => [r => 'red', g => 'green', b => 'blue'],
			    var => \$rvar);
is(ref($radio), 'UI::Various::Tk::Radio',
   'type UI::Various::Tk::Radio is correct');
my $box1 = UI::Various::Box->new(border => 1, columns => 2, rows => 3);
is(ref($box1), 'UI::Various::Tk::Box',
   'type UI::Various::Tk::Box is correct');
my @text8 = ('1st entry', '2nd entry', '3rd entry', '4th entry',
	     '5th entry', '6th entry', '7th entry', '8th entry');
my $listbox = UI::Various::Listbox->new(texts => \@text8, height => 3,
					selection => 1);
my @options = ([a => 1], [b => 2], [c => 3], 42);
my $optionmenu = UI::Various::Optionmenu->new(init => 1,
					      options => \@options);
my $option = 0;
my $optionmenu2 = UI::Various::Optionmenu->new(init => 2,
					       options => \@options,
					       on_select => sub {
						   $option = $_[0];
					       });

stderr_like
{   $text1->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Text element must be accompanied by parent$re_msg_tail/,
    'orphaned Text causes error';
stderr_like
{   $button1->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Button element must be accompanied by parent$re_msg_tail/,
    'orphaned Button causes error';
stderr_like
{   $input->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Input element must be accompanied by parent$re_msg_tail/,
    'orphaned Input causes error';
stderr_like
{   $check->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Check element must be accompanied by parent$re_msg_tail/,
    'orphaned Check causes error';
stderr_like
{   $radio->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Radio element must be accompanied by parent$re_msg_tail/,
    'orphaned Radio causes error';
stderr_like
{   $box1->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Box element must be accompanied by parent$re_msg_tail/,
    'orphaned Box causes error';
stderr_like
{   $listbox->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Listbox element must be accompanied by parent$re_msg_tail/,
    'orphaned Listbox causes error';
stderr_like
{   $optionmenu->_prepare(0, 0);   }
    qr/^UI.*::Tk::Optionmenu element must be accompanied by parent$re_msg_tail/,
    'orphaned Optionmenu causes error';

$box1->add(0, 1, $input, $check, $text2, $radio);

my $button2 = UI::Various::Button->new(text => 'Quit');
my $box2 = UI::Various::Box->new(columns => 2);
$box2->add($button1, $button2);
my $w = $main->window({title => 'Hello', height => 16, width => 42},
		      $text1, $box1, $listbox, $optionmenu, $optionmenu2, $box2);
is(ref($w), 'UI::Various::Tk::Window',
   'type UI::Various::Tk::Window is correct');
$button2->code(sub { $w->destroy(); });

my @internal_types = ();
my $selection1 = 'not undef';
my $selection2 = 'wrong';
combined_like
{
    $main->_mainloop_prepare;
    push @internal_types,
	$text1->_tk(), $button1->_tk(), $input->_tk(), $check->_tk(),
	@{$radio->_tk()}[0], @{$box1->_tk()}[0], $listbox->_tk();
    $button1->_tk()->invoke;
    $input->_tk()->insert(0, 'some');
    $check->_tk()->invoke;
    $radio->_tk()->[2]->invoke;
    $selection1 = $listbox->selected();
    $listbox->_tk()->selectionSet(2);
    $listbox->_tk()->selectionSet(1);
    $selection2 = $listbox->selected();
    # some pseudo invocations:
    &{$optionmenu ->_tk()->cget('-command')->[0]}(1);
    &{$optionmenu2->_tk()->cget('-command')->[0]}(2);
    # ... and quit:
    $button2->_tk()->invoke;
    $main->_mainloop_run;
}
    qr{\A(?:^Devel::Cover: .*lib/Tk/Frame.pm .*\n)*^OK!\Z}m,
    'mainloop produces correct output';
is(@{$main->{children}}, 0, 'main no longer has children');
is(ref($internal_types[0]), 'Tk::Label', 'Text had correct internal type');
is(ref($internal_types[1]), 'Tk::Button', 'Button had correct internal type');
is(ref($internal_types[2]), 'Tk::Entry', 'Input had correct internal type');
is(ref($internal_types[3]), 'Tk::Checkbutton',
   'Check had correct internal type');
is(ref($internal_types[4]), 'Tk::Radiobutton',
   'Radio had correct internal type');
is(ref($internal_types[5]), 'Tk::Frame', 'Box had correct internal type');
is(ref($internal_types[6]), 'Tk::Frame', 'Listbox had correct internal type');
is($ivar, 'something', 'input variable has correct new value');
is($cvar, 1, 'checkbox variable has correct new value of 1');
is($rvar, 'b', 'radio button variable has correct new value of "b"(lue)');
is($selection1, undef, 'listbox has correct initial selection');
is($selection2, 1, 'listbox has correct (invalid) final selection');
is($optionmenu->selected(), 1, 'optionmenu 1 has correct selection');
is($optionmenu2->selected(), 2, 'optionmenu 2 has correct selection');
is($option, 2, 'option has been modified in menu 2');
