# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 16-check.t".
#
# Without "Build" file it could be called with "perl -I../lib 16-check.t"
# or "perl -Ilib t/16-check.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 8;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Check)]});

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

warning_like
{   $_ = UI::Various::Check->new(var => '');   }
{   carped => qr/^'var' attribute must be a SCALAR reference$re_msg_tail/  },
     'bad var parameter fails';

my $main = UI::Various::Main->new(width => 20);

my $check = UI::Various::Check->new();
is(ref($check), 'UI::Various::PoorTerm::Check', 'Check is concrete class');

$main->add($check);			# now we have a maximum width
stdout_is(sub {   $check->_show('(1) ');   },
	  "(1) [ ] \n", '_show prints empty default checkbox');
$main->remove($check);
my $var = 'false';
$check = UI::Various::Check->new(var => \$var);
is($var, 1, 'string "false" sets Check to correct value of 1');

$var = undef;
$check = UI::Various::Check->new(text => 'on/off', var => \$var);
is($var, 0, 'undef sets Check to correct value of 0');
$main->add($check);			# now we have a maximum width
$check->_process();
is($var, 1, '_process inverts variable correctly to 1');
stdout_is(sub {   $check->_show('(1) ');   },
	  "(1) [X] on/off\n", '_show prints correct checked checkbox with text');
$check->_process();
is($var, 0, '_process inverts variable correctly back to 0');
