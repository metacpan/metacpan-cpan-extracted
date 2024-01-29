# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 56-rich-term-utf8.t".
#
# Without "Build" file it could be called with "perl -I../lib
# 56-rich-term-utf8.t" or "perl -Ilib t/56-rich-term-utf8.t".  This is also
# the command needed to find out what specific tests failed in a "./Build
# test" as the later only gives you a number and not the description of the
# test.
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
    $_ = `tty`;
    chomp $_;
    -c $_  and  -w $_
	or  plan skip_all => 'required TTY (' . $_ . ') not available';
    plan tests => 1;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
    $ENV{LANG} = 'en_GB.UTF-8';
}

use UI::Various({use => ['RichTerm']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# prepare some building blocks for the tests:

my %D = %UI::Various::RichTerm::base::D; # simple short-cut

my @numbers = ();
push @numbers, UI::Various::Text->new(text => $_) foreach 1..16;

my $main = UI::Various::Main->new(width => 40);
my $win;
my $quit = UI::Various::Button->new(text => 'Quit',
				    code => sub { $win->destroy; });
my $prompt = 'enter selection: ';

#########################################################################
# unit tests:

####################################
# simple 4x4 box with borders:
my $box = UI::Various::Box->new(rows => 4, columns => 4, border => 1);
$box->add(@numbers);
$win = $main->window({title => 'Borders'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 "$D{W7}$D{W8} Borders $D{W8}$D{W8}$D{W8}$D{W8}<0>$D{W9}",
	 "$D{W4}    $D{B7}$D{B8}$D{B8}$D{b8}$D{B8}$D{B8}$D{b8}$D{B8}$D{B8}$D{b8}$D{B8}$D{B8}$D{B9}$D{W6}",
	 "$D{W4}    $D{B4}1 $D{B5}2 $D{B5}3 $D{B5}4 $D{B6}$D{W6}",
	 "$D{W4}    $D{b4}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b6}$D{W6}",
	 "$D{W4}    $D{B4}5 $D{B5}6 $D{B5}7 $D{B5}8 $D{B6}$D{W6}",
	 "$D{W4}    $D{b4}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b6}$D{W6}",
	 "$D{W4}    $D{B4}9 $D{B5}10$D{B5}11$D{B5}12$D{B6}$D{W6}",
	 "$D{W4}    $D{b4}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b5}$D{c5}$D{c5}$D{b6}$D{W6}",
	 "$D{W4}    $D{B4}13$D{B5}14$D{B5}15$D{B5}16$D{B6}$D{W6}",
	 "$D{W4}    $D{B1}$D{B2}$D{B2}$D{b2}$D{B2}$D{B2}$D{b2}$D{B2}$D{B2}$D{b2}$D{B2}$D{B2}$D{B3}$D{W6}",
	 "$D{W4}<1> $D{BL}Quit$D{BR}       $D{W6}",
	 $D{W1}. $D{W2} x 17 . $D{W3},
	 $prompt),
    'UTF-8 output looks correctly';
