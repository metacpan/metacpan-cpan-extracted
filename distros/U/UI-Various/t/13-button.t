# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 13-button.t".
#
# Without "Build" file it could be called with "perl -I../lib 13-button.t"
# or "perl -Ilib t/13-button.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More tests => 6;
use Test::Output;
use Test::Warn;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Button)]});

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

warning_like
{   $_ = UI::Various::Button->new(code => 1);   }
{   carped => qr/^'code' attribute must be a CODE reference$re_msg_tail/   },
     'bad code parameter fails';

my $main = UI::Various::Main->new(width => 20);

$_ = UI::Various::Button->new();
is(ref($_), 'UI::Various::PoorTerm::Button', 'Button is concrete class');
is($_->text(), '', 'empty constructor creates empty text');

$_ = UI::Various::Button->new(text => 'OK', code => sub { print "OK!\n"; });
is($_->text(), 'OK', 'constructor sets text');

$main->add($_);			# now we have a maximum width
stdout_is(sub {   $_->_show('(1) ');   },
	  "(1) [ OK ]\n", '_show prints correct text');
stdout_is(sub {   $_->_process();   },
	  "OK!\n", '_process prints correct text');
