#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# "Hello World!" example using two windows (of fixed size) and creating the
# first window element by element:

my $main = UI::Various::Main->new();

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my ($window1, $window2);	# must be declared before the subs using them!
my $text1 = UI::Various::Text->new(text => 'Hello World!');
my $button1 = UI::Various::Button->new
    (text => 'Goodbye ...',
     code => sub{
	 $window2  or
	     $window2 =
	     $main->window({title => 'Bye!', width => 30, height => 6},
			   UI::Various::Text->new(text => 'Goodbye World!'),
			   UI::Various::Button->new
			   (text => 'Quit',
			    code => sub{ $window1->destroy; $window2->destroy; }
			   ));
     });
$window1 = UI::Various::Window->new(title => 'Hello', width => 30, height => 6);
$window1->add($text1);
$window1->add($button1);

$main->mainloop;
