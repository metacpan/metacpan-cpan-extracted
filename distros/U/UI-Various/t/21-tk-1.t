# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 21-tk.t".
#
# Without "Build" file it could be called with "perl -I../lib 21-tk.t"
# or "perl -Ilib t/21-tk.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

# Note that the original sole test script had to be split up into one part
# per running UI::Various::Tk::mainloop due to sporadic (11%) segmentation
# violations in Tk's internal code.
# An additional forced initialisation did not help as it blocked the
# mainloop.

#########################################################################

use v5.12.1;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More;
use Test::Output;

BEGIN {
    $ENV{DISPLAY}  or  plan skip_all => 'DISPLAY not found';
    eval { require Tk; };
    $@  and  plan skip_all => 'Perl/Tk not found';
    plan tests => 9;

    # define fixed environment for unit tests:
    delete $ENV{UI};
}

use UI::Various({use => ['Tk']});

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

my $main = UI::Various::Main->new();
is(ref($main), 'UI::Various::Tk::Main', '$main is UI::Various::Tk::Main');

####################################
# bad behaviour:

eval {   UI::Various::Tk::Main::_init(1);   };
like($@,
     qr/^UI::.*::Tk::Main may only be called from UI::Various::Main$re_msg_tail/,
     'forbidden call to UI::Various::Tk::Main::_init should fail');

####################################
# test standard behaviour:

my $text = UI::Various::Text->new(text => 'Hello World!');
is(ref($text), 'UI::Various::Tk::Text',
   'type UI::Various::Tk::Text is correct');
my $button1 = UI::Various::Button->new(text => 'OK',
				       code => sub { print "OK!\n"; });
is(ref($button1), 'UI::Various::Tk::Button',
   'type UI::Various::Tk::Button is correct');

stderr_like
{   $text->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Text element must be accompanied by parent$re_msg_tail/,
    'orphaned Text causes error';
stderr_like
{   $button1->_prepare(0, 0);   }
    qr/^UI::.*::Tk::Button element must be accompanied by parent$re_msg_tail/,
    'orphaned Button causes error';

my $button2 = UI::Various::Button->new(text => 'Quit');
my $w = $main->window({title => 'Hello', height => 12, width => 42},
		      $text, $button1, $button2);
is(ref($w), 'UI::Various::Tk::Window',
   'type UI::Various::Tk::Window is correct');
$button2->code(sub { $w->destroy(); });

combined_is
{
    $main->_mainloop_prepare;
    $button1->_tk()->invoke;
    $button2->_tk()->invoke;
    $main->_mainloop_run;
}
    "OK!\n",
    'mainloop produces correct output';
is(@{$main->{children}}, 0, 'main no longer has children');
