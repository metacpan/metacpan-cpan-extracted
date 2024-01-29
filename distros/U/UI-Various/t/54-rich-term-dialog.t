# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 54-rich-term-dialog.t".
#
# Without "Build" file it could be called with "perl -I../lib
# 54-rich-term-dialog.t" or "perl -Ilib t/54-rich-term-dialog.t".  This is
# also the command needed to find out what specific tests failed in a
# "./Build test" as the later only gives you a number and not the
# description of the test.
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
    plan tests => 8;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
    delete $ENV{LANG};
}

use UI::Various({use => ['RichTerm']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# prepare some building blocks for the tests:
my $main = UI::Various::Main->new();
my $text1 = UI::Various::Text->new(text => 'Hello World!', height => 3);
my $button1 = UI::Various::Button->new(text => 'OK', height => 2,
				       code => sub { print "OK!\n"; });

####################################
# test standard behaviour - dialogue:

my $dialog1 = UI::Various::Dialog->new(title => 'hello', width => 12);
$dialog1->add($text1);
$dialog1->add($button1);
stdout_is(sub {   $dialog1->_show();   },
	  #_____123456_        _____123456_        _____123456_
	  '#= hello ==#'."\n".'"    Hello "'."\n".'"    World!"'."\n".
	  '"          "'."\n".'"<1> [OK]  "'."\n".'"          "'."\n".
	  '#==========#'."\n",
	  '_show 1 prints correct text');
$dialog1->width(14);
stdout_is(sub {   $dialog1->_show();   },
	  #_____12345678_        _____12345678_        _____12345678_
	  '#= hello =<0>#'."\n".'"    Hello   "'."\n".'"    World!  "'."\n".
	  '"            "'."\n".'"<1> [OK]    "'."\n".'"            "'."\n".
	  '#============#'."\n",
	  '_show 2 prints correct text');
$dialog1->width(18);
stdout_is(sub {   $dialog1->_show();   },
	  #_____123456789012_        _____123456789012_
	  '#= hello =====<0>#'."\n".'"    Hello World!"'."\n".
	  '"                "'."\n".'"                "'."\n".
	  '"<1> [OK]        "'."\n".'"                "'."\n".
	  '#================#'."\n",
	  '_show 3 prints correct text');
$dialog1->width(11);
stdout_is(sub {   $dialog1->_show();   },
	  #_____12345_        _____12345_        _____12345_v- too long
	  '#= hello =#'."\n".'"    Hello"'."\n".'"    World!"'."\n".
	  '"         "'."\n".'"<1> [OK] "'."\n".'"         "'."\n".
	  '#=========#'."\n",
	  '_show 4 prints correct (longer) text');
$main->remove($dialog1);
is(@{$main->{children}}, 0, 'main is clean');

####################################
# test standard behaviour - program with window:

my $dialog2;
$text1 = UI::Various::Text->new(text => 'Hello Dialogue!');
$button1 = UI::Various::Button->new(text => 'OK',
				       code => sub { print "OK!\n"; });
my $button2 = UI::Various::Button->new(text => 'Close',
				       code => sub { $dialog2->destroy; });

my $text2 = UI::Various::Text->new(text => 'Hello Window!');
my $button3 =
    UI::Various::Button->new(text => 'Dialogue',
			     code => sub {
				 $dialog2 =
				     $main->dialog({title => 'D in W',
						    height => 2},
						   $text1, $button1, $button2);
			     });
my $window;
my $button4 =
    UI::Various::Button->new(text => 'Quit',
			     code => sub { $window->destroy(); });
$window = $main->window({title => 'W'}, $text2, $button3, $button4);

my $standard_output_d = join("\n",
			     '#= D in W =======<0>#',
			     '"    Hello Dialogue!"',
			     '"<1> [OK]           "',
			     '"<2> [Close]        "',
			     '#===================#',
			     '');
my $standard_output_w = join("\n",
			     '#= W ==========<0>#',
			     '"    Hello Window!"',
			     '"<1> [Dialogue]   "',
			     '"<2> [Quit]       "',
			     '#=================#',
			     '');
my $prompt = 'enter selection: ';
combined_is
{
    _call_with_stdin("0\n1\n0\n1\n1\n-\n9\n2\n2\n",
		     sub { $main->mainloop; });
}
    $standard_output_w . $prompt .
    $standard_output_w . $prompt .
    $standard_output_d . $prompt .
    $standard_output_w . $prompt .
    $standard_output_d . $prompt . "OK!\n" .
    $standard_output_d . $prompt .
    "invalid selection\n" . $prompt .
    "invalid selection\n" . $prompt .
    $standard_output_w . $prompt,
    'window plus dialogue runs correctly';
is(@{$main->{children}}, 0, 'main is clean again');

####################################
# test standard behaviour - stand-alone program:

$text1 = UI::Various::Text->new(text => 'Hello! ');
$main->{max_height} = 4;
$main->dialog({height => 5}, $text1);
stdout_is
{   _call_with_stdin("0\n", sub { $main->mainloop; });   }
    #           _1234567_    _1234567_    _1234567_    _1234567_
    join("\n", '#====<0>#', '"Hello! "', '"       "', '#=======#', $prompt),
    'stand-alone dialogue runs correctly';
