#!/usr/bin/perl

# see README.md for documentation and license

# These 3 lines of code handle the UI selection and set-up.  They are not
# needed for a real program.  Their intent is to make it easier to try out
# the example with the different possible UIs:
($_ = $0) =~ s|[^/]+$|_common.pl|;
m|^/|  or  $_ = './' . $_;
do "$_"  or  exit;

#########################################################################
# "Hello World!" example using a window and a dialogue.  The dialogue
# contains all existing basic UI elements, which are used to configure the
# content of the window:

my $main = UI::Various::Main->new();

my ($use1, $use2, $mrs, $text1, $text2) = (0, 42, 0, '', 'World');
sub text()
{
    local $_;
    $_  = 'Hello '
	. ($mrs == 0 ? '' : $mrs == 1 ? 'Mr. ' : 'Mrs. ')
	. ($use1 ? $text1 . ' ' : '')
	. ($use2 ? $text2       : '');
    s/ *$/!/;
    return $_;
}
$text = text();

my $window;			# must be declared before the subs using it!

# Note that after destruction the dialog can only be reused by completely
# rebuilding it, as it otherwise looses its content.
sub configuration_dialog()
{
    my $dialog_box = UI::Various::Box->new(border => 1, rows => 3, columns => 2);
    $dialog_box->add(UI::Various::Radio->new(buttons => [0 => '<empty>',
							 1 => 'Mr.',
							 2 => 'Mrs.'],
					     var => \$mrs),
		     1,
		     UI::Various::Check->new(text => 'use forename',
					     var => \$use1),
		     UI::Various::Input->new(textvar => \$text1),
		     UI::Various::Check->new(text => 'use name',
					     var => \$use2),
		     UI::Various::Input->new(textvar => \$text2));
    # Note that simply closing the dialogue with the closing button of the
    # window's decoration (Tk) or the '<0>' selection of *Term does not
    # update the text of the window!
    my $dialog_button = UI::Various::Button->new(text => 'Update & Close',
						 code => sub{
						     $_[0]->destroy;
						     $text = text();
						 });
    $main->dialog({title => 'Configuration',
		   width => 60,
		   height => 16},
		  $dialog_box,
		  $dialog_button);
}

# When the UI is Curses::UI, using print(f)/say/... between here and the
# return of $main->mainloop will (usually) not be visible, but may
# completely garble your output (by moving the cursor)!

$window =
    $main->window({title => 'Hello', width => 30, height => 6},
		  UI::Various::Text->new(text => \$text),
		  UI::Various::Button->new
		  (text => 'Configure',
		   code => sub{   configuration_dialog();   }),
		  UI::Various::Button->new
		  (text => 'Quit',
		   code => sub{   $_[0]->destroy;   }));

$main->mainloop;
