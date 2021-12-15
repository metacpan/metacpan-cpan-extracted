#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_";

#########################################################################
# "Hello World!" example:

my $main = UI::Various::Main->new();

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my $window;			# must be declared before the sub using it!
$window =
    $main->window({title => 'Hello'},
		  UI::Various::Text->new(text => 'Hello World!'),
		  UI::Various::Button->new(text => 'Quit',
					   code => sub{ $window->destroy; }));
$main->mainloop;
