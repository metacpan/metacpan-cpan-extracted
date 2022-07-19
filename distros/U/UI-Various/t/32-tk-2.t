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
    eval { require Tk; };
    $@  and  plan skip_all => 'Perl/Tk not found';
    plan tests => 10;

    # define fixed environment for unit tests:
    delete $ENV{UI};
}

use UI::Various({use => ['Tk']});
diag('UI::Various::Tk has been initialised');	# TODO: temporary diagnostics

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
# TODO: temporary check for specific CPAN smoker:
if ($ENV{DISPLAY} =~ m/:121$/)
{
    diag 'extended check for DISPLAY == ', $ENV{DISPLAY};
    diag 'TK has version ', $Tk::VERSION;
    my ($countdown, $pid) = (10, 0);
    while (--$countdown > 0)
    {
	sleep 7  if $countdown < 10;
	open my $ps, '-|', 'ps', 'auxww'  or  die "can't PS: $!\n";
	my $found = 0;
	while (<$ps>)
	{
	    next unless m/[X][a-z].* :121\b/;
	    m/^[^ ]+\s+(\d+).*/  and  $pid = $1;
	    $found++;
	}
	close $ps;
	last if $found > 0;
	diag 'X server not yet running - ', $countdown;
    }
    if ($countdown > 0)
    {   diag 'X server seems to be running with PID ', $pid;   }
    else
    {   diag 'no X server - we will fail';   }
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
	 $listbox2->replace(1, 2, 3, 4);
	 push @counts, scalar(@{$listbox2->texts});
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
is($counts[2], 4, 'listbox has correct 3rd count');
# We don't trigger the the event with selectionSet, so the counter is still 0:
is($counter, 0, 'counter has correct value');
