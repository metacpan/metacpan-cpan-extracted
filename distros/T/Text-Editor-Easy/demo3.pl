#
# Here is an example of
# Text::Editor::Easy object creation with
# a way to make actions on it
# (a new "client thread" have been
# created to execute your sub).
#
# The first argument of the sub is
# the newly created Text::Editor::Easy object.
#
# "Text::Editor::Easy->manage_event" is called
# internally (by the initial thread).
#
# To execute it, still press F5 and
# wait a few seconds for actions
# to be performed...
#

use strict;
use lib 'lib';

use Text::Editor::Easy;

my $editor_thread_0 = Text::Editor::Easy->new(
    {
        'sub'      => 'main',    # Sub for action
    }
);

print "The user have closed the window\n";
if ( -f "Uninteresting_data.txt" ) {
    print "File \"Uninteresting_data.txt\" will be removed\n";
    $editor_thread_0->close;
    if ( !unlink("Uninteresting_data.txt") ) {
        print "Can't remove file \"Uninteresting_data.txt\" : $!\n";
    }
}

sub main {
    my ($editor) = @_;

    # You can now act on the Text::Editor::Easy object with your program and
    # the user can edit things too !
    # Dangerous, isn't it ?

    $editor->focus;    # To see the cursor position, not mandatory
    $editor->insert("\$editor = $editor\n");
    $editor->insert("Second line if user is slower than me\n");
    $editor->insert("\nother line ...\n\nother line");

    my $line = $editor->number(4);
    $line->select( 1, 5 );
    sleep 1;

    $editor->cursor->set( 3, $line );
    $editor->deselect;
    sleep 1;

    $editor->insert( $line->text . " : copied\n" );
    sleep 1;

    $editor->erase(3);
    $editor->save("Uninteresting_data.txt");
}