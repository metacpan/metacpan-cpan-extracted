#
# Let's see an interactive application,
# the macro panel of the Editor
# program.
#
# It may be used to :
#    - debug (requests on data followed
#      by a display : to be in an editor
#      can sometimes be helpful)
#    - learn the interface of the Text::Editor::Easy
#      module interactively
#    - develop or extend the Editor program itself
#      (part of the future standard menu or part
#      of your own one...)
#    - execute a very specific request...
#    - debug (Don't tell me !)
#
# Be careful, this demo (and the
# following ones) can't be executed
# alone as an autonomous program
# (you have to be in the Editor program)
#
# Pressing F5 will clean the "macro panel"
# and will insert macro instructions
# to be executed (at the bottom)
#
# As the "macro panel" is sensible to "change"
# event, the macro instructions
# will be automatically executed.
#
# The execution of these macro instructions
# will display results in the "Eval_out" panel
# (= standard out of macro processing) :
# on the middle right panel
#
# The actions of the macro instructions
# modify the 'call_stack' Text::Editor::Easy object
# which is the bottom right panel
#
# Once F5 has been pressed, you can
# modify the macro-instructions.
# The execution will follow after any modification.
#
# Now, you can try any perl code insertion
# and see in "real time" the execution of
# the code. Well, this maybe dangerous is
# only for responsible users.
#

{
    'F5' => sub {
        my ( $editor, $info_ref ) = @_;
        
        my $macro = Text::Editor::Easy->whose_name('macro');
        $macro->empty;
        $macro->insert( $info_ref->{'macro'} );
    },
    
    'macro' => << 'macro'
my $editor = Text::Editor::Easy->whose_name('call_stack');
$editor->empty;
$editor->deselect;
my @lines = $editor->insert("Hello world !\nIs there anybody ? body dy dy y ...");
print "\nWritten lines :\n\t", join ("\n\t", @lines), "\n";
$editor->insert ("\n\n\n\n" . $lines[0]->text);
my $next = $lines[0]->next;
print "\nNEXT LINE =\n\n", $next->text;
$next->select;
macro
    ,
}