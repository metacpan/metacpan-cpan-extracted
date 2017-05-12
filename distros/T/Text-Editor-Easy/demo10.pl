#
# Session management
#
# A time saving feature of an Editor is to be able
# to save configurations of opened file and to
# re-load this configuration later.
#
# As usual, press F5 to insert code in the macro panel
# This should remove demo 1 to 6 and
# should stop and restart the Editor in the same state.
#

{
    'F5' => sub {
        my ( $editor, $info_ref ) = @_;
        
        my $macro = Text::Editor::Easy->whose_name('macro');
        $macro->empty;
        $macro->insert( $info_ref->{'macro'} );
    },
    
    'macro' => << 'macro'
for my $demo ( 1 .. 6 ) {
    print "demo$demo.pl\n";
    Text::Editor::Easy->on_editor_destroy('zone1', "demo${demo}.pl");
}
Text::Editor::Easy->restart;
macro
    ,
}