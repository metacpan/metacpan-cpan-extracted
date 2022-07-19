#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# Example showing the 3 types of file-selection widgets:
my @title = ('select output file', 'select input file', 'select input files');

my $main = UI::Various::Main->new(height => 20, width => 60);

# Note that after destruction the dialog can only be reused by completely
# rebuilding it, as it otherwise looses its content.
sub fs_dialog($)
{
    my ($mode) = @_;
    my $fs =
        UI::Various::Compound::FileSelect->new(
            mode => $mode,
            directory => $ENV{HOME},
            filter => [['all files' => '.+'], ['Perl scripts' => '\.pl$']],
            height => 12,
            width => 40);
    my $buttons = UI::Various::Box->new(columns => 2);
    $buttons->add(UI::Various::Button->new(text => 'Cancel',
					   code => sub{
					       $_[0]->destroy;
					   }),
		  UI::Various::Button->new(text => 'OK',
					   code => sub{
					       # Note that Curses needs "\r\n":
					       print(STDERR
						     join("\r\n\t", 'SELECTED:',
							  $fs->selection()),
						     "\r\n");
					       $_[0]->destroy;
					   }));
    $main->dialog({title => $title[$mode]}, $fs, $buttons);
}

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my $window;			# must be declared before the sub using it!
$window =
    $main->window({title => 'Hello'},
		  UI::Various::Button->new(text => $title[0],
					   code => sub{ fs_dialog(0); }),
		  UI::Various::Button->new(text => $title[1],
					   code => sub{ fs_dialog(1); }),
		  UI::Various::Button->new(text => $title[2],
					   code => sub{ fs_dialog(2); }),
		  UI::Various::Button->new(text => 'Quit',
					   code => sub{ exit; }));
$main->mainloop;

# Trick to see previously stored standard error output even when Curses
# clears the screen at the very end of program:
END {
    if (UI::Various::using() eq 'Curses')
    {
	print STDERR "\r\n waiting 10 seconds before screen is cleared\r\n";
	sleep 10;
    }
}
