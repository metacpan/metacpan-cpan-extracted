# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 41-rich-term.t".
#
# Without "Build" file it could be called with "perl -I../lib 41-rich-term.t"
# or "perl -Ilib t/41-rich-term.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More;
use Test::Output;
my $tty;
BEGIN {
    # Use simple ReadLine without ornaments (aka ANSI escape sequences) for
    # unit tests to allow exact comparison:
    $ENV{PERL_RL} = 'Stub o=0';
    unless (defined $DB::{single})
    {
	# This check confuses the Perl debugger, so we wont run it while
	# debugging:
	eval { require Term::ReadLine::Gnu; };
	$@ =~ m/^It is invalid to load Term::ReadLine::Gnu directly/
	    or  plan skip_all => 'Term::ReadLine::Gnu not found';
    }
    $tty = `tty`;
    chomp $tty;
    -c $tty  and  -w $tty
	or  plan skip_all => 'required TTY (' . $tty . ') not available';
    plan tests => 29;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['RichTerm']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/run_in_fork.pl');
do(T_PATH . '/functions/call_with_stdin.pl');
do(T_PATH . '/functions/sub_perl.pl');

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

####################################
# bad behaviour:

eval {   UI::Various::RichTerm::Main::_init(1);   };
like($@,
     qr/^.*RichTerm::Main may only be called from UI::Various::Main$re_msg_tail/,
     'forbidden call to UI::Various::RichTerm::Main::_init should fail');

####################################
# special initialisation tests:

_run_in_fork
    ('default initialisation without stty',
     3,
     sub{
	 $ENV{PATH} = '';
	 my $main = UI::Various::Main->new();
	 _ok($main, 'UI::Various::Main->new() returned singleton');
	 _ok(24 == $main->height(),
	     'maximum application height set to 24');
	 _ok(80 == $main->width(),
	     'maximum application width set to 80');
     });
$_ = _sub_perl('BEGIN { $ENV{PERL_RL} = "Gnu"; }
		use Term::ReadLine;
		open IN, "' . $tty . '"  or  die "IN: $!";
		open OUT, "' . $tty . '"  or  die "OUT: $!";
		my $term = Term::ReadLine->new("T41", *IN, *OUT);
		use UI::Various({use => ["RichTerm"]});
		use UI::Various::Main;
		my $main = UI::Various::Main->new();
		print(	$main->{_rl}->ReadLine, ": ",
			$main->width, "x", $main->height, "\n");
');
chomp;
ok(m/^Term::ReadLine::Gnu: \d{2,}x\d{2,}/,
   'Term::ReadLine::Gnu returned size: "' . $_ . '"');

####################################
# test standard behaviour - elements:

my $main = UI::Various::Main->new();
is(ref($main), 'UI::Various::RichTerm::Main',
   '$main is UI::Various::RichTerm::Main');

my $text1 = UI::Various::Text->new(text => 'Hello World!', height => 3);
is(ref($text1), 'UI::Various::RichTerm::Text',
   'type UI::Various::RichTerm::Text is correct');
my ($w, $h) = $text1->_prepare(10);
is($w, 6, 'UI::Various::RichTerm::Text::_prepare returns correct width');
is($h, 3, 'UI::Various::RichTerm::Text::_prepare returns correct height');
$_ = $text1->_show('=> ', $w, $h);
is($_,
   #___123456  ___123456  ___123456
   "=> Hello \n   World!\n         ",
   'UI::Various::RichTerm::Text::_show (6,3) returns correct output');
$_ = $text1->_show('   ', 12, 2);
is($_,
   #___123456789012  ___123456789012
   "   Hello World!\n               ",
   'UI::Various::RichTerm::Text::_show (12,2) returns correct output');

$_ = UI::Various::Text->new(text => '1234567 123'); # long / short
($w, $h) = $_->_prepare(10);
is($w, 7, 'UI::Various::RichTerm::Text::_prepare L/S returns correct width');
is($h, 2, 'UI::Various::RichTerm::Text::_prepare L/S returns correct height');
$_ = $_->_show('', $w, $h);
is($_, "1234567\n123    ",
   'UI::Various::RichTerm::Text::_show (7,2) returns correct output');

my $button1 = UI::Various::Button->new(text => 'OK', height => 2,
				      code => sub { print "OK!\n"; });
is(ref($button1), 'UI::Various::RichTerm::Button',
   'type UI::Various::RichTerm::Button is correct');
($w, $h) = $button1->_prepare(10);
is($w, 4, 'UI::Various::RichTerm::Button::_prepare returns correct width');
is($h, 2, 'UI::Various::RichTerm::Button::_prepare returns correct height');
$_ = $button1->_show('<1> ', $w, $h);
is($_,
   #____1234  ____1234
   "<1> [OK]\n        ",
   'UI::Various::RichTerm::Button::_show returns correct output');

####################################
# test standard behaviour - window:

my $win1 = UI::Various::Window->new(title => 'hello', width => 12);
$win1->add($text1);
$win1->add($button1);
stdout_is(sub {   $win1->_show();   },
	  #_____123456_        _____123456_        _____123456_
	  '#= hello ==#'."\n".'"    Hello "'."\n".'"    World!"'."\n".
	  '"          "'."\n".'"<1> [OK]  "'."\n".'"          "'."\n".
	  '#==========#'."\n",
	  'UI::Various::RichTerm::Window::_show 1 prints correct text');
$win1->width(14);
stdout_is(sub {   $win1->_show();   },
	  #_____12345678_        _____12345678_        _____12345678_
	  '#= hello =<0>#'."\n".'"    Hello   "'."\n".'"    World!  "'."\n".
	  '"            "'."\n".'"<1> [OK]    "'."\n".'"            "'."\n".
	  '#============#'."\n",
	  'UI::Various::RichTerm::Window::_show 2 prints correct text');
$win1->width(18);
stdout_is(sub {   $win1->_show();   },
	  #_____123456789012_        _____123456789012_
	  '#= hello =====<0>#'."\n".'"    Hello World!"'."\n".
	  '"                "'."\n".'"                "'."\n".
	  '"<1> [OK]        "'."\n".'"                "'."\n".
	  '#================#'."\n",
	  'UI::Various::RichTerm::Window::_show 3 prints correct text');
$win1->width(11);
stdout_is(sub {   $win1->_show();   },
	  #_____12345_        _____12345_        _____12345_v- too long
	  '#= hello =#'."\n".'"    Hello"'."\n".'"    World!"'."\n".
	  '"         "'."\n".'"<1> [OK] "'."\n".'"         "'."\n".
	  '#=========#'."\n",
	  'UI::Various::RichTerm::Window::_show 4 prints correct (longer) text');

####################################
# test standard behaviour - program:

$win1->width(12);
$win1->title('');
$text1->height(undef);
$button1->height(undef);
my $output1 =
    #_____123456_        _____123456_        _____123456_
    '#=======<0>#'."\n".'"    Hello "'."\n".'"    World!"'."\n".
    '"<1> [OK]  "'."\n".'#==========#'."\n";
stdout_is(sub {   $win1->_show();   }, $output1,
	  'UI::Various::RichTerm::Window::_show 5 prints correct text');

my $output2 =
    #_____123456_        _____123456_        _____123456_
    '#= goodbye #'."\n".'"    HI!   "'."\n".'"<1> [Quit]"'."\n".
    '#==========#'."\n";
my $win2;
my $text2 = UI::Various::Text->new(text => 'HI!', width => 3);
my $button2 = UI::Various::Button->new(text => 'Quit', width => 4, height => 1,
				       code => sub {
					   $win1->destroy;
					   $win2->destroy;
				       });
$win2 = $main->window({title => 'goodbye', width => 12},
		      $text2, $button2);
stdout_is(sub {   $win2->_show();   }, $output2,
	  'UI::Various::RichTerm::Window::_show 6 prints correct text');

# Remove ReadLine's escape sequences to allow exact comparison.  (Note that
# direct testing and ./Build test use Term::ReadLine::Stub from
# Term/ReadLine.pm while testing with coverage, e.g. ./Build testcover, runs
# with Term::ReadLine::Gnu):

$main->add($win1);
my $prompt = "enter selection: ";
my $error = "invalid selection\n";

combined_is
{   _call_with_stdin("1\nx\n2\n+\n0\n-\n1\n", sub { $main->mainloop; });   }
    $output1 . $prompt . "OK!\n" .
    $output1 . $prompt . $error . $prompt . $error . $prompt .
    $output2 . $prompt .
    $output1 . $prompt .
    $output2 . $prompt,
    'mainloop 1 runs correctly';

$button1->code(sub{$win2 = $main->window({title => 'goodbye', width => 12},
					 $text2, $button2);
	       });
$win1 = $main->window({width => 12}, $text1, $button1);

combined_is
{   _call_with_stdin('', sub { eval { $main->mainloop; }; });   }
    $output1 . $prompt,
    'mainloop 2 runs correctly';

combined_is
{   _call_with_stdin("1\n1\n", sub { $main->mainloop; });   }
    $output1 . $prompt . $output2 . $prompt,
    'mainloop 3 runs correctly';

####################################
# other standard behaviour - various to increase coverage:

$main->{max_height} = 10;
$win1 = UI::Various::Window->new(title => 'hello', height => 12);
$win1->add($text2);
my $text3 = UI::Various::Text->new(text => 'BYE!');
$win1->add($text3);
stdout_is
{   $win1->_show();   }
    "#= hello #\n\"HI!     \"\n\"BYE!    \"\n" . ("\"        \"\n" x 6) .
    "#========#\n",
    'UI::Various::RichTerm::Window::_show 7 prints correct text';
$win1->title('');
stdout_is
{   $win1->_show();   }
    "#====#\n\"HI! \"\n\"BYE!\"\n" . ("\"    \"\n" x 6) . "#====#\n",
    'UI::Various::RichTerm::Window::_show 8 prints correct text';

$main->remove($win1);

$win1 = UI::Various::Window->new();
my @buttons =
    map { $_ = UI::Various::Button->new(text => 'OK'); }
    (1..10);
$win1->add(@buttons);

stdout_is
{   $win1->_show();   }
    "#======<0>#\n" .
    "\"< 1> [OK]\"\n" . "\"< 2> [OK]\"\n" . "\"< 3> [OK]\"\n" .
    "\"< 4> [OK]\"\n" . "\"< 5> [OK]\"\n" . "\"< 6> [OK]\"\n" .
    "\"< 7> [OK]\"\n" . "\"< 8> [OK]\"\n" . "\"< 9> [OK]\"\n" .
    "\"<10> [OK]\"\n" . "#=========#\n",
    'UI::Various::RichTerm::Window::_show 9 prints correct text';

$main->remove($win1);

####################################
# test unused behaviour (and get 100% coverage):
$win1 = UI::Various::Window->new(title => 'dummy');
$win1->destroy;
stdout_is(sub {   $main->mainloop();   }, '',
	  'destroyed window is not shown');
