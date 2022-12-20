# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 51-rich-term.t".
#
# Without "Build" file it could be called with "perl -I../lib 51-rich-term.t"
# or "perl -Ilib t/51-rich-term.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More;
use Test::Output;
my $tty;
BEGIN {
    # Use simple ReadLine without ornaments (aka ANSI escape sequences) for
    # unit tests to allow exact comparison.  (Note that direct testing and
    # ./Build test use Term::ReadLine::Stub from Term/ReadLine.pm while
    # testing with coverage, e.g. ./Build testcover, runs with
    # Term::ReadLine::Gnu):
    $ENV{PERL_RL} = 'Stub ornaments=0';
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
    plan tests => 54;

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
     qr/^UI::Various::RichTerm::Main may only be called from itself$re_msg_tail/,
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

my %D = %UI::Various::RichTerm::base::D; # simple short-cut

my $main = UI::Various::Main->new();
is(ref($main), 'UI::Various::RichTerm::Main',
   '$main is UI::Various::RichTerm::Main');

my $text1 = UI::Various::Text->new(text => 'Hello World!', height => 3);
is(ref($text1), 'UI::Various::RichTerm::Text', 'Text is concrete class');
my ($w, $h) = $text1->_prepare(10);
is($w, 6, '_prepare returns correct width');
is($h, 3, '_prepare returns correct height');
$_ = $text1->_show('=> ', $w, $h);
is($_,
   #___123456  ___123456  ___123456
   "=> Hello \n   World!\n         ",
   '_show (6,3) returns correct output');
$_ = $text1->_show('   ', 12, 2);
is($_,
   #___123456789012  ___123456789012
   "   Hello World!\n               ",
   '_show (12,2) returns correct output');

$_ = UI::Various::Text->new(text => '1234567 123'); # long / short
($w, $h) = $_->_prepare(10);
is($w, 7, '_prepare L/S returns correct width');
is($h, 2, '_prepare L/S returns correct height');
$_ = $_->_show('', $w, $h);
is($_, "1234567\n123    ",
   '_show (7,2) returns correct output');

my $button1 = UI::Various::Button->new(text => 'OK', height => 2,
				       code => sub { print "OK!\n"; });
is(ref($button1), 'UI::Various::RichTerm::Button', 'Button is concrete class');
($w, $h) = $button1->_prepare(10);
is($w, 4, '_prepare returns correct width');
is($h, 2, '_prepare returns correct height');
$_ = $button1->_show('<1> ', $w, $h);
is($_,
   #____1234  ____1234
   "<1> [OK]\n        ",
   '_show returns correct output');

my $var = 'initial value';
my $input = UI::Various::Input->new(textvar => \$var,);
is(ref($input), 'UI::Various::RichTerm::Input', 'Input is concrete class');
($w, $h) = $input->_prepare(10);
is($w, 7, '_prepare returns correct width');
is($h, 2, '_prepare returns correct height');
$_ = $input->_show('<1> ', $w, $h);
is($_,
   #____1234  ____1234
   "<1> $D{UL1}initial$D{UL0}\n    $D{UL1}value$D{UL0}  ",
   '_show returns correct output');
$main->add($input);
stdout_is
{   _call_with_stdin("something new\n", sub { $input->_process(); });   }
    'new value? ',
    '_process prints correct test';
is($var, 'something new', 'input variable has correct new value');
$main->remove($input);

$var = 0;
my $check = UI::Various::Check->new(text => 'on or off', var => \$var);
is(ref($check), 'UI::Various::RichTerm::Check', 'Check is concrete class');
($w, $h) = $check->_prepare(8);
is($w, 9, '_prepare (Check) returns correct width');
is($h, 2, '_prepare (Check) returns correct height');
$_ = $check->_show('<1> ', $w, $h);
is($_,
   #________12345  ________12345
   "<1> [ ] on or\n        off  ",
   '_show returns correct output');
$main->add($check);
$check->_process();
$_ = $check->_show('<1> ', $w, $h);
is($_,
   #________12345  ________12345
   "<1> [X] on or\n        off  ",
   '_process inverts variable correctly to 1');
$check->_process();
$_ = $check->_show('<1> ', $w, $h);
is($_,
   #________12345  ________12345
   "<1> [ ] on or\n        off  ",
   '_process inverts variable correctly back to 0');
$main->remove($check);

$var = 'c';
my $radio =
    UI::Various::Radio->new(buttons => [a => 'Roses are red',
					b => 'green',
					c => 'blue'],
			    var => \$var);
is(ref($radio), 'UI::Various::RichTerm::Radio', 'Radio is concrete class');
($w, $h) = $radio->_prepare(8);
is($w, 11, '_prepare (Radio 1) returns correct width');
is($h, 4, '_prepare (Radio 1) returns correct height');
$_ = $radio->_show('<1> ', $w, $h);
is($_,
   #________1234567  ________1234567  ________1234567  ________1234567
   "<1> ( ) Roses  \n        are red\n    ( ) green  \n    (o) blue   ",
   '_show (Radio 1) returns correct output');

$var = 'x';
$radio =
    UI::Various::Radio->new(buttons => [a => 'red', b => 'green', c => 'blue'],
			    var => \$var);
($w, $h) = $radio->_prepare(8);
is($w, 9, '_prepare (Radio 2) returns correct width');
is($h, 3, '_prepare (Radio 2) returns correct height');
$_ = $radio->_show('<1> ', $w, $h);
is($_,
   #________12345  ________12345  ________12345
   "<1> ( ) red  \n    ( ) green\n    ( ) blue ",
   '_show (Radio 2a) returns correct output');
$main->add($radio);
my $selection = "x\n9\n2\n";
my $prompt = "<1> red\n<2> green\n<3> blue\nenter selection (0 to cancel): ";
my $error = "invalid selection\n";
combined_is
{   _call_with_stdin($selection, sub { $radio->_process(); });   }
    $prompt . $error .
    $prompt . $error .
    $prompt,
    '_process of Radio produces correct output';
is($var, 'b', 'variable has correct value');
$_ = $radio->_show('<1> ', $w, $h);
is($_,
   #________12345  ________12345  ________12345
   "<1> ( ) red  \n    (o) green\n    ( ) blue ",
   '_show (Radio 2b) returns correct output');
$main->remove($radio);

$radio =
    UI::Various::Radio->new(buttons => [a => 'red', b => 'green', c => 'blue'],
			    var => \$var);
$main->add($radio);
combined_is
{   _call_with_stdin("0\n", sub { $radio->_process(); });   }
    $prompt,
    '_process of Radio produces correct output';
is($var, 'b', 'variable still has correct value');

$main->remove($radio);

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
	  '_show 1 prints correct text');
$win1->width(14);
stdout_is(sub {   $win1->_show();   },
	  #_____12345678_        _____12345678_        _____12345678_
	  '#= hello =<0>#'."\n".'"    Hello   "'."\n".'"    World!  "'."\n".
	  '"            "'."\n".'"<1> [OK]    "'."\n".'"            "'."\n".
	  '#============#'."\n",
	  '_show 2 prints correct text');
$win1->width(18);
stdout_is(sub {   $win1->_show();   },
	  #_____123456789012_        _____123456789012_
	  '#= hello =====<0>#'."\n".'"    Hello World!"'."\n".
	  '"                "'."\n".'"                "'."\n".
	  '"<1> [OK]        "'."\n".'"                "'."\n".
	  '#================#'."\n",
	  '_show 3 prints correct text');
$win1->width(11);
stdout_is(sub {   $win1->_show();   },
	  #_____12345_        _____12345_        _____12345_v- too long
	  '#= hello =#'."\n".'"    Hello"'."\n".'"    World!"'."\n".
	  '"         "'."\n".'"<1> [OK] "'."\n".'"         "'."\n".
	  '#=========#'."\n",
	  '_show 4 prints correct (longer) text');

####################################
# test standard behaviour - program:

$win1->width(12);
$win1->title('');
if ($^V lt 'v5.20')		# workaround for Perl bugs #7508 / #109726
{
    $text1->{height} = undef;
    $button1->{height} = undef;
}
else
{
    $text1->height(undef);
    $button1->height(undef);

}
my $output1 =
    #_____123456_        _____123456_        _____123456_
    '#=======<0>#'."\n".'"    Hello "'."\n".'"    World!"'."\n".
    '"<1> [OK]  "'."\n".'#==========#'."\n";
stdout_is(sub {   $win1->_show();   }, $output1,
	  '_show 5 prints correct text');

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
	  '_show 6 prints correct text');

$main->add($win1);
$prompt = 'enter selection: ';

combined_is			# 2nd window is displayed 1st!
{   _call_with_stdin("-\n1\nx\n2\n+\n0\n-\n1\n", sub { $main->mainloop; });   }
    $output2 . $prompt .
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
    '_show 7 prints correct text';
$win1->title('');
stdout_is
{   $win1->_show();   }
    "#====#\n\"HI! \"\n\"BYE!\"\n" . ("\"    \"\n" x 6) . "#====#\n",
    '_show 8 prints correct text';

$_ = $win1->dump;
like($_,
     qr{^_space:\n
	\ \ 3:3\n
	\ \ 1:1\n
	\ \ 4:4\n
	\ \ 1:1\n
	_total_height:4\n
	children:\n
	\ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ text:HI!\n
	\ \ \ \ width:3\n
	\ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ text:BYE!\n
	height:12\n
	title:\n\Z}msx,
     'dump of window looks correct');

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
    '_show 9 prints correct text';

$main->remove($win1);

####################################
# test unused behaviour (and get 100% coverage):
$win1 = UI::Various::Window->new(title => 'dummy');
$win1->destroy;
stdout_is(sub {   $main->mainloop();   }, '',
	  'destroyed window is not shown');
