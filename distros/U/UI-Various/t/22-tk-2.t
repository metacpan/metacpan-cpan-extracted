# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 22-tk.t".
#
# Without "Build" file it could be called with "perl -I../lib 22-tk.t"
# or "perl -Ilib t/22-tk.t".  This is also the command needed to find
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

use v5.14.0;
use strictures;
no indirect 'fatal';
no multidimensional;

use Test::More;
use Test::Output;

BEGIN {
    $ENV{DISPLAY}  or  plan skip_all => 'DISPLAY not found';
    eval { require Tk; };
    $@  and  plan skip_all => 'Perl/Tk not found';
    plan tests => 7;

    # define fixed environment for unit tests:
    delete $ENV{UI};
}

use UI::Various({use => ['Tk']});

#########################################################################
# identical parts of messages:
my $re_msg_tail = qr/ at $0 line \d{2,}\.?$/;

####################################
# test variant two windows with either width or height, but not both:

my $main = UI::Various::Main->new();
my ($win1, $win2);
my $text1 = UI::Various::Text->new(text => 'Hello World!');
my $button2 = UI::Various::Button->new
    (text => 'Quit',
     code => sub{ $win1->destroy; $win2->destroy; });
my $button1 = UI::Various::Button->new
    (text => 'Bye',
     code => sub {
	 $win2 =
	     $main->window({title => 'Bye!', width => 42},
			   UI::Various::Text->new(text => 'Goodbye World!'),
			   $button2);
	 $_ = $win2->width;
	 $button2->_tk()->invoke;
     });
$win1 = $main->window({title => 'Hello', height => 12}, $text1, $button1);
is($win1->height, 12, '$win1 has correct fixed height');
combined_is
{
    $main->_mainloop_prepare;
    $button1->_tk()->invoke;
    $main->_mainloop_run;
}
    '', 'mainloop produces correct empty output';
is(@{$main->{children}}, 0, 'main again no longer has children');
is($_, 42, '$win2 had correct fixed width');

####################################
# test unused behaviour (and get 100% coverage):

$_ = UI::Various::Window->new(title => 'hello');
is(@{$main->{children}}, 1, 'main has new child');
is($_->title(), 'hello', 'window constructor sets title');
$_->destroy();
is(@{$main->{children}}, 0, 'main is clean again');

$main->mainloop();		# an additional empty call just for the coverage
