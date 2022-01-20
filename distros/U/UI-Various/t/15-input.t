# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 15-input.t".
#
# Without "Build" file it could be called with "perl -I../lib 15-input.t"
# or "perl -Ilib t/15-input.t".  This is also the command needed to find
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

use Test::More tests => 5;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Input)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

warning_like
{   $_ = UI::Various::Input->new(textvar => '');   }
{   carped => qr/^'textvar' attribute must be a SCALAR reference$re_msg_tail/  },
     'bad textvar parameter fails';

my $main = UI::Various::Main->new(width => 20);

my $input = UI::Various::Input->new();
is(ref($input), 'UI::Various::PoorTerm::Input', 'Input is concrete class');

$main->add($input);			# now we have a maximum width
stdout_is(sub {   $input->_show('(1) ');   },
	  "(1) \n", '_show prints empty text of dummy variable');
$main->remove($input);

my $var = 'initial value';
$input = UI::Various::Input->new(textvar => \$var);
$main->add($input);
stdout_is
{   _call_with_stdin("something new\n", sub { $input->_process(); });   }
    "old value: initial value\n" . 'new value? ',
    '_process prints correct test';
is($var, 'something new', 'variable has correct new value');
