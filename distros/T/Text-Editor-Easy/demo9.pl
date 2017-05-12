#
# What about an interactive test of perl regexp ?
#
# Search implementation is not yet finished, but here is an other possibility
# of what a perl Editor could be used to. Interactive tutorials are a more
# friendly way to learn than a text file. If there are more funny ways to learn
# perl, maybe there will be more perl programmers and less wasted time
# to learn other inefficient langages !
# 
# As usual, press F5 to insert search code in the macro panel
# You can then press the arrows "Up" or "Down" to navigate into
# the different expressions to be searched.
# You can also put your own expression in the second line of the macro
# instructions.
# 
# You'll notice that, for the $exp variable, you can put a string for an
# exact match (not a regular expression search) or a regexp with the perl
# syntax : qr/regexp/modifiers
#

{
    'F5' => sub {
        my ( $editor, $info_ref ) = @_;
        
        $editor->bind_key({ 
            'sub_ref' => $info_ref->{'up_key'},
            'key' => 'Up'
        } );
        $editor->bind_key({ 
            'sub_ref' => $info_ref->{'down_key'},
            'key' => 'Down'
        } );
        
        my $stack_ed = Text::Editor::Easy->whose_name('call_stack');
        $stack_ed->empty;
        my @exp = ( 
            'qr/e.+s/', 
            'qr/e.+?s/', 
            '\'is\'', 
            'qr/\\bis\\b/', 
            'qr/F.*n/', 
            'qr/F.*n/i', 
            'qr/f[er]+[^e]+/'
        );
        my $exp = undef;
        for ( @exp ) {
            $exp .= "$_\n";
        }
        chomp $exp;
        $stack_ed->insert( $exp );
        my $first = $stack_ed->number(1);
        $first->select;
        $stack_ed->cursor->set( 0, $first);
        
        my $macro = Text::Editor::Easy->whose_name('macro');
        $macro->empty;
        $macro->insert( $info_ref->{'macro'} );
    },
    
    'macro' => << 'macro'
my $editor = Text::Editor::Easy->whose_name('demo9.pl');
my $exp = qr/e.+s/;
my ( $line, $start, $end, $regexp ) = $editor->search($exp);
$editor->deselect;
return if ( ! defined $line );
$line->select($start, $end);
$editor->visual_search( $regexp, $line, $end);
macro
    ,
    
    'up_key' => sub {
        my $editor = Editor->whose_name('call_stack');
        
        my ( $line ) = $editor->cursor->get;
        #print "Dans up_demo9 : trouvé $line | ", $line->text, "\n";
        if ( my $previous = $line->previous ) {
            $editor->deselect;
            my $exp = $previous->select;
            $editor->cursor->set(0, $previous);
            my $macro_ed = Editor->whose_name('macro');
    
    # Hoping the automatic inserted lines are still there and in the right order !
    # ==> the line number 2 of the macro editor will be set to "my \$exp = $exp;" and this will cause
    # new execution of the macro instructions
            $macro_ed->number(2)->set("my \$exp = $exp;");
        }
    },
    
    'down_key' => sub {
        my $editor = Editor->whose_name('call_stack');
        my ( $line ) = $editor->cursor->get;
        #print "Dans down_demo9 : trouvé $line | ", $line->text, "\n";
        if ( my $next = $line->next ) {
            $editor->deselect;
            my $exp = $next->select;
            $editor->cursor->set(0, $next);
            my $macro_ed = Editor->whose_name('macro');
    
    # Hoping the automatic inserted lines are still there and in the right order !
    # ==> the line number 2 of the macro editor will be set to "my \$exp = $exp;" and this will cause
    # new execution of the macro instructions
            $macro_ed->number(2)->set("my \$exp = $exp;");
        }
    },
}