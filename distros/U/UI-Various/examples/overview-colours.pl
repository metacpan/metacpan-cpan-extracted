#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# "Hello World!" example:

BEGIN {
    $DB::single = 1;
}
my $main = UI::Various::Main->new();

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

my @text_fields = ();
foreach ('RED', 'Ff8000', 'YEllOW', 'GREEN', 'Cyan', 'BLUE',#'8080ff')
	 'magenta')
{
    push @text_fields, UI::Various::Text->new(text => 'Hello ' . $_ . '!',
					      width => 16,
					      fg => 'black', bg => $_);
}
my $inner_box = UI::Various::Box->new(rows => 9, bg => '404040');
$inner_box->add(UI::Various::Text->new(text => 'Hello Rainbow!', width => 20,
				       fg => 'white', bg => 'black'),
		@text_fields,
		UI::Various::Text->new(text => 'Hello Rainbow!',
				       fg => 'white', bg => 'black'));
my $outer_box =
    UI::Various::Box->new(rows => 3, border => 1,
			  fg => 'white', bg => '808080');
$outer_box->add($inner_box,
		UI::Various::Button->new(text => 'Exit',
					 fg => 'black', bg => 'c0c0ff',
					 code => sub{ $_[0]->destroy; }),
		UI::Various::Button->new(text => 'Quit',
					 fg => '008000', bg => 'white',
					 code => sub{ $_[0]->destroy; }));
$main->window({title => 'Hello', fg => 'white', bg => 'black'},
	      $outer_box);
$main->mainloop;
