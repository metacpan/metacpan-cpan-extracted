# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 53-rich-term-listbox.t".
#
# Without "Build" file it could be called with "perl -I../lib
# 53-rich-term-listbox.t" or "perl -Ilib t/53-rich-term-listbox.t".  This is
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
    plan tests => 17;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['RichTerm']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# prepare some building blocks for the tests:

my %D = %UI::Various::RichTerm::base::D; # simple short-cut

my @text8 = ('1st entry', '2nd entry', '3rd entry', '4th entry',
	     '5th entry', '6th entry', '7th entry', '8th entry');

my $main = UI::Various::Main->new(width => 40);

my $win;
my $quit = UI::Various::Button->new(text => 'Quit',
				    code => sub { $win->destroy; });

my $prompt = 'enter selection: ';

#########################################################################
# unit tests:

####################################
# empty list:
my $lb0 = UI::Various::Listbox->new(texts => [], height => 5);
$win = $main->window({title => '0-5-2'}, $lb0, $quit);
stdout_is
{   _call_with_stdin("1\n2\n7\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 0-5-2 ==#',
	 '"    0/0   "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"<7> [Quit]"',
	 '#==========#',
	 $prompt . '#= 0-5-2 ==#',
	 '"    0/0   "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"<7> [Quit]"',
	 '#==========#',
	 $prompt . '#= 0-5-2 ==#',
	 '"    0/0   "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"<7> [Quit]"',
	 '#==========#',
	 $prompt),
    'empty 0-5-2 mainloop runs correctly';
my @result = $lb0->selected;
is_deeply(\@result, [],
   'selected after processing empty listbox 0-5-2 returns correct selection');

####################################
# list without selection:
my $lb8 = UI::Various::Listbox->new(texts => \@text8, height => 5,
				    selection => 0);
$win = $main->window({title => '8-5-0'}, $lb8, $quit);
stdout_is
{   _call_with_stdin("1\n1\n2\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 8-5-0 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"    1st entry"',
	 '"    2nd entry"',
	 '"    3rd entry"',
	 '"    4th entry"',
	 '"    5th entry"',
	 '"<2> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-0 ==<0>#',
	 '"<1>+4-8/8    "',
	 '"    4th entry"',
	 '"    5th entry"',
	 '"    6th entry"',
	 '"    7th entry"',
	 '"    8th entry"',
	 '"<2> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-0 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"    1st entry"',
	 '"    2nd entry"',
	 '"    3rd entry"',
	 '"    4th entry"',
	 '"    5th entry"',
	 '"<2> [Quit]   "',
	 '#=============#',
	 $prompt),
    'simple 8-5-0 mainloop runs correctly';

####################################
# list with single selection:
my $counter = 0;
$lb8 = UI::Various::Listbox->new(texts => \@text8, height => 5, selection => 1,
				 on_select => sub { $counter++; });
$win = $main->window({title => '8-5-1'}, $lb8, $quit);
stdout_is
{   _call_with_stdin("1\n2\n1\n3\n7\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 8-5-1 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"<2> 1st entry"',
	 '"<3> 2nd entry"',
	 '"<4> 3rd entry"',
	 '"<5> 4th entry"',
	 '"<6> 5th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-1 ==<0>#',
	 '"<1>+4-8/8    "',
	 '"<2> 4th entry"',
	 '"<3> 5th entry"',
	 '"<4> 6th entry"',
	 '"<5> 7th entry"',
	 '"<6> 8th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-1 ==<0>#',
	 '"<1>+4-8/8    "',
	 '"<2> '.$D{SL1}.'4th entry'.$D{SL0}.'"',
	 '"<3> 5th entry"',
	 '"<4> 6th entry"',
	 '"<5> 7th entry"',
	 '"<6> 8th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-1 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"<2> 1st entry"',
	 '"<3> 2nd entry"',
	 '"<4> 3rd entry"',
	 '"<5> '.$D{SL1}.'4th entry'.$D{SL0}.'"',
	 '"<6> 5th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-1 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"<2> 1st entry"',
	 '"<3> '.$D{SL1}.'2nd entry'.$D{SL0}.'"',
	 '"<4> 3rd entry"',
	 '"<5> 4th entry"',
	 '"<6> 5th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt),
    'simple 8-5-1 mainloop runs correctly';
$_ = $lb8->selected;
is($_, 1, 'selected after processing listbox 8-5-1 returns correct selection');
is($counter, 2, 'counter has correct 1st value');

####################################
# list with multiple selection:
$lb8 = UI::Various::Listbox->new(texts => \@text8, height => 5, selection => 2,
				 on_select => sub { $counter++; });
$win = $main->window({title => '8-5-2'}, $lb8, $quit);
stdout_is
{   _call_with_stdin("1\n2\n1\n3\n7\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 8-5-2 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"<2> 1st entry"',
	 '"<3> 2nd entry"',
	 '"<4> 3rd entry"',
	 '"<5> 4th entry"',
	 '"<6> 5th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-2 ==<0>#',
	 '"<1>+4-8/8    "',
	 '"<2> 4th entry"',
	 '"<3> 5th entry"',
	 '"<4> 6th entry"',
	 '"<5> 7th entry"',
	 '"<6> 8th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-2 ==<0>#',
	 '"<1>+4-8/8    "',
	 '"<2> '.$D{SL1}.'4th entry'.$D{SL0}.'"',
	 '"<3> 5th entry"',
	 '"<4> 6th entry"',
	 '"<5> 7th entry"',
	 '"<6> 8th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-2 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"<2> 1st entry"',
	 '"<3> 2nd entry"',
	 '"<4> 3rd entry"',
	 '"<5> '.$D{SL1}.'4th entry'.$D{SL0}.'"',
	 '"<6> 5th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-5-2 ==<0>#',
	 '"<1>+1-5/8    "',
	 '"<2> 1st entry"',
	 '"<3> '.$D{SL1}.'2nd entry'.$D{SL0}.'"',
	 '"<4> 3rd entry"',
	 '"<5> '.$D{SL1}.'4th entry'.$D{SL0}.'"',
	 '"<6> 5th entry"',
	 '"<7> [Quit]   "',
	 '#=============#',
	 $prompt),
    'simple 8-5-2 mainloop runs correctly';
@result = $lb8->selected;
is_deeply(\@result, [1, 3],
	  'selected after processing listbox 8-5-2 returns correct selection');
is($counter, 4, 'counter has correct 2nd value');

####################################
# short list with multiple selection:
my @text2 = ('1st entry', '2nd entry which is a bit too long');
my $lb2 = UI::Various::Listbox->new(texts => \@text2, height => 5, width => 30);
my ($w, $h) = $lb2->_prepare(99);
is($w, 30, '_prepare returns correct width for listbox 2-5-2');
is($h, 6, '_prepare returns correct height for listbox 2-5-2');
$_ = $lb2->_show('', $w, $h, '<%1d> ');
is($_,
   join("\n",
	 '1-2/2                         ',
	 '1st entry                     ',
	 '2nd entry which is a bit too l',
	 '                              ',
	 '                              ',
	 '                              '),
   '_show for listbox 2-5-2 returned correct result');
$win = $main->window({title => '2-5-2'}, $lb2, $quit);
stdout_is
{   _call_with_stdin("2\n2\n7\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 2-5-2 =======================<0>#',
	 '"<1>+1-2/2                         "',
	 '"<2> 1st entry                     "',
	 '"<3> 2nd entry which is a bit too l"',
	 '"                                  "',
	 '"                                  "',
	 '"                                  "',
	 '"<7> [Quit]                        "',
	 '#==================================#',
	 $prompt . '#= 2-5-2 =======================<0>#',
	 '"<1>+1-2/2                         "',
	 '"<2> '.$D{SL1}.'1st entry'.$D{SL0}.'                     "',
	 '"<3> 2nd entry which is a bit too l"',
	 '"                                  "',
	 '"                                  "',
	 '"                                  "',
	 '"<7> [Quit]                        "',
	 '#==================================#',
	 $prompt . '#= 2-5-2 =======================<0>#',
	 '"<1>+1-2/2                         "',
	 '"<2> 1st entry                     "',
	 '"<3> 2nd entry which is a bit too l"',
	 '"                                  "',
	 '"                                  "',
	 '"                                  "',
	 '"<7> [Quit]                        "',
	 '#==================================#',
	 $prompt),
    'short 2-5-2 mainloop runs correctly';
@result = $lb2->selected;
is_deeply(\@result, [],
   'selected after processing short listbox 2-5-2 returns correct selection');

####################################
# short list without multiple selection:
$lb2 = UI::Various::Listbox->new(texts => ['1st', '2nd'], height => 5,
				 selection => 1);
$win = $main->window({title => '2-5-1'}, $lb2, $quit);
stdout_is
{   _call_with_stdin("3\n3\n7\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 2-5-1 ==#',
	 '"<1>+1-2/2 "',
	 '"<2> 1st   "',
	 '"<3> 2nd   "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"<7> [Quit]"',
	 '#==========#',
	 $prompt . '#= 2-5-1 ==#',
	 '"<1>+1-2/2 "',
	 '"<2> 1st   "',
	 '"<3> '.$D{SL1}.'2nd'.$D{SL0}.'   "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"<7> [Quit]"',
	 '#==========#',
	 $prompt . '#= 2-5-1 ==#',
	 '"<1>+1-2/2 "',
	 '"<2> 1st   "',
	 '"<3> 2nd   "',
	 '"          "',
	 '"          "',
	 '"          "',
	 '"<7> [Quit]"',
	 '#==========#',
	 $prompt),
    'short 2-5-1 mainloop runs correctly';
$_ = $lb2->selected;
is($_, undef,
   'selected after processing short listbox 2-5-1 returns correct selection');

####################################
# list without selection and multiple pages:
$lb8 = UI::Various::Listbox->new(texts => \@text8, height => 3,
				 selection => 0);
$win = $main->window({title => '8-3-0'}, $lb8, $quit);
stdout_is
{   _call_with_stdin("1\n1\n2\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 8-3-0 ==<0>#',
	 '"<1>+1-3/8    "',
	 '"    1st entry"',
	 '"    2nd entry"',
	 '"    3rd entry"',
	 '"<2> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-3-0 ==<0>#',
	 '"<1>+4-6/8    "',
	 '"    4th entry"',
	 '"    5th entry"',
	 '"    6th entry"',
	 '"<2> [Quit]   "',
	 '#=============#',
	 $prompt . '#= 8-3-0 ==<0>#',
	 '"<1>+6-8/8    "',
	 '"    6th entry"',
	 '"    7th entry"',
	 '"    8th entry"',
	 '"<2> [Quit]   "',
	 '#=============#',
	 $prompt),
    'simple 8-3-0 mainloop runs correctly';
