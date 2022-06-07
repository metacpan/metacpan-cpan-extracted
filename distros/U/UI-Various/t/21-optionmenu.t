# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 21-optionmenu.t".
#
# Without "Build" file it could be called with "perl -I../lib
# 21-optionmenu.t" or "perl -Ilib t/21-optionmenu.t".  This is also the
# command needed to find out what specific tests failed in a "./Build test"
# as the later only gives you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More tests => 22;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Optionmenu)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

####################################
# test creation errors:
warning_like
{   $_ = UI::Various::Optionmenu->new();   }
{   carped => qr/^mandatory parameter 'options' is missing$re_msg_tail/   },
    'missing options parameter fails';
warnings_like
{   $_ = UI::Various::Optionmenu->new(options => 0);   }
    [ { carped => qr/^'options' attribute .* a ARRAY reference$re_msg_tail/ },
      { carped => qr/^mandatory parameter 'options' is missing$re_msg_tail/ }, ],
    'invalid options parameter fails';
warning_like
{   $_ = UI::Various::Optionmenu->new(options => [[0]]);   }
{   carped => qr/^invalid pair in 'options' attribute$re_msg_tail/   },
    'bad options parameter fails';
warning_like
{   $_ = UI::Various::Optionmenu->new(options => [0], on_select => '');   }
{   carped =>
	qr/^'on_select' attribute must be a CODE reference$re_msg_tail/   },
    'bad on_select parameter fails';

####################################
# test standard behaviour:

my $main = UI::Various::Main->new(width => 40);

my @options = ([a => 1], [b => 2], [c => 3], 42);
my $om = UI::Various::Optionmenu->new(options => \@options);
$_ = $om->options();
is_deeply($_, [[a => 1], [b => 2], [c => 3], [42 => 42]],
	  'menu of options initialises correctly');
is(ref($om), 'UI::Various::PoorTerm::Optionmenu',
   'Optionmenu is concrete class');

$main->add($om);			# now we have a maximum width
stdout_is(sub {   $om->_show('<1> ');   },
	  "<1> [ --- ]\n",
	  '_show 1 prints correct text');
my $selection = "x\n9\n2\n";
my $prompt = "<1> a\n<2> b\n<3> c\n<4> 42\nenter selection (0 to cancel): ";
my $output =
    $prompt . "x\ninvalid selection\n" .
    $prompt . "9\ninvalid selection\n" .
    $prompt . "2\n";
combined_is
{   _call_with_stdin($selection, sub { $om->_process(); });   }
    $output,
    '_process 1 prints correct text';
is($om->{_selected_menu}, 'b', '_process 1 sets correct text');
is($om->{_selected}, 2, '_process 1 sets correct value');
is($om->selected, 2, 'selected 1 returns correct value');

stdout_is(sub {   $om->_show('<1> ');   },
	  "<1> [ b ]\n",
	  '_show 2 prints correct text');

$om = UI::Various::Optionmenu->new(options => \@options, init => 1);
is($om->{_selected_menu}, 'a', 'initialisation sets correct text');
is($om->{_selected}, 1, 'initialisation sets correct value');

$main->add($om);			# now we again have a maximum width

my $value = -1;
$om->on_select(sub { $value = $_[0]; });
combined_is
{   _call_with_stdin("4\n", sub { $om->_process(); });   }
    $prompt . "4\n",
    '_process 2 prints correct text';
stdout_is(sub {   $om->_show('<1> ');   },
	  "<1> [ 42 ]\n",
	  '_show 3 prints correct text');
is($om->selected, 42, 'selected 2 returns correct value');
is($value, 42, 'on_select 2 has been called correctly');

$value = -1;
combined_is
{   _call_with_stdin("1\n", sub { $om->_process(); });   }
    $prompt . "1\n",
    '_process 3 prints correct text';
stdout_is(sub {   $om->_show('<1> ');   },
	  "<1> [ a ]\n",
	  '_show 4 prints correct text');
is($om->selected, 1, 'selected 3 returns correct value');
is($value, 1, 'on_select 3 has been called correctly');
