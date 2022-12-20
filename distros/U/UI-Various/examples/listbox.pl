#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# Example using a listbox with multiple selection:

my $main = UI::Various::Main->new();
my @list = ();
my $next_id = 1;
foreach (1..8)
{
    push @list, 'entry #' . $next_id++;
}
my $counter = 0;
my $listbox = UI::Various::Listbox->new(texts => \@list, height => 5,
					on_select => sub { $counter++; });

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my $window;			# must be declared before the sub using it!
$window =
    $main->window({title => 'Listbox', width => 20, height => 12},
		  $listbox,
		  UI::Various::Button->new
		  (text => 'Add Entry',
		   code => sub{   $listbox->add('entry #' . $next_id++);   }),
		  UI::Various::Button->new
		  (text => 'Remove 2nd',
		   code => sub{   $listbox->remove(1);   }),
		  UI::Various::Button->new
		  (text => 'Quit',
		   code => sub{
		       local $_;
		       # Note that Curses needs "\r\n":
		       print STDERR "Selection (after $counter changes):\r\n";
		       print STDERR "\t$_\t$list[$_]\r\n"
			   foreach $listbox->selected;
		       $window->destroy;
		   }));
$main->mainloop;

#########################################################################
# Trick to see previously stored standard error output even when Curses
# clears the screen at the very end of program (and not at the end of the
# main event-loop, note that this seems to be nondeterministic depending on
# errors occurring):
END {
    if (UI::Various::using() eq 'Curses'  and  ($? != 0  or  $@))
    {
	print STDERR "\r\n waiting 10 seconds before screen is cleared\r\n";
	sleep 10;
    }
}
