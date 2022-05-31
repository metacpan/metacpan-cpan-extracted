# Before "./Build install" is performed this script should be runnable with
# "./Build build && ./Build test".
#
# After "./Build install" it should work as "perl 32-tk-2.t".
#
# Without "Build" file it could be called with "perl -I../lib 32-tk-2.t"
# or "perl -Ilib t/32-tk-2.t".  This is also the command needed to find
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

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;

use Cwd 'abs_path';

use Test::More;
use Test::Output;

BEGIN {
    $ENV{DISPLAY}  or  plan skip_all => 'DISPLAY not found';
sleep 2;				# TODO: trying work-around for Xvfb
    eval { require Tk; };
diag('Tk has been initialised');	# TODO: temporary diagnostics
    $@  and  plan skip_all => 'Perl/Tk not found';
    plan tests => 9;

    # define fixed environment for unit tests:
    delete $ENV{UI};
}

sleep 2;				# TODO: trying work-around for Xvfb
use UI::Various({use => ['Tk']});
diag('V::UI::Tk has been initialised');	# TODO: temporary diagnostics
sleep 2;				# TODO: trying work-around for Xvfb

#########################################################################
# specific check for problematic configuration, is sub-test as the
# additional check otherwise might affect further tests in some Perl and/or
# Tk versions:
use constant T_PATH => map { s|/[^/]+$||; $_ } abs_path($0);
do(T_PATH . '/functions/sub_perl.pl');
$_ = _sub_perl('require Tk;
		$_ = MainWindow->new();
		$_->fontActual("", "-size");
		$_->destroy;');
if ($_)
{
    diag('Your ', $^O,
	 ' apparently has a strange font configuration (no default font?).',
	 '  This will hurt!');
}

####################################
# test variant two windows with either width or height, but not both:

my $main = UI::Various::Main->new();
my ($win1, $win2);
my $text1 = UI::Various::Text->new(text => 'Hello World!');
my $button2 = UI::Various::Button->new
    (text => 'Quit',
     code => sub{ $win1->destroy; $win2->destroy; });

my @text8 = ('1st entry', '2nd entry', '3rd entry', '4th entry',
	     '5th entry', '6th entry', '7th entry', '8th entry');
my $listbox0 = UI::Various::Listbox->new(texts => \@text8, height => 3,
					 selection => 0);
my $counter = 0;
my $listbox2 = UI::Various::Listbox->new(texts => \@text8, height => 3,
					 selection => 2,
					 on_select => sub {
					     $counter++;
					 });
my @selection = ();
my @counts = ();

my $ww2 = 0;
my $button1 = UI::Various::Button->new
    (text => 'Bye',
     code => sub {
	 $win2 =
	     $main->window({title => 'Bye!', width => 42},
			   UI::Various::Text->new(text => 'Goodbye World!'),
			   $button2);
	 $listbox2->_tk()->selectionSet(4);
	 $listbox2->_tk()->selectionSet(2);
	 $listbox2->_tk()->selectionSet(1);
	 $listbox2->add('last');
	 push @counts, scalar(@{$listbox2->texts});
	 $listbox2->remove(8);
	 push @counts, scalar(@{$listbox2->texts});
	 $ww2 = $win2->width;
	 @selection = $listbox2->selected();
	 $button2->_tk()->invoke;
     });
$win1 = $main->window({title => 'Hello', height => 12}, $text1, $button1);
is($win1->height, 12, '$win1 has correct fixed height');

is($win1->add($listbox0, $listbox2), 2, 'window has added 2 listboxes');

combined_like
{
    $main->_mainloop_prepare;
    $button1->_tk()->invoke;
    $main->_mainloop_run;
}
    qr{\A(?:^Devel::Cover: .*lib/Tk/Frame.pm .*\n)*\Z}m,
    'mainloop "2 windows" produces correct empty output';
is(@{$main->{children}}, 0, 'main again no longer has children');
is($ww2, 42, '$win2 had correct fixed width');
is($counts[0], 9, 'listbox has correct 1st count');
is($counts[1], 8, 'listbox has correct 2nd count');
is_deeply(\@selection, [1, 2, 4], 'listbox had correct final selection');
# We don't trigger the the event with selectionSet, so the counter is still 0:
is($counter, 0, 'counter has correct value');
