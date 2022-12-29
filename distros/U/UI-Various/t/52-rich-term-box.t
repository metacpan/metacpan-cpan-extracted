# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 52-rich-term-box.t".
#
# Without "Build" file it could be called with "perl -I../lib 52-rich-term-box.t"
# or "perl -Ilib t/52-rich-term-box.t".  This is also the command needed to find
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
    plan tests => 34;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['RichTerm']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# prepare some building blocks for the tests:

# TODO: currently for testing purposes only, later switch in base.pm when utf8
#use utf8::all
#%UI::Various::RichTerm::base::D = UI::Various::RichTerm::base::DECO_UTF8;
my %D = %UI::Various::RichTerm::base::D; # simple short-cut

# 10-16 of each (short / long / multi-line texts, buttons):
my $text1_10 = '';
my @short  = ();
my @long   = ();
my @multi  = ();
my @big    = ();
my @button = ();
foreach (1..16)
{
    $text1_10 .= ' ' . $_ x $_ if $_ <= 10;
    push @short,  UI::Various::Text->new(text => $_);
    push @long,   UI::Various::Text->new(text => $_ x $_);
    push @multi,  UI::Various::Text->new(text => join("\n", ($_) x $_));
    push @big,    UI::Various::Text->new(text => $_,
					 align => $_ + 6 - 6 * int(($_ - 1) / 3),
					 height => 3,
					 width => 3)
	if $_ <= 9;
    my $str = $_ . "\n";
    push @button, UI::Various::Button->new(text => $_,
					   code => sub { print $str; });
}
$text1_10 = UI::Various::Text->new(text => $text1_10, width => 24);

my $main = UI::Various::Main->new(width => 40);

my $win;
my $quit = UI::Various::Button->new(text => 'Quit',
				    code => sub { $win->destroy; });
my $dump;
my $dump_and_quit = UI::Various::Button->new(text => 'Quit',
					     code => sub {
						 $dump = $win->dump;
						 $win->destroy;
					     });

my $prompt = 'enter selection: ';

#########################################################################
# unit tests:

####################################
# simplest of all 3x3 boxes:
my $box = UI::Various::Box->new(rows => 3, columns => 3);
is(ref($box), 'UI::Various::RichTerm::Box', 'Box is concrete class');
$box->add(@{short}[0..8]);
$win = $main->window({title => 'Simplest'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Simplest #',
	 '"    1 2 3  "',
	 '"    4 5 6  "',
	 '"    7 8 9  "',
	 '"<1> [Quit] "',
	 '#===========#',
	 $prompt),
    'simplest mainloop runs correctly';

####################################
# 3x3 box with texts of different lengths:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{long}[0..8]);
$win = $main->window({title => 'Normal Long'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Normal Long =============<0>#',
	 '"    1       22       333      "',
	 '"    4444    55555    666666   "',
	 '"    7777777 88888888 999999999"',
	 '"<1> [Quit]                    "',
	 '#==============================#',
	 $prompt),
    'normal long mainloop runs correctly';

####################################
# 3x3 box with texts of different lengths in reverse order:
$box = UI::Various::Box->new(rows => 3, columns => 3, width => 999);
$box->add(reverse(@{long}[0..8]));
$win = $main->window({title => 'Reversed Long'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Reversed Long ===========<0>#',
	 '"    999999999 88888888 7777777"',
	 '"    666666    55555    4444   "',
	 '"    333       22       1      "',
	 '"<1> [Quit]                    "',
	 '#==============================#',
	 $prompt),
    'reversed long mainloop runs correctly';

####################################
# 3x3 box with incomplete texts of different lengths:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{long}[0..8]);
$box->remove($long[1]);
$box->remove($long[3]);
$win = $main->window({title => 'normal long'}, $box, $dump_and_quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= normal long =============<0>#',
	 '"    1                333      "',
	 '"            55555    666666   "',
	 '"    7777777 88888888 999999999"',
	 '"<1> [Quit]                    "',
	 '#==============================#',
	 $prompt),
    'incomplete long mainloop runs correctly';
like($dump,
     qr{_space:\n
	\ \ 26:26\n
	\ \ 3:3\n
	\ \ 6:6\n
	\ \ 1:1\n
	_total_height:6\n
	children:\n
	\ \ UI::Various::RichTerm::Box=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ _heights:\n
	\ \ \ \ \ \ 1\n
	\ \ \ \ \ \ 1\n
	\ \ \ \ \ \ 1\n
	\ \ \ \ _sizes:\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 1\ 1\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 0\ 0\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 3\ 1\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 0\ 0\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 5\ 1\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 6\ 1\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 7\ 1\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 8\ 1\n
	\ \ \ \ \ \ ARRAY\(0x[0-9a-f]+\):\ 9\ 1\n
	\ \ \ \ _widths:\n
	\ \ \ \ \ \ 7\n
	\ \ \ \ \ \ 8\n
	\ \ \ \ \ \ 9\n
	\ \ \ \ border:0\n
	\ \ \ \ columns:3\n
	\ \ \ \ field:\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:1\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:333\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:55555\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:666666\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:7777777\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:88888888\n
	\ \ \ \ \ \ UI::Various::RichTerm::Text=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ \ \ \ \ text:999999999\n
	\ \ \ \ rows:3\n
	\ \ UI::Various::RichTerm::Button=HASH\(0x[0-9a-f]+\):\n
	\ \ \ \ code:CODE\(0x[0-9a-f]+\)\n
	\ \ \ \ text:Quit\n
	title:normal\ long\n}x,
     'dump of incomplete window is correct');

####################################
# 3x3 box with aligned texts:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@big);
$win = $main->window({title => 'Big'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Big ======<0>#',
	 '"    1    2    3"',
	 '"               "',
	 '"               "',
	 '"               "',
	 '"    4    5    6"',
	 '"               "',
	 '"               "',
	 '"               "',
	 '"    7    8    9"',
	 '"<1> [Quit]     "',
	 '#===============#',
	 $prompt),
    'big aligned box in mainloop runs correctly';

####################################
# 4x1 box with radio buttons, border and button inside:
my $var = 'b';
my $radio =
    UI::Various::Radio->new(buttons => [a => 123,
					b => 42,
					c => 12345],
			    var => \$var);
$box = UI::Various::Box->new(rows => 2, border => 2);
$box->add($radio,$quit);
$win = $main->window($box);
stdout_is
{   _call_with_stdin("2\n", sub { $main->mainloop; });   }
    join("\n",
	 '#============<0>#',
	 '"+-------------+"',
	 '"|<1> ( ) 123  |"',
	 '"|    (o) 42   |"',
	 '"|    ( ) 12345|"',
	 '"+-------------+"',
	 '"|<2> [Quit]   |"',
	 '"+-------------+"',
	 '#===============#',
	 $prompt),
    'incomplete long mainloop runs correctly';

####################################
# 3x3 box with multi-line texts of different lengths:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{multi}[0..8]);
$win = $main->window({title => 'Multi-Line'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Multi-Line #',
	 '"    1 2 3    "',
	 '"      2 3    "',
	 '"        3    "',
	 '"    4 5 6    "',
	 '"    4 5 6    "',
	 '"    4 5 6    "',
	 '"    4 5 6    "',
	 '"      5 6    "',
	 '"        6    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"      8 9    "',
	 '"        9    "',
	 '"<1> [Quit]   "',
	 '#=============#',
	 $prompt),
    'multi-line mainloop runs correctly';

####################################
# 3x3 box with multi-line texts of different lengths:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{multi}[0..8]);
$box->remove($multi[1]);
$box->remove($multi[3]);
$win = $main->window({title => 'multi-line'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= multi-line #',
	 '"    1   3    "',
	 '"        3    "',
	 '"        3    "',
	 '"      5 6    "',
	 '"      5 6    "',
	 '"      5 6    "',
	 '"      5 6    "',
	 '"      5 6    "',
	 '"        6    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"    7 8 9    "',
	 '"      8 9    "',
	 '"        9    "',
	 '"<1> [Quit]   "',
	 '#=============#',
	 $prompt),
    'incomplete multi-line mainloop runs correctly';

####################################
# simplest 3x3 box with borders:
$box = UI::Various::Box->new(rows => 3, columns => 3, border => 1);
$box->add(@{short}[0..8]);
$win = $main->window({title => 'Borders'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Borders =#',
	 '"    +-+-+-+"',
	 '"    |1|2|3|"',
	 '"    +-+-+-+"',
	 '"    |4|5|6|"',
	 '"    +-+-+-+"',
	 '"    |7|8|9|"',
	 '"    +-+-+-+"',
	 '"<1> [Quit] "',
	 '#===========#',
	 $prompt),
    'borders mainloop runs correctly';

####################################
# incomplete 3x3 box with borders:
$box = UI::Various::Box->new(rows => 3, columns => 3, border => 1);
$box->add(@{short}[0..8]);
$box->remove($short[1]);
$box->remove($short[3]);
$win = $main->window({title => 'borders'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= borders =#',
	 '"    +-+-+-+"',
	 '"    |1| |3|"',
	 '"    +-+-+-+"',
	 '"    | |5|6|"',
	 '"    +-+-+-+"',
	 '"    |7|8|9|"',
	 '"    +-+-+-+"',
	 '"<1> [Quit] "',
	 '#===========#',
	 $prompt),
    'incomplete borders mainloop runs correctly';

####################################
# 3x3 box with a wrapped text:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{short}[0..8]);
$box->remove($short[4]);
$box->add($text1_10);
$win = $main->window({title => 'wrapped'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= wrapped ===================<0>#',
	 '"    1 2                        3"',
	 '"    4  1 22 333 4444 55555     6"',
	 '"      666666 7777777 88888888   "',
	 '"      999999999                 "',
	 '"      10101010101010101010      "',
	 '"    7 8                        9"',
	 '"<1> [Quit]                      "',
	 '#================================#',
	 $prompt),
    'wrapped mainloop runs correctly';

####################################
# incomplete 3x3 box with a wrapped text:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add($short[0], 0, 2, $short[2], 1, 1, $text1_10, @{short}[5..8]);
$win = $main->window({title => 'wrapped'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= wrapped ===================<0>#',
	 '"    1                          3"',
	 '"       1 22 333 4444 55555     6"',
	 '"      666666 7777777 88888888   "',
	 '"      999999999                 "',
	 '"      10101010101010101010      "',
	 '"    7 8                        9"',
	 '"<1> [Quit]                      "',
	 '#================================#',
	 $prompt),
    'incomplete wrapped mainloop runs correctly';

####################################
# 3x3 box with one button:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{short}[0..8]);
$box->remove($short[4]);
$box->add($button[4]);
$win = $main->window({title => 'Button'}, $box, $quit);
my $stdout = join("\n",
		  '#= Button ===<0>#',
		  '"    1     2   3"',
		  '"    4 <1> [5] 6"',
		  '"    7     8   9"',
		  '"<2> [Quit]     "',
		  '#===============#',
		  $prompt);
stdout_is
{   _call_with_stdin("1\n2\n", sub { $main->mainloop; });   }
    $stdout . "5\n" . $stdout,
    'button mainloop runs correctly';

####################################
# incomplete 3x3 box with one button and a checkbox:
my $cbvar = 1;
my $check = UI::Various::Check->new(text => '!', var => \$cbvar);
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add($short[0], 0, 2, $short[2], 1, 1, $button[4], $check, @{short}[6..8]);
$win = $main->window({title => 'button'}, $box, $quit);
$stdout = join("\n",
	       '#= button ===========<0>#',
	       '"    1             3    "',
	       '"      <1> [5] <2> [X] !"',
	       '"    7     8       9    "',
	       '"<3> [Quit]             "',
	       '#=======================#',
	       $prompt);
stdout_is
{   _call_with_stdin("1\n3\n", sub { $main->mainloop; });   }
    $stdout . "5\n" . $stdout,
    'incomplete button mainloop runs correctly';

####################################
# 3x3 box with 9(+1) buttons:
$box = UI::Various::Box->new(rows => 3, columns => 3);
$box->add(@{button}[0..8]);
$win = $main->window({title => '10 Buttons'}, $box, $quit);
$stdout = join("\n",
	       '#= 10 Buttons ===============<0>#',
	       '"     < 1> [1] < 2> [2] < 3> [3]"',
	       '"     < 4> [4] < 5> [5] < 6> [6]"',
	       '"     < 7> [7] < 8> [8] < 9> [9]"',
	       '"<10> [Quit]                    "',
	       '#===============================#',
	       $prompt);
my $input = '';
my $sequence = $stdout;
foreach (1..9)
{   $input .= $_ . "\n";   $sequence .= $_ . "\n" . $stdout;   }
stdout_is
{   _call_with_stdin($input . "10\n", sub { $main->mainloop; });   }
    $sequence,
    '10 buttons mainloop runs correctly';

####################################
# 3 rows in 3 columns with multi-line texts of different lengths:
$box = UI::Various::Box->new(columns => 3);
my $box1 = UI::Various::Box->new(rows => 3);
my $box2 = UI::Various::Box->new(rows => 3);
my $box3 = UI::Various::Box->new(rows => 3);
$box->add($box1, $box2, $box3);
$box1->add(@{multi}[0,3,6]);
$box2->add(@{multi}[1,4,7]);
$box3->add(@{multi}[2,5,8]);
$win = $main->window({title => '3 Boxes'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= 3 Boxes #',
	 '"    1 2 3 "',
	 '"    4 2 3 "',
	 '"    4 5 3 "',
	 '"    4 5 6 "',
	 '"    4 5 6 "',
	 '"    7 5 6 "',
	 '"    7 5 6 "',
	 '"    7 8 6 "',
	 '"    7 8 6 "',
	 '"    7 8 9 "',
	 '"    7 8 9 "',
	 '"    7 8 9 "',
	 '"      8 9 "',
	 '"      8 9 "',
	 '"      8 9 "',
	 '"        9 "',
	 '"        9 "',
	 '"        9 "',
	 '"<1> [Quit]"',
	 '#==========#',
	 $prompt),
    'mainloop with 3 rows in 3 columns runs correctly';

####################################
# border-less boxes in box with borders:
my $box4;
$box  = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box1 = UI::Various::Box->new(rows => 2, columns => 2);
$box2 = UI::Various::Box->new(rows => 2, columns => 2);
$box3 = UI::Various::Box->new(rows => 2, columns => 2);
$box4 = UI::Various::Box->new(rows => 2, columns => 2);
$box->add($box1, $box2, $box3, $box4);
$box1->add(@{short}[ 0.. 3]);
$box2->add(@{short}[ 4.. 7]);
$box3->add(@{short}[ 8..11]);
$box4->add(@{short}[12..15]);
$win = $main->window({title => 'Borders out'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Borders out ===#',
	 '"    +-----+-----+"',
	 '"    |1 2  |5 6  |"',
	 '"    |3 4  |7 8  |"',
	 '"    +-----+-----+"',
	 '"    |9  10|13 14|"',
	 '"    |11 12|15 16|"',
	 '"    +-----+-----+"',
	 '"<1> [Quit]       "',
	 '#=================#',
	 $prompt),
    'mainloop with bordered outer box runs correctly';

####################################
# bordered boxes in box without borders:
$box  = UI::Various::Box->new(rows => 2, columns => 2);
$box1 = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box2 = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box3 = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box4 = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box->add($box1, $box2, $box3, $box4);
$box1->add(@{short}[ 0.. 3]);
$box2->add(@{short}[ 4.. 7]);
$box3->add(@{short}[ 8..11]);
$box4->add(@{short}[12..15]);
$win = $main->window({title => 'Borders in'}, $box, $quit);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    join("\n",
	 '#= Borders in ===<0>#',
	 '"    +-+-+   +-+-+  "',
	 '"    |1|2|   |5|6|  "',
	 '"    +-+-+   +-+-+  "',
	 '"    |3|4|   |7|8|  "',
	 '"    +-+-+   +-+-+  "',
	 '"    +--+--+ +--+--+"',
	 '"    |9 |10| |13|14|"',
	 '"    +--+--+ +--+--+"',
	 '"    |11|12| |15|16|"',
	 '"    +--+--+ +--+--+"',
	 '"<1> [Quit]         "',
	 '#===================#',
	 $prompt),
    'mainloop with bordered inner box runs correctly';

####################################
# border-less boxes plus button in box with borders:
$box  = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box1 = UI::Various::Box->new(rows => 2, columns => 2);
$box2 = UI::Various::Box->new(rows => 2, columns => 2);
$box3 = UI::Various::Box->new(rows => 2, columns => 2);
$box->add($box1, $box2, $box3, $button[3]);
$box1->add(@{short}[ 0.. 3]);
$box2->add(@{short}[ 4.. 7]);
$box3->add(@{short}[ 8..11]);
$win = $main->window({title => 'Borders&Buttons'}, $box, $quit);
$stdout = join("\n",
	       '#= Borders&Buttons =#',
	       '"    +-----+-------+"',
	       '"    |1 2  |    5 6|"',
	       '"    |3 4  |    7 8|"',
	       '"    +-----+-------+"',
	       '"    |9  10|<1> [4]|"',
	       '"    |11 12|       |"',
	       '"    +-----+-------+"',
	       '"<2> [Quit]         "',
	       '#===================#',
	       $prompt);
stdout_is
{   _call_with_stdin("1\n2\n", sub { $main->mainloop; });   }
    $stdout . "4\n" . $stdout,
    'mainloop with bordered outer box and button runs correctly';

####################################
# border-less boxes plus quit button in box with borders:
$box  = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box1 = UI::Various::Box->new(rows => 2, columns => 2);
$box2 = UI::Various::Box->new(rows => 2, columns => 2);
$box3 = UI::Various::Box->new(rows => 2, columns => 2);
$box->add($box1, $box2, $box3, $quit);
$box1->add(@{short}[ 0.. 3]);
$box2->add(@{short}[ 4.. 7]);
$box3->add(@{short}[ 8..11]);
$win = $main->window({title => 'Quit in Box'}, $box);
$stdout = join("\n",
	       '#= Quit in Box =<0>#',
	       '"+-----+----------+"',
	       '"|1 2  |    5 6   |"',
	       '"|3 4  |    7 8   |"',
	       '"+-----+----------+"',
	       '"|9  10|<1> [Quit]|"',
	       '"|11 12|          |"',
	       '"+-----+----------+"',
	       '#==================#',
	       $prompt);
stdout_is
{   _call_with_stdin("1\n", sub { $main->mainloop; });   }
    $stdout,
    'mainloop with quit button in bordered outer box runs correctly';

####################################
# borderline behaviour tests to increase coverage:
my ($w, $h);

# full "need_max":
$box = UI::Various::Box->new(rows => 2, columns => 2);
$box->add(@{short}[0..3]);
$main->add($box);
($w, $h) = $box->_prepare(3, 0);	# 3 triggers "need_max" for all columns
is($w, 3, '_prepare 1 returns correct width');
is($h, 2, '_prepare 2 returns correct height');
$_ = $box->_show('', $w, $h, '');
is($_, join("\n", '1 2', '3 4'),
   'box without window returns correct text');
$main->remove($box);

# DISTORTED: no top-level (also "need_max"):
$box = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box->add(@{short}[0..2], $button[0]);
$main->add($box);
($w, $h) = $box->_prepare(10, 4);	# size 10 triggers "need_max" here
is($w, 11, '_prepare 2 returns correct width');
is($h,  5, '_prepare 2 returns correct height');
$_ = $box->_show('', $w, $h, '<%1d> ');
is($_, join("\n",
	    '+-+-------+',
	    '|1|    2  |',
	    '+-+-------+',
	    '|3|[1]|    ',		# no selector due to missing top-level!
	    '+-+-------+'),
   'box without window returns correct (malformed) text');
$main->remove($box);

# DISTORTED: unused top-level:
$box = UI::Various::Box->new(rows => 2, columns => 2, border => 1);
$box->add(@{short}[0..2], $button[0]);
$win = $main->window({title => 'unused'}, $box);
($w, $h) = $box->_prepare(20, 4);
is($w, 11, '_prepare 3 returns correct width');
is($h,  5, '_prepare 3 returns correct height');
$_ = $box->_show('', $w, $h, '<%1d> ');
is($_, join("\n",
	    '+-+-------+',
	    '|1|    2  |',
	    '+-+-------+',
	    '|3|[1]|    ',		# no selector due to unused top-level!
	    '+-+-------+'),
   'box with unused window returns correct (malformed) text');
$win->destroy;

# CORRECTED: box with explicit width is to small:
$box = UI::Various::Box->new(rows => 2, columns => 2, width => 2);
$box->add(@{short}[0..3]);
$main->add($box);
($w, $h) = $box->_prepare(10, 0);
is($w, 3, '_prepare 4 returns correct needed minimum width');
is($h, 2, '_prepare 4 returns correct height');
$_ = $box->_show('', $w, $h, '');
is($_, join("\n", '1 2', '3 4'),
   'box with explicit too short width returns correct text');
$main->remove($box);
