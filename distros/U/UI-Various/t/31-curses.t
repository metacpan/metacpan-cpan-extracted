# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 31-curses.t".
#
# Without "Build" file it could be called with "perl -I../lib 31-curses.t"
# or "perl -Ilib t/31-curses.t".  This is also the command needed to find
# out what specific tests failed in a "./Build test" as the later only gives
# you a number and not the description of the test.
#
# For successful run with test coverage use "./Build testcover".

#########################################################################

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More;
use Test::Output;

BEGIN {
    eval { require Curses::UI; };
    $@  and  plan skip_all => 'Curses::UI not found';
    plan tests => 16;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['Curses']});

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

# We use a (dirty?) trick to simulate the keyboard input for Curses::UI.
# This way we can test using almost all of the real thing; and it's easier
# than using Curses::UI's "feedkey" (which is not yet documented anyway) and
# "add_callback":
my @chars_to_read = ();
package Curses::UI::Common {
    no warnings 'redefine';
    sub char_read(;$)
    {
	0 < @chars_to_read  or  die 'run out of input';
	local $_ = shift @chars_to_read;
	return $_;
    };
};

my $main;
stdout_like
{
    # On Linux we try to save the TTY configuration to keep the output of
    # Test::More readable, although this still only works correctly if the
    # prompt is in the last line of a TTY before running the test.  (Note
    # that -g is POSIX, --save is not!)
    my $tty_configuration;
    $^O eq 'linux'  and  $tty_configuration = `stty -g`;
    $main = UI::Various::Main->new(width => 20, height => 5);
    $tty_configuration  and  system('stty ' . $tty_configuration);
}
    qr/^.*\e\[(\?\d{3,4}h|1;24r).*$/s,
    'UI::Various::Main initialises STDOUT with some escape sequence';
is(ref($main), 'UI::Various::Curses::Main',
   '$main is UI::Various::Curses::Main');

####################################
# bad behaviour:

eval {   UI::Various::Curses::Main::_init(1);   };
like($@,
     qr/^.*::Curses::Main may only be called from UI::Various::Main$re_msg_tail/,
     'forbidden call to UI::Various::Curses::Main::_init should fail');

####################################
# test standard behaviour:

my $text1 = UI::Various::Text->new(text => 'Hello World!');
is(ref($text1), 'UI::Various::Curses::Text',
   'type UI::Various::Curses::Text is correct');
my $button1 = UI::Various::Button->new(text => 'OK',
				       code => sub {
					   print "OK!\n";
				       });
is(ref($button1), 'UI::Various::Curses::Button',
   'type UI::Various::Curses::Button is correct');

stderr_like
{   $text1->_prepare(0, 0);   }
    qr/^UI::.*::Curses::Text element must be accompanied by parent$re_msg_tail/,
    'orphaned Text causes error';
stderr_like
{   $button1->_prepare(0, 0);   }
    qr/^UI::.*:Curses::Button element must be accompanied by parent$re_msg_tail/,
    'orphaned Button causes error';

my $w;
my $button2 = UI::Various::Button->new(text => 'Quit',
				       code => sub {
					   $w->destroy;
				       });
$w = $main->window({title => 'Hello', width => 42},
		   $text1, $button1, $button2);
is(ref($w), 'UI::Various::Curses::Window',
   'type UI::Various::Curses::Window is correct');

@chars_to_read = (' ', "\t", ' ');
# TODO: Remove dummy code inserted to counter strange testing behaviour:
combined_like
{   $main->mainloop;   }
#{ print "- Hello World!- Hello -Quit-\n";  }
    qr/^.* Hello World!.* Hello .*Quit\b.*$/s,
    'mainloop produces correct output';
#$w->destroy;
is(@{$main->{children}}, 0, 'main no longer has children');

####################################
# test standard behaviour with 2 windows:

my ($w1, $w2);
my $text2 = UI::Various::Text->new(text => 'Bye!');
$button2 =
    UI::Various::Button->new(text => 'Quit',
			     code => sub {   $w1->destroy;   $w2->destroy;   });
$text1 = UI::Various::Text->new(text => 'HI!');
$button1 =
    UI::Various::Button->new(text => 'Bye',
			     code => sub {
				 $w2 = $main->window({title => 'bye',
						      width => 10},
						     $text2, $button2); });
$w1 = $main->window({title => 'hi', width => 10}, $text1, $button1);


# Note that title and first text have a different sequence when running this
# test as stand-alone (correct sequence) and within the test harness of
# "./Build test" (wrong sequence).  So we don't care about the sequence as
# long as both strings appear:
my $re_o1 = '.*(?:hi\b.*HI!|HI!.*hi\b).*Bye\b';
my $re_o2 = '.*(?:bye\b.*Bye!|Bye!.*bye\b).*Quit\b';

@chars_to_read = (' ', "\cN", "\cN", "\cP", "\cP", ' ');
combined_like
{   $main->mainloop;   }
    qr/^$re_o1$re_o2$re_o1$re_o2$re_o1$re_o2.*$/s,
    'mainloop 2 produces correct output';
is(@{$main->{children}}, 0, 'main no longer has children');

####################################
# test unused behaviour (and get 100% coverage):

$w1 = UI::Various::Window->new(title => 'hello');
$w2 = UI::Various::Window->new(title => 'dummy');
is(@{$main->{children}}, 2, 'main has new children');
is($w1->title(), 'hello', 'window constructor sets title');
$w1->add($text1);
is(@{$w1->{children}}, 1, 'Window has 1 child');
$w1->destroy();
$w2->destroy();
is(@{$main->{children}}, 0, 'main is clean again');

$main->mainloop();		# an additional empty call just for the coverage
