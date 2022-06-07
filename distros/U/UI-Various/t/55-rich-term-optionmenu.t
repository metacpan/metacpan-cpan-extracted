# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 55-rich-term-optionmenu.t".
#
# Without "Build" file it could be called with "perl -I../lib 55-rich-term-optionmenu.t"
# or "perl -Ilib t/55-rich-term-optionmenu.t".  This is also the command needed to find
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
    plan tests => 3;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['RichTerm']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# prepare test window and some building blocks:

my %D = %UI::Various::RichTerm::base::D; # simple short-cut

my @options = ([a => 1], [b => 2], [c => 3], 42);

my $main = UI::Various::Main->new(width => 40);

my $win;
my $quit = UI::Various::Button->new(text => 'Quit',
				    code => sub { $win->destroy; });
my $om = UI::Various::Optionmenu->new(options => \@options);
$win = $main->window({title => 'OM'}, $om, $quit);

my $prompt = 'enter selection: ';
my $selection_prompt =
    "<1> a\n<2> b\n<3> c\n<4> 42\nenter selection (0 to cancel): ";

####################################
# test standard behaviour:
stdout_is
{   _call_with_stdin("1\n2\n2\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= OM ==<0>#',
	 '"<1> [---] "',
	 '"<2> [Quit]"',
	 '#==========#',
	 $prompt . $selection_prompt . '#= OM ==<0>#',
	 '"<1> [b]   "',
	 '"<2> [Quit]"',
	 '#==========#',
	 $prompt),
    'mainloop 1 runs correctly';

####################################
# test with callback:
my $value = -1;
$om = UI::Various::Optionmenu->new(options => \@options,
				   init => 3,
				   on_select => sub { $value = $_[0]; });
$win = $main->window({title => 'OM'}, $om, $quit);
stdout_is
{   _call_with_stdin("1\n4\n1\n0\n2\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= OM ==<0>#',
	 '"<1> [c]   "',
	 '"<2> [Quit]"',
	 '#==========#',
	 $prompt . $selection_prompt . '#= OM ==<0>#',
	 '"<1> [42]  "',
	 '"<2> [Quit]"',
	 '#==========#',
	 $prompt . $selection_prompt . '#= OM ==<0>#',
	 '"<1> [42]  "',
	 '"<2> [Quit]"',
	 '#==========#',
	 $prompt),
    'mainloop 2 runs correctly';
is($value, 42, 'on_select 2 has been called correctly');
