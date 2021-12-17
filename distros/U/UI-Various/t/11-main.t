# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 11-main.t".
#
# Without "Build" file it could be called with "perl -I../lib 11-main.t"
# or "perl -Ilib t/11-main.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More tests => 18;
use Test::Output;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => 'Main'});
use UI::Various::toplevel;

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do T_PATH . '/functions/run_in_fork.pl';

#########################################################################


#########################################################################
# minimal dummy classes needed for unit tests:
package UI::Various::Window
{   use UI::Various::widget; our @ISA = qw(UI::Various::toplevel);   };
package UI::Various::Dialog
{   use UI::Various::widget; our @ISA = qw(UI::Various::toplevel);   };
package Dummy
{   sub new { my $self = {}; bless $self, 'Dummy'; }   };

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

_run_in_fork
    ('max_app initialisation with big values',
     3,
     sub{
	 my $main = UI::Various::Main->new({height => 9999,
					    width => 9999});
	 _ok($main, 'UI::Various::Main->new({...}) returned singleton');
	 _ok(10 < $main->height()  &&  $main->height() < 8999,
	     'maximum application height reduced into [11, 9000]: ' .
	     $main->height());
	 _ok(10 < $main->width()  &&  $main->width() < 8999,
	     'maximum application width reduced into [11, 9000]: ' .
	     $main->width());
     });
_run_in_fork
    ('max_app initialisation with normal values',
     3,
     sub{
	 my $main = UI::Various::Main->new({height => 15,
					    width => 40});
	 _ok($main, 'UI::Various::Main->new({...}) returned singleton');
	 _ok(15 == $main->height(),
	     'maximum application height set to 15: ' . $main->height());
	 _ok(40 == $main->width(),
	     'maximum application width set to 40: ' . $main->width());
     });
_run_in_fork
    ('default initialisation without stty',
     3,
     sub{
	 $ENV{PATH} = '';
	 my $main = UI::Various::Main->new();
	 _ok($main, 'UI::Various::Main->new() returned singleton');
	 _ok(24 == $main->height(),
	     'maximum application height set to 24');
	 _ok(80 == $main->width(),
	     'maximum application width set to 80');
     });
eval {   UI::Various::PoorTerm::Main::_init(1);   };
like($@,
     qr/^.*PoorTerm::Main may only be called from UI::Various::Main$re_msg_tail/,
     'forbidden call to UI::Various::PoorTerm::Main::_init should fail');
eval {   $_ = UI::Various::Main::height(Dummy->new());   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::\w+::widget::.*$re_msg_tail/,
     'bad access of height before set-up of singleton should fail');
eval {   $_ = UI::Various::Main::width(Dummy->new());   };
like($@,
     qr/^invalid object \(Dummy\) in call to UI::\w+::widget::.*$re_msg_tail/,
     'bad access of width before set-up of singleton should fail');

my $main = UI::Various::Main->new();
ok($main, 'UI::Various::Main->new returned singleton');
ok(10 < $main->max_height(), 'maximum screen height > 10');
ok(10 < $main->max_width(), 'maximum screen width > 10');
is($main->height(), $main->max_height(),
   'maximum application height equals maximum screen height: ' .
   $main->height());
is($main->width(), $main->max_width(),
   'maximum application width equals maximum screen width: ' .
   $main->width());
$_ = UI::Various::Main->new();
is($_, $main, '2nd initialisation returned singleton');
$_ = UI::Various::Main::height(Dummy->new());
is($_, $main->height(),
   'bad access of height after set-up of singleton ignores object');
$_ = UI::Various::Main::width(Dummy->new());
is($_, $main->width(),
   'bad access of width after set-up of singleton ignores object');

####################################
# broken tests for $main->window() and $main->mainloop():

combined_like
{   $main->window(Dummy->new());   }
    qr/^invalid parameter 'Dummy' in call to UI::.*::Main::window$re_msg_tail/,
    'wrong object in window should fail';
combined_like
{   $main->window(UI::Various::Window->new());   }
    qr/^invalid object \(UI::.*::Window\) in call to .*::window$re_msg_tail/,
    'wrong object in window should fail';
combined_like
{   $main->window(UI::Various::Dialog->new());   }
    qr/^invalid object \(UI::.*::Dialog\) in call to .*::window$re_msg_tail/,
    'wrong object in window should fail';

eval {   $_ = UI::Various::Main::mainloop($main);   };
like($@,
     qr/^specified implementation missing$re_msg_tail/,
     'bad access of general mainloop should fail');
# Note that the real code of $main->window() and $main->mainloop() will be
# tested together with PoorTerm::Window!
