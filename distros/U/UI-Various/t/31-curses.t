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

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More;
use Test::Output;

BEGIN {
    eval { require Curses::UI; };
    $@  and  plan skip_all => 'Curses::UI not found';
    plan tests => 29;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['Curses']});

#########################################################################
# minimal dummy classes needed for unit tests:
package UI::Various::Dummy
{
    use UI::Various::widget;
    our @ISA = qw(UI::Various::widget);
    sub new($;\[@$])
    { return UI::Various::core::construct({ text => '' }, '.', @_); }
    sub text($;$)
    { return UI::Various::core::access('text', undef, @_); }
};
package UI::Various::Curses::Dummy
{
    use UI::Various::widget;
    our @ISA = qw(UI::Various::Dummy UI::Various::Curses::base);
};

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
     qr/^UI::Various::Curses::Main may only be called from itself$re_msg_tail/,
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

my $ivar = 'thing';
my $input1 = UI::Various::Input->new(textvar => \$ivar);
is(ref($input1), 'UI::Various::Curses::Input',
   'type UI::Various::Curses::Input is correct');
eval {   $input1->_update();   };
is($@, '', 'update of unused UI::Various::Curses::Input does not fail');

my $cvar = 1;
my $check1 = UI::Various::Check->new(text => 'on/off', var => \$cvar);
is(ref($check1), 'UI::Various::Curses::Check',
   'type UI::Various::Curses::Check is correct');
eval {   $check1->_update();   };
is($@, '', 'update of unused UI::Various::Curses::Check does not fail');

my $rvar = 'r';
my $radio1 =
    UI::Various::Radio->new(buttons => [r => 'red', g => 'green', b => 'blue'],
			    var => \$rvar);
my $rvar2 = undef;
my $radio2 = UI::Various::Radio->new(buttons => [1 => 1, 2 => 2, 3 => 3],
				     var => \$rvar2);

stderr_like
{   $text1->_prepare(0, 0);   }
    qr/^UI::.*::Curses::Text element must be accompanied by parent$re_msg_tail/,
    'orphaned Text causes error';
stderr_like
{   $button1->_prepare(0, 0);   }
    qr/^UI::.*:Curses::Button element must be accompanied by parent$re_msg_tail/,
    'orphaned Button causes error';
stderr_like
{   $input1->_prepare(0, 0);   }
    qr/^UI::.*:Curses::Input element must be accompanied by parent$re_msg_tail/,
    'orphaned Input causes error';
stderr_like
{   $check1->_prepare(0, 0);   }
    qr/^UI::.*:Curses::Check element must be accompanied by parent$re_msg_tail/,
    'orphaned Check causes error';
stderr_like
{   $radio1->_prepare(0, 0);   }
    qr/^UI::.*::Curses::Radio element must be accompanied by parent$re_msg_tail/,
    'orphaned Radio causes error';

# additional fields with same SCALAR reference as $input1:
my $text2  = UI::Various::Text ->new(text    => \$ivar);
my $input2 = UI::Various::Input->new(textvar => \$ivar);
my $dummy  = UI::Various::Dummy->new(text    => \$ivar);
my $check2 = UI::Various::Check->new(text => '2nd check', var => \$cvar);

eval {   $text2->_update();   };
is($@, '', 'update of unused UI::Various::Curses::Text does not fail');

my $result = 'not set';
my $w;
my $button2 = UI::Various::Button->new(text => 'Quit',
				       code => sub {
					   $result =
					       $text2->_cui->text . ':' .
					       $input2->_cui->get;
					   $w->destroy;
				       });
$w = $main->window({title => 'Hello', width => 42},
		   $text1, $input1, $check1, $radio1, $radio2, $button1,
		   $button2, $text2, $input2, $check2);
is(ref($w), 'UI::Various::Curses::Window',
   'type UI::Various::Curses::Window is correct');

# Note that the text for an input field needs a '-1' after each character,
# and 'j' is 'Cursor down' in a Listbox:
@chars_to_read = ('s', -1, 'o', -1, 'm', -1, 'e', -1,	# input1
		  "\t", ' ', ' ', ' ',			# check1
		  "\t", ' ', 'j', ' ',			# radio1
		  "\t",					# radio2 (ignored)
		  "\t", ' ',				# button1
		  "\t", ' ');				# button2
combined_like
{   $main->mainloop;   }
    qr/^.* Hello World!.* Hello .*Quit\b.*\[X\].*\[X\].*$/s,
    'mainloop produces correct output';
is(@{$main->{children}}, 0, 'main no longer has children');
is($ivar, 'something', 'input variable has correct new value');
is($cvar, 0, 'check variable has correct value 0 after 3 invocations');
is($rvar, 'g', 'radio button variable 1 has correct new value of "g"(reen)');
is($rvar2, undef, 'radio button variable 2 is still undefined');
is($result, 'something:something', 'all SCALAR references changed correctly');

####################################
# test standard behaviour with 2 windows:

my ($w1, $w2);
$text2 = UI::Various::Text->new(text => 'Bye!');
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
