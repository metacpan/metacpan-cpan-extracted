# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 57-rich-term-colour.t".
#
# Without "Build" file it could be called with "perl -I../lib
# 57-rich-term-colour.t" or "perl -Ilib t/57-rich-term-colour.t".  This is
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
    plan tests => 3;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
    delete $ENV{LANG};
}

use UI::Various({use => ['RichTerm']});

#########################################################################
# just three simple tests covering all branches and conditions:
my $text1 = UI::Various::Text->new(text => 'dark green on light grey',
				   bg => 'c0c0c0', fg => '004000');
my $text2 = UI::Various::Text->new(text => 'dark red on default',
				   fg => '400000');
my $text3 = UI::Various::Text->new(text => 'default on light red',
				   bg => 'ff8080');
my $win = UI::Various::Window->new(title => 'colours',
				   bg => 'yellow', fg => '000080');
$win->add($text1, $text2, $text3);

stdout_is
{   $win->_show();   }

    "\e[48;5;226m\e[38;5;19m#= colours ===========<0>#\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' . "\e[48;5;188m\e[38;5;22m" .
    "dark green on light grey\e[48;5;188m\e[38;5;22m\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' .
    "\e[38;5;52mdark red on default\e[38;5;52m\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '     '. "\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' .
    "\e[48;5;217mdefault on light red\e[48;5;217m\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '    '. "\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m#========================#\e[39;49m\n",

    'colours in simple window are translated correctly';

# same with invisible box around each text:
$win = UI::Various::Window->new(title => 'colours',
				bg => 'yellow', fg => '000080');
my $box1 = UI::Various::Box->new(bg => 'yellow', fg => '000080');
$box1->add($text1);
my $box2 = UI::Various::Box->new(bg => 'yellow');
$box2->add($text2);
my $box3 = UI::Various::Box->new(fg => '000080');
$box3->add($text3);
$win->add($box1, $box2, $box3);

stdout_is
{   $win->_show();   }

    "\e[48;5;226m\e[38;5;19m#= colours ===========<0>#\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' . "\e[48;5;188m\e[38;5;22m" .
    "dark green on light grey\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' .
    "\e[48;5;226m\e[38;5;52mdark red on default\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '     '. "\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' .
    "\e[38;5;19m\e[48;5;217mdefault on light red\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '    '. "\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m#========================#\e[39;49m\n",

    'colours in boxed window are translated correctly';

# same as first with a dialogue:
my $dia = UI::Various::Dialog->new(title => 'colours',
				   bg => 'yellow', fg => '000080');
$dia->add($text1, $text2, $text3);

stdout_is
{   $dia->_show();   }

    "\e[48;5;226m\e[38;5;19m#= colours ===========<0>#\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' . "\e[48;5;188m\e[38;5;22m" .
    "dark green on light grey\e[48;5;188m\e[38;5;22m\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' .
    "\e[38;5;52mdark red on default\e[38;5;52m\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '     '. "\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m" . '"' .
    "\e[48;5;217mdefault on light red\e[48;5;217m\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '    '. "\e[39;49m" .
    "\e[48;5;226m\e[38;5;19m" . '"'. "\e[39;49m\n" .

    "\e[48;5;226m\e[38;5;19m#========================#\e[39;49m\n",

    'colours in simple dialogue are translated correctly';
