# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 18-box.t".
#
# Without "Build" file it could be called with "perl -I../lib 18-box.t"
# or "perl -Ilib t/18-box.t".  This is also the command needed to find
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

use Test::More tests => 62;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Text Button Box)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# minimal dummy classes needed for unit tests:
package Dummy
{   sub new { my $self = {}; bless $self, 'Dummy'; }   };
package UI::Various::Broken
{
    use UI::Various::widget;
    our @ISA = qw(UI::Various::container);
    sub remove($@) { return undef; }
};
package UI::Various::PoorTerm::Broken
{   use UI::Various::widget; our @ISA = qw(UI::Various::Broken);   };

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_msg_tail_add = qr/ in call to UI::Various::Box::add$re_msg_tail/;

####################################
# test creation errors:
my $dummy = Dummy->new();
eval {   $_ = UI::Various::Box::add($dummy);   };
like($@,
     qr/^invalid object \(Dummy\)$re_msg_tail_add/,
     'bad call to add creates error');

warning_like
{   $_ = UI::Various::Box->new(columns => {});   }
{   carped =>
	qr/^parameter 'columns' must be a positive integer$re_msg_tail/   },
    'bad box parameter fails';
warning_like
{   $_ = UI::Various::Box->new(columns => '');   }
{   carped =>
	qr/^parameter 'columns' must be a positive integer$re_msg_tail/   },
    'empty box parameter fails';
warning_like
{   $_ = UI::Various::Box->new(columns => 0);   }
{   carped =>
	qr/^parameter 'columns' must be a positive integer$re_msg_tail/   },
    'wrong box parameter fails';
warning_like
{   $_ = UI::Various::Box->new(rows => {});   }
{   carped => qr/^parameter 'rows' must be a positive integer$re_msg_tail/   },
    'bad box parameter fails';
warning_like
{   $_ = UI::Various::Box->new(rows => '');   }
{   carped => qr/^parameter 'rows' must be a positive integer$re_msg_tail/   },
    'empty box parameter fails';
warning_like
{   $_ = UI::Various::Box->new(rows => 0);   }
{   carped => qr/^parameter 'rows' must be a positive integer$re_msg_tail/   },
    'wrong box parameter fails';

my $main = UI::Various::Main->new(width => 40);

####################################
# test default creation:
my $box = UI::Various::Box->new();
is(ref($box), 'UI::Various::PoorTerm::Box', 'Box is concrete class');
is($box->border,  0, 'Box has correct disabled default border');
is($box->rows,    1, 'Box has correct default rows');
is($box->columns, 1, 'Box has correct default columns');
stdout_is(sub {   $box->_show('<1> ');   },
	  "<1> \n    \n",
	  '_show prints correct empty Box');

####################################
# test wrong adding:
eval {   $_ = $box->add($dummy);   };
like($@,
     qr/^invalid object \(Dummy\)$re_msg_tail_add/,
    'adding wrong object creates error');
warning_like
{   $_ = $box->add('');   }
{   carped => qr/^parameter 'row' must be a pos.*integer$re_msg_tail_add/   },
    'passing bad row creates error';
is($_, 0, 'passing bad row changed nothing');
warning_like
{   $_ = $box->add(0, '');   }
{   carped => qr/^parameter 'column' must be a pos.*integer$re_msg_tail_add/   },
    'passing bad column creates error';
is($_, 0, 'passing bad column changed nothing');
warning_like
{   $_ = $box->add(99);   }
{   carped => qr/^invalid value 99 for parameter 'row'$re_msg_tail_add/   },
    'passing wrong row creates error';
is($_, 0, 'passing wrong row changed nothing');
warning_like
{   $_ = $box->add(0, 99);   }
{   carped => qr/^invalid value 99 for parameter 'column'$re_msg_tail_add/   },
    'passing wrong column creates error';
is($_, 0, 'passing wrong column changed nothing');
warning_like
{   $_ = $box->add(0, 0, 0);   }
{   carped => qr/^invalid scalar '0'$re_msg_tail_add/   },
    'passing bad position creates error';
is($_, 0, 'passing bad position changed nothing');

$box = UI::Various::Box->new(border => 0);
is($box->border,  0, 'Box has correct explicitly disabled border');
my $kept = UI::Various::Text->new(text => 'not removable');
my $unremovable = UI::Various::Broken->new();
$_ = $unremovable->add($kept);
is($_, 1, 'prepared object that is not addable');
warning_like
{   $_ = $box->add($kept);   }
{   carped =>
	qr/^can't remove '.*HASH.*' from old parent '.*HASH.*'$re_msg_tail/   },
    'only removable objects can be added';
is($_, 0, 'an object that can not be removed changed nothing');

warning_like
{   $_ = $box->remove($kept);   }
{   carped =>
	qr/^can't remove U.*m::Text: no such node in U.*m::Box$re_msg_tail/   },
    'foreign element could not be removed';
is($_, undef, 'removing foreign element returns nothing');

####################################
# test creation and adding:
$box = UI::Various::Box->new(border => 1, rows => 2, columns => 2);
is($box->border,  1, 'Box has correct explicitly enabled border');
is($box->rows,    2, 'Box has correct explicit rows');
is($box->columns, 2, 'Box has correct explicit columns');
$_ = $box->field(0, 0);
is($_, undef, 'elements are yet undefined');

my $button1 = UI::Various::Button->new(text => 'OK',
				       code => sub { print "OK!\n"; });
$_ = $box->add(1, 0);
is($_, 0, 'adding no element at valid position returned correct value');
$_ = $box->add(0, 1, $button1);
is($_, 1, 'adding 1 element returned correct value');
$_ = $box->field(0, 1);
is(ref($_), 'UI::Various::PoorTerm::Button', 'added element can be accessed');
$_ = $box->field(1, 0);
is($_, undef, 'other elements are still undefined');

####################################
# test output:
$main->add($box);			# now we have a maximum width
stdout_is(sub {   $box->_show('<1> ');   },
	  "<1> ----------\n" .
	  "<*> [ OK ]\n" .
	  "    ----------\n",
	  '_show prints correct partly filled Box');

$_ = $box->add(UI::Various::Text->new(text => 'text being a little bit longer'),
	       UI::Various::Text->new(text => 'text #2'),
	       UI::Various::Text->new(text => 'text #3'));
is($_, 3, 'adding 3 elements returned correct value');
is($box->children(), 4, 'box has correct number of children');
warning_like
{   $_ = $box->add(UI::Various::Text->new(text => 'too much'));   }
{   carped => qr|no free position for .*::PoorTerm::Text$re_msg_tail_add|   },
    'adding too much fails';
is($_, 0, 'adding too much changed nothing');

my $output_select =
    "<0> leave box\n\n----- enter number to choose next step: ";

stdout_is(sub {   $box->_show('<1> ');   },
	  "<1> ----------\n" .
	  "    text being a little bit longer\n" .
	  "<*> [ OK ]\n" .
	  "    text #2\n" .
	  "    text #3\n" .
	  "    ----------\n",
	  '_show with prefix correct prints full Box');
stdout_is(sub {   $box->_show('  ');   },
	  "  ----------\n" .
	  "  text being a little bit longer\n" .
	  "  [ OK ]\n" .
	  "  text #2\n" .
	  "  text #3\n" .
	  "  ----------\n",
	  '_show with blank prefix prints correct full Box');
stdout_is(sub {   $box->_show('');   },
	  "    text being a little bit longer\n" .
	  "<1> [ OK ]\n" .
	  "    text #2\n" .
	  "    text #3\n" .
	  $output_select,
	  '_show with empty prefix prints correct full Box');

####################################
# test default processing:
stdout_is(sub { $_ = $box->_process(); },
	  "OK!\n",
	  '_process 1 prints correct text');
is($_, 0, '_process 1 returned correctly');

####################################
# test modifications:
my $button2 = UI::Various::Button->new(text => 'HI',
				       code => sub { print "Hi!\n"; });
warning_like
{   $_ = $box->add(1, 0, $button2);   }
{   carped => qr|element 1/0 in call.*::Box::add already exists$re_msg_tail|   },
    'adding existing element fails';
is($_, 0, 'adding existing element returned correct value');
$_ = $box->field(1, 0);
is(ref($_), 'UI::Various::PoorTerm::Text', 'Box::field returned correct class');
my $text2 = $box->remove($_);
is($text2, $_, 'element 1/0 could be removed');

$box->add(1, $button2);
$main->width(20);
stdout_is(sub {   $box->_show('<1> ');   },
	  "<1> ----------\n" .
	  "    text being a little\n    bit longer\n" .
	  "    [ OK ]\n" .
	  "    [ HI ]\n" .
	  "    text #3\n" .
	  "    ----------\n",
	  '_show prints correct modified Box');

####################################
# test standard processing:
$main->width(40);
my $output =
    "    text being a little bit longer\n" .
    "<1> [ OK ]\n" .
    "<2> [ HI ]\n" .
    "    text #3\n" .
    $output_select;
stdout_is(sub {   $box->_show('');   },
	  $output,
	  '_show with empty prefix prints correct modified Box');
stdout_is
{   _call_with_stdin("1\n2\n0\n", sub { $box->_process(); });   }
    $output . "1\nOK!\n" . $output . "2\nHi!\n" . $output . "0\n",
    '_process 2 prints correct text';
$main->remove($box);

####################################
# tests with sub-boxes:
$box = UI::Various::Box->new(border => 1, rows => 2);
my $box_1 = UI::Various::Box->new(border => 0, columns => 2);
my $box_2 = UI::Various::Box->new(border => 1, columns => 2);
my $button3 = UI::Various::Button->new(text => 'HO',
				       code => sub { print "Ho Ho Ho!\n"; });
$box->add($box_1, $box_2);
is($box->children(), 2, 'main box has correct number of children');
$box_1->add($button1, $text2);
is($box_1->children(), 2, 'sub-box 1 has correct number of children');
$box_2->add($button2, $button3);
is($box_2->children(), 2, 'sub-box 2 has correct number of children');

$main->add($box);			# now we again have a maximum width

$output =
    "<1> \n" .
    "<*> [ OK ]\n" .
    "    text #2\n" .
    "    \n" .
    "<2> ----------\n" .
    "    [ HI ]\n" .
    "    [ HO ]\n" .
    "    ----------\n" .
    $output_select;
stdout_is(sub {   $box->_show('');   },
	  $output,
	  '_show with empty prefix prints correct combined Box');
my $output_2 =
    "<1> [ HI ]\n" .
    "<2> [ HO ]\n" .
    $output_select;
stdout_is(sub {   $box_2->_show('');   },
	  $output_2,
	  '_show with empty prefix prints correct sub-box 2');
combined_is
{   _call_with_stdin("1\n2\n1\n2\nx\n9\n0\n0\n", sub { $box->_process(); });   }
    $output .
    "1\nOK!\n" .
    $output .
    "2\n" .
    $output_2 .
    "1\nHi!\n" .
    $output_2 .
    "2\nHo Ho Ho!\n" .
    $output_2 .
    "x\ninvalid selection\n" .
    $output_2 .
    "9\ninvalid selection\n" .
    $output_2 .
    "0\n" .
    $output .
    "0\n",
    '_process 3 prints correct text';
$main->remove($box);

####################################
# tests with multiple levels of partly filled boxes:
$_ = UI::Various::Box->new(border => 1, rows => 2, columns => 2);
my $outer_box = $_;
$_ = UI::Various::Box->new(border => 1, rows => 2, columns => 2);
$_->add(0, 1, $box);
$outer_box->add(1, $_);
$main->add($outer_box);

$output =
    "<1> ----------\n" .
    "    <*> ----------\n" .
    "            \n" .
    "            [ OK ]\n" .
    "            text #2\n" .
    "            \n" .
    "            ----------\n" .
    "            [ HI ]\n" .
    "            [ HO ]\n" .
    "            ----------\n" .
    "        ----------\n" .
    "    ----------\n" .
    $output_select;
stdout_is(sub {   $outer_box->_show('');   },
	  $output,
	  '_show with empty prefix prints 4 combined boxes correctly');
$main->remove($outer_box);
$_ = $outer_box;
$outer_box = UI::Various::Box->new(border => 1);
$outer_box->add($_);
$main->add($outer_box);

$output =
    "<1> ----------\n" .
    "    <*> ----------\n" .
    "        <*> ----------\n" .
    "                \n" .
    "                [ OK ]\n" .
    "                text #2\n" .
    "                \n" .
    "                ----------\n" .
    "                [ HI ]\n" .
    "                [ HO ]\n" .
    "                ----------\n" .
    "            ----------\n" .
    "        ----------\n" .
    "    ----------\n" .
    $output_select;
stdout_is(sub {   $outer_box->_show('');   },
	  $output,
	  '_show with empty prefix prints 5 combined boxes correctly');
