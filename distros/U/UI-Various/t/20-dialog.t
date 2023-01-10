# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 20-dialog.t".
#
# Without "Build" file it could be called with "perl -I../lib 20-dialog.t"
# or "perl -Ilib t/20-dialog.t".  This is also the command needed to find
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

use Test::More tests => 27;
use Test::Output;

# define fixed environment for unit tests:
BEGIN { delete $ENV{DISPLAY}; delete $ENV{UI}; }

use UI::Various({use => [], include => [qw(Main Text Button Dialog Window)]});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/call_with_stdin.pl');

#########################################################################
# minimal dummy classes needed for unit tests:
package Dummy
{   sub new { my $self = {}; bless $self, 'Dummy'; }   };
package UI::Various::Box
{
    use UI::Various::widget;
    our @ISA = qw(UI::Various::container UI::Various::PoorTerm::base);
    sub _show() {}
    sub _self_destruct($) { my ($self) = @_; $self->parent()->remove($self); }
};
package UI::Various::PoorTerm::Box
{   use UI::Various::widget; our @ISA = qw(UI::Various::Box);   };

#########################################################################
# identical parts of messages and some basic building blocks:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;
my $standard_output = join("\n",
			   '========== hello',
			   '    Hello World!',
			   '<1> [ OK ]',
			   '<0> leave dialogue',
			   '',
			   '----- enter number to choose next step: ');

my $main = UI::Various::Main->new(width => 66); # 66 ~ 5 " Hello World,"
my $text = UI::Various::Text->new(text => 'Hello World!');
my $button = UI::Various::Button->new(text => 'OK',
				      code => sub { print "OK!\n"; });

####################################
# test standard behaviour:

$_ = UI::Various::Dialog->new(title => 'hello');
is($_->title(), 'hello', 'constructor sets title');
ok(10 < $_->max_width(), 'maximum screen width > 10: ' . $_->max_width());
ok(10 < $_->max_height(), 'maximum screen height > 10: ' . $_->max_height());

$_->add($text);
$_->add($button);

stdout_is(sub {   $_->_show();   }, $standard_output,
	  '_show 1 prints correct text');

my $selection = "1\n2\nx\n+\n-\n0\n";
my $standard_output1 =
    $standard_output . "1\n" .
    "OK!\n" .
    $standard_output . "2\n" .
    "invalid selection\n" .
    $standard_output . "x\n" .
    "invalid selection\n" .
    $standard_output . "+\n" .
    "invalid selection\n" .
    $standard_output . "-\n" .
    "invalid selection\n" .
    $standard_output . "0\n";
combined_is
{   _call_with_stdin($selection, sub { $_->_process(); });   }
    $standard_output1,
    '_process 1a prints correct text';

####################################
# test destruction:

eval {   $_ = UI::Various::Dialog::destroy($_);   };
like($@,
     qr/^specified implementation missing$re_msg_tail/,
     'bad access of general destroy should fail');

$_->destroy();
combined_is
{   _call_with_stdin($selection, sub { $_->_process(); });   }
    '',
    '_process 1b correctly aborts after destroy';
is($text->parent(), undef, 'text is now an orphan');
is($button->parent(), undef, 'button is now an orphan');
is($_->parent(), undef, 'dialogue has been correctly removed');
is(@{$main->{children}}, 0, 'main no longer has children');

####################################
# test destruction variants:

my $box = UI::Various::Box->new();
my $standard_output2 = join("\n",
			    '========== ',
			    '<1> [ OK ]',
			    '<0> leave dialogue',
			    '',
			    '----- enter number to choose next step: ');
$_ = $main->dialog($box, $button);
is($_->parent(), $main, 'dialogue is child of main');
is($_->title(), '', 'empty constructor creates empty title');
is($box->parent(), $_, 'box has been correctly added');
stdout_is(sub {   $_->_show();   },
	  $standard_output2,
	  '_show 2 prints correct text');
$_->destroy();
stdout_is
{   _call_with_stdin("1\n", sub { $_->_process(); });   }
    '',
    '_process 2 correctly aborts after destroy';
is($box->parent(), undef, 'box has been correctly removed');

####################################
# test "one-liner" creation:

$_ = $main->dialog({title => 'hello'}, $text, $button);
stdout_is(sub {   $_->_show();   }, $standard_output,
	  '_show 3 prints correct text');
$_->_self_destruct();		# quickest clean-up for unit test

# again without usage for full code coverage:
$_ = $main->dialog({title => 'hello'}, $text, $button);
$_->_self_destruct();		# quickest clean-up for unit test

####################################
# test wrapping:

my $standard_output4 = join("\n",
			    '========== HI',
			    '    ' . ' Hello World,' x 5,
			    '     Hello World!',
			    '< 1> [ OK ]',
			    '< 2> [ OK ]',
			    '< 3> [ OK ]',
			    '< 4> [ OK ]',
			    '< 5> [ OK ]',
			    '< 6> [ OK ]',
			    '< 7> [ OK ]',
			    '< 8> [ OK ]',
			    '< 9> [ OK ]',
			    '<10> [ OK ]',
			    '< 0> leave dialogue',
			    '',
			    '----- enter number to choose next step: ');

my $text4 = UI::Various::Text->new(text =>
				   'Hello World, ' x 5 . 'Hello World!');
# We need 10 different buttons as each needs its own parent pointer:
my @buttons4 =
    map { $_ = UI::Various::Button->new(text => 'OK'); }
    (1..10);
$_ = $main->dialog({title => 'HI'}, $text4, @buttons4);
stdout_is(sub {   $_->_show();   }, $standard_output4,
	  '_show 4 prints correct text');
$_->_self_destruct();		# quickest clean-up for unit test

####################################
# test mainloop:

is(@{$main->{children}}, 0, 'main is still clean');

my $button5 = UI::Various::Button->new(text => 'Quit');
my $dialog = $main->dialog({title => 'hello'}, $text, $button, $button5);
$button5->code(sub { $dialog->destroy(); });

my $standard_output5 = join("\n",
			    '========== hello',
			    '    Hello World!',
			    '<1> [ OK ]',
			    '<2> [ Quit ]',
			    '<0> leave dialogue',
			    '',
			    '----- enter number to choose next step: ');

stdout_is(sub {   $dialog->_show();   }, $standard_output5,
	  '_show 5 prints correct text');
stdout_is
{   _call_with_stdin("1\n2\n", sub { $main->mainloop; });   }
    $standard_output5 . "1\nOK!\n" . $standard_output5 . "2\n",
    'mainloop runs correctly';

####################################
# window and dialogue:

is(@{$main->{children}}, 0, 'main is clean again');

my $button6d = UI::Various::Button->new(text => 'Close',
					code => sub { $_[0]->destroy; });
my $text6w = UI::Various::Text->new(text => 'Hello Window!');
my $button6w1 =
    UI::Various::Button->new(text => 'Dialogue',
			     code => sub {
				 $main->dialog({title => 'D in W'},
					       $text, $button, $button6d);
			     });
my $button6w2 =
    UI::Various::Button->new(text => 'Quit',
			     code => sub { $_[0]->destroy(); });
$main->window({title => 'W'}, $text6w, $button6w1, $button6w2);

my $standard_output6d = join("\n",
			     '========== D in W',
			     '    Hello World!',
			     '<1> [ OK ]',
			     '<2> [ Close ]',
			     '<0> leave dialogue',
			     '',
			     '----- enter number to choose next step: ');
my $standard_output6w = join("\n",
			     '========== W',
			     '    Hello Window!',
			     '<1> [ Dialogue ]',
			     '<2> [ Quit ]',
			     '<0> leave window',
			     '',
			     '----- enter number to choose next step: ');
#$main->mainloop;print"OK\n";exit;
stdout_is
{   _call_with_stdin("0\n1\n0\n1\n1\n2\n2\n", sub { $main->mainloop; });   }
    $standard_output6w . "0\n" .
    $standard_output6w . "1\n" .
    $standard_output6d . "0\n" .
    $standard_output6w . "1\n" .
    $standard_output6d . "1\n" . "OK!\n" .
    $standard_output6d . "2\n" .
    $standard_output6w . "2\n",
    'window plus dialogue is handled correctly';

####################################
# broken tests for $main->dialog():

combined_like
{   $main->dialog(Dummy->new());   }
    qr/^invalid parameter 'Dummy' in call to UI::.*::Main::dialog$re_msg_tail/,
    'wrong object 1 in dialog should fail';
combined_like
{   $main->dialog(UI::Various::Dialog->new());   }
    qr/^invalid object \(UI::.*::Dialog\) in call to .*::dialog$re_msg_tail/,
    'wrong object 2 in dialog should fail';
combined_like
{   $main->dialog(UI::Various::Window->new());   }
    qr/^invalid object \(UI::.*::Window\) in call to .*::dialog$re_msg_tail/,
    'wrong object 3 in dialog should fail';
