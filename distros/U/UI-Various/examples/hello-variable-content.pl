#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_";

#########################################################################
# "Hello World!" example using two windows (of fixed size), where the first
# one can be used to configure the content of the second one:

my $main = UI::Various::Main->new();

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my ($window1, $window2);	# must be declared before the subs using them!

my $text = 'Hello World!';
$window1 =
    $main->window({title => 'Configuration', width => 30, height => 6},
		  UI::Various::Input->new(textvar => \$text),
		  UI::Various::Button->new
		  (text => 'Close',
		   code => sub{   $window1->destroy;   $window1 = undef;   }
		  ));
$window2 =
    $main->window({title => 'Hello', width => 30, height => 6},
		  UI::Various::Text->new(text => \$text),
		  UI::Various::Button->new
		  (text => 'Quit',
		   code => sub{
		       $window1  and  $window1->destroy;
		       $window2->destroy;
		   }));

$main->mainloop;
