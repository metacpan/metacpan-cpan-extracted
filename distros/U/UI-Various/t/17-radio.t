# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 17-radio.t".
#
# Without "Build" file it could be called with "perl -I../lib 17-radio.t"
# or "perl -Ilib t/17-radio.t".  This is also the command needed to find
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

use UI::Various({use => [], include => [qw(Main Radio)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $re_msg_mandatory_buttons =
    qr/^mandatory parameter 'buttons' is missing$re_msg_tail/;

warning_like
{   $_ = UI::Various::Radio->new();   }
{   carped => $re_msg_mandatory_buttons   },
    'missing button parameter fails';
warning_like
{   $_ = UI::Various::Radio->new(buttons => '');   }
{   carped =>
	[qr/^'buttons' attribute must be a ARRAY reference$re_msg_tail/
	 ,   $re_msg_mandatory_buttons]   },
    'bad button parameter fails';
warning_like
{   $_ = UI::Various::Radio->new(buttons => []);   }
{   carped =>
	[qr/^'buttons' may not be empty$re_msg_tail/,
	 $re_msg_mandatory_buttons]   },
    'empty button parameter fails';
warning_like
{   $_ = UI::Various::Radio->new(buttons => [1]);   }
{   carped =>
	[qr/^odd number of parameters in init.* list of buttons$re_msg_tail/,
	 $re_msg_mandatory_buttons]   },
    'odd button parameter fails';
warning_like
{   $_ = UI::Various::Radio->new(buttons => [1 => 2], var => '');   }
{   carped => qr/^'var' attribute must be a SCALAR reference$re_msg_tail/  },
    'bad var parameter fails';

my $main = UI::Various::Main->new(width => 20);

my $var = 'c';
my $radio =
    UI::Various::Radio->new(buttons => [a => 'Roses are really, really red!',
					b => 'green',
					c => 'blue'],
			    var => \$var);
is(ref($radio), 'UI::Various::PoorTerm::Radio', 'Radio is concrete class');

$main->add($radio);			# now we have a maximum width
stdout_is(sub {   $radio->_show('<1> ');   },
	  "<1> ( ) Roses are really,\n        really red!\n" .
	  "    ( ) green\n    (o) blue\n",
	  '_show 1 prints correct (wrapped) text');
$main->remove($radio);
$main->width(40);

$radio =
    UI::Various::Radio->new(buttons => [a => 'red', b => 'green', c => 'blue'],
			    var => \$var);
$main->add($radio);
stdout_is(sub {   $radio->_show('<1> ');   },
	  "<1> ( ) red\n    ( ) green\n    (o) blue\n",
	  '_show 2a prints correct text');

my $selection = "x\n9\n2\n";
my $prompt = "<1> red\n<2> green\n<3> blue\nenter selection (0 to cancel): ";
my $output =
    $prompt . "x\ninvalid selection\n" .
    $prompt . "9\ninvalid selection\n" .
    $prompt . "2\n";
combined_is
{   _call_with_stdin($selection, sub { $radio->_process(); });   }
    $output,
    '_process 2 prints correct text';
is($var, 'b', 'variable has correct value');
stdout_is(sub {   $radio->_show('<1> ');   },
	  "<1> ( ) red\n    (o) green\n    ( ) blue\n",
	  '_show 2b prints correct text');

combined_is
{   _call_with_stdin("0\n", sub { $radio->_process(); });   }
    $prompt . "0\n",
    '_process 2 prints correct text when aborted';
is($var, 'b', 'variable still has correct value');

$main->remove($radio);

$radio =
    UI::Various::Radio->new(buttons =>
			    [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5,
			     6 => 6, 7 => 7, 8 => 8, 9 => 9, 10 => 10],
			    var => \$var);
is($var, undef, 'variable has been reset');
$main->add($radio);
stdout_is(sub {   $radio->_show('<1> ');   },
	  "<1> ( ) 1\n    ( ) 2\n    ( ) 3\n    ( ) 4\n    ( ) 5\n" .
	  "    ( ) 6\n    ( ) 7\n    ( ) 8\n    ( ) 9\n    ( ) 10\n",
	  '_show 3a prints correct text');

combined_is
{   _call_with_stdin("9\n", sub { $radio->_process(); });   }
    "< 1> 1\n< 2> 2\n< 3> 3\n< 4> 4\n< 5> 5\n< 6> 6\n< 7> 7\n< 8> 8\n< 9> 9\n" .
    "<10> 10\nenter selection (0 to cancel): 9\n",
    '_process 3 prints correct text';
stdout_is(sub {   $radio->_show('<1> ');   },
	  "<1> ( ) 1\n    ( ) 2\n    ( ) 3\n    ( ) 4\n    ( ) 5\n" .
	  "    ( ) 6\n    ( ) 7\n    ( ) 8\n    (o) 9\n    ( ) 10\n",
	  '_show 3b prints correct text');
is($var, 9, 'variable again has correct value');

####################################
# other standard behaviour - various to increase coverage:

UI::Various::Radio::_init_var($main);
delete $radio->{var};
$radio->_init_var();
