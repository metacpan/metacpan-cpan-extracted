# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 22-fileselect.t".
#
# Without "Build" file it could be called with "perl -I../lib 22-fileselect.t"
# or "perl -Ilib t/22-fileselect.t".  This is also the command needed to find
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

use Test::More tests => 18;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Compound::FileSelect)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# identical parts of messages and some basic building blocks:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $main = UI::Various::Main->new(width => 40);
my $re_output_select_box =
    " *\n<0> leave box\n\n----- enter number\\s+to\\s+choose\\s+next\\s+step: ";
my $re_output_select_list_base =
    "<0>   leave listbox\nenter selection";
my $re_output_select_list =
    $re_output_select_list_base . ': ';
my $re_output_select_list_scroll =
    $re_output_select_list_base . ' \(\+/- scrolls\): ';
my $re_output_select_option = "enter selection\\s+\\(0\\s+to\\s+cancel\\): ";

my $forbidden_dir = T_PATH . '/forbidden';
# clean-up possible errors from previous test:
-d $forbidden_dir  and  rmdir $forbidden_dir;

####################################
# test creation errors:
warning_like
{   $_ = UI::Various::Compound::FileSelect->new();   }
{   carped => qr/^mandatory parameter 'mode' is missing$re_msg_tail/   },
    'missing mode parameter fails';
warning_like
{   $_ = UI::Various::Compound::FileSelect->new(mode => 3);   }
{   carped => qr/^parameter 'mode' must be in \[0\.\.2\]$re_msg_tail/   },
    'bad mode parameter fails';

####################################
# test selection of single input file:
my $fs = UI::Various::Compound::FileSelect->new(mode => 1, directory => T_PATH);
$main->add($fs);			# now we have a maximum width
is($fs->selection(), T_PATH . '/',
   'no selection in mode 0 returns current directory with trailing /');

my $re_basic_output =
    "[ <1-8>*]+ 00-compile\\.t\n" .
    "[ <1-8>*]+ 00-test-functions\\.\n" .
    "[ <1-8>*]+ 01-use\\.t\n" .
    "[ <1-8>*]+ 02-core\\.t\n" .
    "[ <1-8>*]+ 03-widget-essentia\n" .
    "[ <1-8>*]+ 04-container\\.t\n" .
    "[ <1-8>*]+ 11-main\\.t\n" .
    "[ <1-8>*]+ 12-text\\.t\n";
my $re_whole_output =
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2>   1-8/\\d+\n" .
    $re_basic_output .
    $re_output_select_box;
stdout_like(sub {   $fs->_show('');   },
	    qr/^$re_whole_output$/,
	    '_show 1 prints correct text');

my $selection = "2\n3\n0\n0\n";
my $re_list_output = "<\\+/-> 1-8/\\d+\n" . $re_basic_output;
my $re_output =
    $re_whole_output . "2\n" .
    $re_list_output .
    $re_output_select_list_scroll . "3\n" .
    $re_list_output .
    $re_output_select_list_scroll . "0\n" .
    $re_whole_output . "0\n";
stdout_like
{   _call_with_stdin($selection, sub {   $fs->_process();   });   }
    qr/^$re_output$/,
    '_process 1 prints correct text';
like($fs->selection(), qr'/t/01-use.t',
     '_process 1 selected correct selection');
$main->remove($fs);

####################################
# test selection of multiple Perl scripts as input files:

$fs = UI::Various::Compound::FileSelect->new(mode => 2,
					     directory => T_PATH,
					     filter =>
					     [['all files' => '.+'],
					      ['PL scripts' => '\.pl$']]
					    );
is(join("\n", $fs->selection()), T_PATH . '/',
   'no selection in mode 2 returns current directory with trailing /');
$main->add($fs);			# now we again have a maximum width
$re_whole_output =
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2> \\[ all files \\]\n" .
    "<3>   1-8/\\d+\n" .
    $re_basic_output .
    $re_output_select_box;
stdout_like(sub {   $fs->_show('');   },
	    qr/^$re_whole_output$/,
	    '_show 2 prints correct text');

$selection = "2\n2\n3\n1\n1\n1\n1\n3\n0\n0\n";
my $re_pl_whole_output_t =
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2> \\[ PL scripts \\]\n" .
    "<3>   1-1/1\n" .
    "      functions\n\n\n\n\n\n\n\n";
my $re_list_output_t =
    "      1-1/1\n" .
    "<1>   functions\n\n\n\n\n\n\n\n";
my $re_basic_pl_output =
    "[ <1-3>*]+ call_with_stdin\\.pl\n" .
    "[ <1-3>*]+ run_in_fork\\.pl\n" .
    "[ <1-3>*]+ sub_perl\\.pl\n" .
    "\n\n\n\n\n";
$re_output =
    $re_whole_output . "2\n" .
    "<1> all files\n<2> PL scripts\n" . $re_output_select_option . "2\n" .
    $re_pl_whole_output_t . $re_output_select_box . "3\n" .
    $re_list_output_t . $re_output_select_list . "1\n" .
    "      1-3/3\n" . $re_basic_pl_output . $re_output_select_list . "1\n" .
    "      1-3/3\n" . $re_basic_pl_output . $re_output_select_list . "1\n" .
    "      1-3/3\n" . $re_basic_pl_output . $re_output_select_list . "1\n" .
    "      1-3/3\n" . $re_basic_pl_output . $re_output_select_list . "3\n" .
    "      1-3/3\n" . $re_basic_pl_output . $re_output_select_list . "0\n" .
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "/functions\n    \n" .
    "<2> \\[ PL scripts \\]\n" .
    "<3>   1-3/3\n" . $re_basic_pl_output . $re_output_select_box . "0\n" .
'';
stdout_like
{   _call_with_stdin($selection, sub {   $fs->_process();   });   }
    qr/^$re_output$/,
    '_process 2 prints correct text';
like(join("\n", $fs->selection()),
     qr'/t/functions/call_with_stdin\.pl\n.*/t/functions/sub_perl\.pl$',
     '_process 2 selected correct selection');
$main->remove($fs);

####################################
# test selection of single output file (entering name):
$fs = UI::Various::Compound::FileSelect->new(mode => 0,
					     directory => T_PATH,
					     filter =>
					     [['all files' => '.+'],
					      ['text files' => '\.txt$']]
					    );
$main->add($fs);			# now we again have a maximum width
$re_whole_output =
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2> \\[ all files \\]\n" .
    "<3>   1-8/\\d+\n" .
    $re_basic_output .
    "<4> *\n" . $re_output_select_box;
stdout_like(sub {   $fs->_show('');   },
	    qr/^$re_whole_output$/,
	    '_show 3 prints correct text');

$selection = "2\n2\n3\n1\n0\n1\n4\narrow.txt\n0\n";
my $re_txt_whole_output_t =
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2> \\[ text files \\]\n" .
    "<3>   1-1/1\n" .
    "      functions\n\n\n\n\n\n\n\n";
$re_output =
    $re_whole_output . "2\n" .
    "<1> all files\n<2> text files\n" . $re_output_select_option . "2\n" .
    $re_txt_whole_output_t . "<4> *\n" . $re_output_select_box . "3\n" .
    $re_list_output_t . $re_output_select_list . "1\n" .
    "      0/0\n\n\n\n\n\n\n\n\n" . $re_output_select_list . "0\n" .
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "/functions\n    \n" .
    "<2> \\[ text files \\]\n" .
    "      0/0\n\n\n\n\n\n\n\n\n" .
    "<4> *\n" . $re_output_select_box . "1\n" .
    $re_txt_whole_output_t . "<4> *\n" . $re_output_select_box . "4\n" .
    "old value: *\nnew value\\? " .
    $re_txt_whole_output_t . "<4> arrow\\.txt\n" . $re_output_select_box .
    "0\n";
stdout_like
{   _call_with_stdin($selection, sub {   $fs->_process();   });   }
    qr/^$re_output$/,
    '_process 3 prints correct text';
like($fs->selection(), qr'/t/arrow.txt',
     '_process 3 selected correct selection');
$main->remove($fs);

####################################
# test selection of single output file (selecting it):
$fs = UI::Various::Compound::FileSelect->new(mode => 0, directory => T_PATH);
$main->add($fs);			# now we have a maximum width

$re_whole_output =
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2>   1-8/\\d+\n" .
    $re_basic_output .
    "<3> *\n" . $re_output_select_box;
stdout_like(sub {   $fs->_show('');   },
	    qr/^$re_whole_output$/,
	    '_show 4 prints correct text');

$selection = "2\n1\n0\n0\n";
$re_list_output = "<\\+/-> 1-8/\\d+\n" . $re_basic_output;
$re_output =
    $re_whole_output . "2\n" .
    $re_list_output .
    $re_output_select_list_scroll . "1\n" .
    $re_list_output .
    $re_output_select_list_scroll . "0\n" .
    "<1> \n<\\*> \\[ \\.\\. \\]\n    " . T_PATH . "\n    \n" .
    "<2>   1-8/\\d+\n" .
    $re_basic_output .
    "<3> 00-compile\\.t\n" . $re_output_select_box . "0\n";
stdout_like
{   _call_with_stdin($selection, sub {   $fs->_process();   });   }
    qr/^$re_output$/,
    '_process 4 prints correct text';
like($fs->selection(), qr'/t/00-compile.t',
     '_process 4 selected correct selection');

####################################
# use last complex object to test pretty-printer (dump):
$_ = $main->dump;
like($_,
     qr{^children:\n
	\ \ UI::Various::Compound::FileSelect=.*_inputvar:.*_msg:.*_widget:\n
	\ \ \ \ \ \ files:\n
	\ \ \ \ \ \ \ \ _initialised:1\n
	\ \ \ \ \ \ \ \ first:0\n
	\ \ \ \ \ \ \ \ height:8\n
	\ \ \ \ \ \ \ \ on_select:CODE.*
	\ \ \ \ \ \ \ \ selection:1\n
	\ \ \ \ \ \ \ \ texts:\n
	.*
	^\ \ \ \ field:\n
	^\ \ \ \ \ \ UI::Various::PoorTerm::Box=.*
	^\ \ \ \ \ \ \ \ \ \ UI::Various::PoorTerm::Button=.*
	^\ \ \ \ \ \ \ \ \ \ \ \ text:\.\.\n
	\ \ \ \ \ \ \ \ \ \ \ \ width:2\n
	\ \ \ \ \ \ \ \ \ \ UI::Various::PoorTerm::Text=.*
	^\ \ \ \ \ \ UI::Various::PoorTerm::Listbox=.*
	^\ \ \ \ \ \ UI::Various::PoorTerm::Input=.*
	^\ \ \ \ \ \ UI::Various::PoorTerm::Text=.*
	^height:[1-9][0-9]+\n
	max_height:[1-9][0-9]+\n
	max_width:[1-9][0-9]+\n
	ui:UI::Various::PoorTerm\n
	width:40\n\Z}msx,
     'dump of main looks correct');

$main->remove($fs);

####################################
# triggering remaining missing coverage:
SKIP:
{
    mkdir($forbidden_dir, 0)  or
	skip "can't check \"forbidden\" directory - mkdir failed", 1;
    $fs->_cd('forbidden');
    like($fs->{_msg}, qr|^can't open '.*/t/forbidden': |,
	 'directory without access fails correctly');
    rmdir $forbidden_dir;
}
