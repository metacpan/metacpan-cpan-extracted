#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# example for the 9 different values of align:

my $title_text =
    #         1         2         3         4         5         6
    #12345678901234567890123456789012345678901234567890123456789012
    'overview over alignments (UI::Various and Dungeons&Dragons ;-)';
my @text = ("7\nLG\nlawful good",
	    "8\nNG\nneutral good",
	    "9\nCG\nchaotic good",
	    "4\nLN\nlawful neutral",
	    "5\nN\n(true) neutral",
	    "6\nCN\nchaotic neutral",
	    "1\nLE\nlawful evil",
	    "2\nNE\nneutral evil",
	    "3\nCE\nchaotic evil");
my $main = UI::Various::Main->new();

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my @text_fields = ();
foreach (@text)
{
    push @text_fields, UI::Various::Text->new(text => $_,
					      height => 5,
					      width => 15,
					      align => substr($_, 0, 1));
}
my $box = UI::Various::Box->new(rows => 3, columns => 3, border => 1);
$box->add(@text_fields);
my $window;			# must be declared before the sub using it!
$window =
    $main->window({title => 'Overview Alignments', width => 51},
		  UI::Various::Text->new(text => $title_text,
					 width => 51),
		  $box,
		  UI::Various::Button->new(text => 'Quit',
					   height => 3,
					   width => 42,
					   align => 5,
					   code => sub{ $window->destroy; }));
$main->mainloop;
