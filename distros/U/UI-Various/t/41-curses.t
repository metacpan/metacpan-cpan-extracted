# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 41-curses.t".
#
# Without "Build" file it could be called with "perl -I../lib 41-curses.t"
# or "perl -Ilib t/41-curses.t".  This is also the command needed to find
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

use Test::More;
use Test::Output;

BEGIN {
    eval { require Curses::UI; };
    $@  and  plan skip_all => 'Curses::UI not found';
    plan tests => 58;

    # define fixed environment for unit tests:
    delete $ENV{DISPLAY};
    delete $ENV{UI};
}

use UI::Various({use => ['Curses']});

use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);

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
    $main = UI::Various::Main->new(width => 20, height => 15);
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
my $listbox0 = UI::Various::Listbox->new(texts => [], height => 5);
my @options = ([a => 1], [b => 2], [c => 3], 42);
my $optionmenu = UI::Various::Optionmenu->new(init => 2, options => \@options);
my $option2 = 0;
my $optionmenu2 = UI::Various::Optionmenu->new(options => \@options,
					       on_select => sub {
						   $option2 = $_[0];
					       });

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
stderr_like
{   $listbox0->_prepare(0, 0);   }
    qr/^UI::.*Curses::Listbox element must be accompanied by parent$re_msg_tail/,
    'orphaned Listbox causes error';
stderr_like
{   $optionmenu->_prepare(0, 0);   }
    qr/^.*Curses::Optionmenu element must be accompanied by parent$re_msg_tail/,
    'orphaned Optionmenu causes error';

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
				       width => 4,
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
    'mainloop 1 produces correct output';
is(@{$main->{children}}, 0, 'main 1 no longer has children');
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
is(@{$main->{children}}, 0, 'main 2 no longer has children');

####################################
# test standard behaviour with 1 + 3 boxes:
my @t = (UI::Various::Text->new(text =>  '1'),
	 UI::Various::Text->new(text =>  "2\n2"),
	 undef,
	 UI::Various::Text->new(text =>  '3'),

	 UI::Various::Text->new(text =>  '4'),
	 undef,
	 UI::Various::Text->new(text =>  '5'),
	 UI::Various::Text->new(text =>  '6'),

	 undef,
	 UI::Various::Text->new(text =>  '7'),
	 UI::Various::Text->new(text =>  "8\n8"),
	 undef);
$button1 = UI::Various::Button->new(text => 'Quit',
				    code => sub {   $w->destroy;   });
my $box1 = UI::Various::Box->new(rows => 2, columns => 2);
$box1->add($t[0], $t[1], 1, 1, $t[3]);
my $box2 = UI::Various::Box->new(rows => 2, columns => 2);
$box2->add($t[4], 1, $t[6], $t[7]);
my $box3 = UI::Various::Box->new(rows => 2, columns => 2,
				 width => 3, height => 4);
$box3->add(0, 1, $t[9], $t[10]);
my $box = UI::Various::Box->new(rows => 2, columns => 2);
$box->add($box1, $box2, $box3, $button1);
is(ref($box), 'UI::Various::Curses::Box',
   'type UI::Various::Curses::Box is correct');

$w = $main->window($box);

# same differences as above, difficult to test of the diverse platforms:
my $re_output = '(?:(?:\b[1-8]|[1-8]\b).*){10}';

@chars_to_read = (' ');
combined_like
{   $main->mainloop;   }
    qr/^.*$re_output/s,
    'mainloop 3 produces correct output';
is(@{$main->{children}}, 0, 'main 3 no longer has children');

####################################
# test standard behaviour with a multi-selection listbox:
my @list = (1..4);
my $next = 5;
my $counter = 0;
my $listbox = UI::Various::Listbox->new(texts => \@list, height => 5,
					on_select => sub { $counter++; });
my @selected = ();
$w =  $main->window($listbox,
		    UI::Various::Button->new
		    (text => 'Add Entry',
		     code => sub{   $listbox->add($next++);   }),
		    UI::Various::Button->new
		    (text => 'Remove #3',
		     code => sub{   $listbox->remove(2);   }),
		    UI::Various::Button->new
		    (text => 'Quit',
		     code => sub{
			 @selected = $listbox->selected();
			 $w->destroy;
		     }));

@chars_to_read = (' ',			# select #1
		  'j', 'j', ' ',	# go to #3 and select it
		  "\t",  ' ', ' ',	# go to ADD and add 2 more
		  "\t", "\t", "\t",	# go back to listbox
		  'j', 'j', ' ',	# go to #5 and select it
		  'j', ' ',		# go to #6 and select it
		  "\t", "\t", ' ', ' ',	# go to REMOVE #3 and do it 2 times
		  "\t", ' ');		# quit
combined_like
{   $main->mainloop;   }
    qr/^.*Add Entry.*Remove #3.*Quit\b.*$/s,
    'mainloop 4 produces correct output';
is_deeply(\@selected, [0, 2, 3], 'listbox had correct final selection');
is(@{$main->{children}}, 0, 'main 4 no longer has children');
is($counter, 4, 'counter has correct value');

####################################
# test standard behaviour with a single-selection listbox:
$listbox = UI::Various::Listbox->new(texts => [1..5], height => 5,
				     selection => 1);
my ($selected1, $selected2, $texts1, $texts2) = (-1, -1, -1, -1);
$w =  $main->window($listbox,
		    UI::Various::Button->new
		    (text => 'Remove #5',
		     code => sub{   $listbox->remove(4);   }),
		    UI::Various::Button->new
		    (text => 'Quit',
		     code => sub{
			 $selected1 = $listbox->selected();
			 $texts1 = @{$listbox->texts};
			 $listbox->replace(3, 2, 1);
			 $selected2 = $listbox->selected();
			 $texts2 = @{$listbox->texts};
			 $w->destroy;
		     }));

@chars_to_read = ('j', ' ',		# go to #2 and select it
		  'j', ' ',		# go to #3 and select it
		  "\t", ' ',		# go to REMOVE #5 and do it
		  "\t", ' ');		# quit
combined_like
{   $main->mainloop;   }
    qr/^.*Quit\b.*$/s,
    'mainloop 5 produces correct output';
is($selected1, 2, '2nd listbox had correct final selection');
is($texts1, 4, '2nd listbox had correct number of elements');
is($selected2, undef, "listbox's replace also removes selection");
is($texts2, 3, 'entries of listbox have been replaced');
is(@{$main->{children}}, 0, 'main 5 no longer has children');

####################################
# test standard behaviour of a dialogue:

$text1 = UI::Various::Text->new(text => 'Dialogue!');
my $run_dialog = 0;
$button1 =
    UI::Various::Button->new(text => 'Back',
			     code => sub {
				 $_[0]->destroy;
				 $run_dialog++;
			     });
my $text = 'Window!';		# We need a referenced item outside of dialogue.
$text2 = UI::Various::Text->new(text => \$text);
$button2 =
    UI::Various::Button->new(text => 'Dialogue',
			     code => sub {
				 $main->dialog({title => 'DIA',
						width => 12,
						height => 5},
					       $text1, $button1); });
my $button3 = UI::Various::Button->new(text => 'Quit',
				       code => sub {   $w->destroy;   });
$w = $main->window({title => 'WIN', width => 20}, $text1, $button2, $button3);

@chars_to_read = (' ',			# select button 2 in WIN
		  ' ',			# select button in DIA
		  "\t", ' ');		# select button 3 in WIN
combined_like
{   $main->mainloop;   }
    # Note that we can apparently only match some parts of the window here:
    qr/^.*\bDialogue!.*\bWIN\b.*Dialogue\b.*Quit\b.*/s,
    'mainloop 6 produces correct output';
is($run_dialog, 1, 'dialogue did run');
is(@{$main->{children}}, 0, 'main 6 no longer has children');

####################################
# test standard behaviour with the 1st optionmenu:
my $option = -1;
$w =  $main->window($optionmenu,
		    UI::Various::Button->new
		    (text => 'Quit',
		     code => sub{
			 $option = $optionmenu->selected();
			 $w->destroy;
		     }));

@chars_to_read = (' ',			# select Optionmenu
		  'j', 'j', ' ',	# go from #2 (init) to #4 and select it
		  "\t", ' ');		# quit
combined_like
{   $main->mainloop;   }
    qr/^.*Quit\b.*$/s,
    'mainloop 7 produces correct output';
is($option, 42, '1st optionmenu had correct final selection');
is(@{$main->{children}}, 0, 'main 7 no longer has children');

####################################
# test standard behaviour with the 2nd optionmenu:
$option = -1;
$w =  $main->window($optionmenu2,
		    UI::Various::Button->new
		    (text => 'Quit',
		     code => sub{
			 $option = $optionmenu2->selected();
			 $w->destroy;
		     }));

@chars_to_read = (' ',			# select Optionmenu
		  'j', 'j', ' ',	# go to #3 and select it
		  "\t", ' ');		# quit
combined_like
{   $main->mainloop;   }
    qr/^.*Quit\b.*$/s,
    'mainloop 8 produces correct output';
is($option, 3, '2nd optionmenu had correct final selection');
is($option2, 3, '2nd optionmenu run its on_select');
is(@{$main->{children}}, 0, 'main 8 no longer has children');

####################################
# test selection of single output file (selecting it):
my $fs =
    UI::Various::Compound::FileSelect->new
    (mode => 0,
     filter => [['PL scripts' => '\.pl$']],
     directory => T_PATH);
($selected1, $selected2) = ('', '');
$w =  $main->window($fs,
		    UI::Various::Button->new
		    (text => 'Quit',
		     code => sub{
			 $selected1 = $fs->selection();
			 $selected2 = $fs->{_widget}{input}->textvar;
			 $w->destroy;
		     }));
@chars_to_read = ("\t", "\t", ' ',	# select sub-directory
		  ' ',			# select 1st file
		  "\t", "\t", ' ');	# quit
combined_like
{   $main->mainloop;   }
    qr/^.*functions\b.*$/s,
    'mainloop 9 produces correct output';
like($selected1, qr'/t/functions/[a-z_]+\.pl$',
     'file selection returned correct file');
like($selected1, qr"/t/functions/$selected2", 'file selection is consistent');
is(@{$main->{children}}, 0, 'main 9 no longer has children');

####################################
# test unused behaviour (and get 100% coverage):

$w1 = UI::Various::Window->new(title => 'hello');
$w2 = UI::Various::Window->new(title => 'dummy 1');
my $d1 = UI::Various::Dialog->new(title => 'dummy 2', height => 2);
my $d2 = $main->dialog({title => 'dummy 3', height => 3},
		       UI::Various::Button->new(text => "multi\n line"));
is(@{$main->{children}}, 4, 'main has new children');
$d2->_prepare;
is($w1->title(), 'hello', 'window constructor sets title');
$w1->add($text1);
is(@{$w1->{children}}, 1, 'Window has 1 child');
$w1->destroy();
$w2->destroy();
$d1->destroy();
$d2->destroy();
is(@{$main->{children}}, 0, 'main is clean again');

$main->mainloop();		# an additional empty call just for the coverage
