#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# Example using a listbox with single selection and buttons to add / remove
# items with improved (boxed) layout:

my $main = UI::Various::Main->new();
my @list = ();
my $next_id = 1;
foreach (1..4)
{
    push @list, 'entry #' . $next_id++;
}
my $listbox = UI::Various::Listbox->new(texts => \@list,
					height => 10,
					width => 10,
					selection => 1);

my $del = UI::Various::Button->new(text => ' - ',
				   width => 3,
				   code => sub{
				       local $_ = $listbox->selected();
				       defined $_  and  $listbox->remove($_);
				   });
my $add = UI::Various::Button->new(text => ' + ',
				   width => 3,
				   code => sub{
				       $listbox->add('entry #' . $next_id++);
				   });
my $buttons = UI::Various::Box->new(columns => 2);
$buttons->add($del, $add);

my $boxed_lb = UI::Various::Box->new(border => 1, rows => 2);
$boxed_lb->add($listbox, $buttons);

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

$main->window({title => 'Listbox', width => 18, height => 19},
	      $boxed_lb,
	      UI::Various::Button->new(text => 'Quit',
				       code => sub{   $_[0]->destroy;   }));
$main->mainloop;

#########################################################################
# Trick to see previously stored standard error output even when Curses
# clears the screen at the very end of program (and not at the end of the
# main event-loop, note that this seems to be nondeterministic depending on
# errors occurring):
END {
    print join("\n", @list, '');
    if (UI::Various::using() eq 'Curses'  and  ($? != 0  or  $@))
    {
	print STDERR "\r\n waiting 10 seconds before screen is cleared\r\n";
	sleep 10;
    }
}
