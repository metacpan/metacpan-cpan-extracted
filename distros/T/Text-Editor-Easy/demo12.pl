#
# Dynamic event management
# 
# This demo gives better examples of dynamic designing and
# shows the interest of threads in graphical user applications.
#
# The principle is to add a specific management to the 'clic'  event 
# of the 'call_stack' editor.
#
# In order to know which editor the 'call_stack' is, press F5.
#

{
    'F5' => sub {

        my ( $editor, $info_ref ) = @_;
        print "Dans F5, editor = $editor\n";
        $info_ref->{'id'} = $editor->id;
        
        my $stack_editor = Text::Editor::Easy->whose_name('call_stack');
        $info_ref->{'color'} = $stack_editor->background;
        
        print "couleur = $info_ref->{'color'}\n";
        
        my $tid = Text::Editor::Easy->create_new_server( {
            'object' => $info_ref,
            'methods' => [
            ],
            'name' => 'Demo12',
        } );
        $info_ref->{'sequence'} = 0;
        $stack_editor->save_info( $info_ref );
        
        $stack_editor->ask_thread('add_thread_method', $tid, {
            'method' => 'blink',
            'code' => $info_ref->{'blink'},
        } );        
        
        $editor->bind_key( { 
            'sub_ref' => $info_ref->{'F5_stack'},
            'key' => 'F5',
        } );
        
        $stack_editor->set_event( 
            'clic',
            { 
                'code' => $info_ref->{'clic_1'},
                'thread' => 'Demo12',
            },
        );
        
        $stack_editor->async->blink;
        
        print "Avant création de 'clic'\n";
        
        my $clic_ed = Text::Editor::Easy->whose_name('clic');
        
        my $highlight_ref = {
            'use'     => 'Text::Editor::Easy::Syntax::Perl_glue',
            'package' => 'Text::Editor::Easy::Syntax::Perl_glue',
            'sub'     => 'syntax',
        };
        if ( ! defined $clic_ed ) {
            $clic_ed = Text::Editor::Easy->new( {
                'zone'      => 'zone1',
                'bloc'      => $info_ref->{'comment_1'},
                'name'      => 'clic',
                'highlight' => $highlight_ref,
                'focus' => 'yes',
            } );
        }
        else {
            $clic_ed->set_highlight( $highlight_ref );
            $clic_ed->empty;
            $clic_ed->insert( $info_ref->{'comment_1'} );
            $clic_ed->focus;
        }
        
        $clic_ed->bind_key( { 
            'sub_ref' => $info_ref->{'F5_clic'},
            'key' => 'F5',
        } );
        $stack_editor->bind_key( { 
            'sub_ref' => $info_ref->{'F5_clic'},
            'key' => 'F5',
        } );
    },
    
    'F5_stack' => sub {
        my ( $editor ) = @_;
        
        print "Dans F5 new, editor = $editor\n";
        my $stack_editor = Text::Editor::Easy->whose_name('call_stack');
        
        my $clic_ed = Text::Editor::Easy->whose_name('clic');
        $clic_ed->empty;
        
        my $info_ref = $stack_editor->load_info;
        $clic_ed->insert( $info_ref->{'comment_1'} );
        $clic_ed->focus;
        
        $info_ref->{'sequence'} = 0;
        $clic_ed->save_info( $info_ref );
        
        $stack_editor->set_event( 
            'clic',
            { 
                'code' => $info_ref->{'clic_1'},
                'thread' => 'Demo12',
            },
        );
        $stack_editor->async->blink;
    },
    
    'blink' => << 'blink'
        my ( $self ) = @_;
        
        print "Dans blink, self = $self... tid = ", threads->tid, "\n";
        
        my $stack_editor = Text::Editor::Easy->whose_name('call_stack');
        
        while ( 1 ) {
            $stack_editor->set_background('blue');
            
            sleep 1;
            return if ( anything_for_me() );
            $stack_editor->set_background('red');
            sleep 1;
            return if ( anything_for_me() );
        }
blink
    ,
    
    'clic_1' => << 'clic_1'

my ( $self ) = @_;

$self->empty;

print "Dans clic 1... tid = ", threads->tid, ", self = $self\n";
my $info_ref = $self->load_info;
$info_ref->{'sequence'} = 2;
$self->save_info( $info_ref );

print "couleur trouvée dans save_info $info_ref->{'color'}\n";
$self->set_background( $info_ref->{'color'} );

my $clic_ed = Text::Editor::Easy->whose_name('clic');
$clic_ed->empty;
$clic_ed->insert( $info_ref->{'comment_2'}, {
    'display' => [ 'line_0' => { 'at' => 'top' } ]
} );
$clic_ed->at_top;

my $macro = Text::Editor::Easy->whose_name('macro');
$macro->empty;
$macro->insert( $info_ref->{'macro'} );

clic_1
    ,

    'comment_1' => <<'comment_1'
# Now that you've pressed F5, the 'call_stack' editor
#   should be blinking blue and red.
# 
# In order, to stop this blinking, all you have to do
#   is to 'clic' in this editor.   
comment_1
    ,

    'comment_2' => <<'comment_2'
# Good, now you know which editor we're playing with :
# we are going to  modify the 'clic' event of this 
# 'call_stack' editor and you'll just have to clic in it
# again to check that the action wanted is done.
#
# In the 'macro' editor (at the left bottom),
# you have the instructions that change the 'clic' event
# of 'call_stack' editor. You shouldn't change these
# instructions.
# 
# Just under these last comments, you have the new code
# for the 'clic' event of the 'call_stack' editor.
# You can test it as you've done before (by a 'clic'
# in the 'call_stack') or you can change the 'clic'
# event by pressing F5 key ...
#

my ( $editor, $info_ref ) = @_;

$editor->insert( 
    "\nClic at x = $info_ref->{'x'}, y = $info_ref->{'y'}",
    {
        'line' => $info_ref->{'line'},
    }
);
comment_2
    ,
    
    'macro' => <<'macro'
my $call_stack_ed = Text::Editor::Easy->whose_name('call_stack');
my $clic_ed = Text::Editor::Easy->whose_name('clic');

$call_stack_ed->set_event( 'clic', {
    'code' => $clic_ed->slurp,
    'thread' => 'Demo12',
} );
macro
    ,

    'F5_clic' => sub {
        my ( $clic_ed ) = @_;
        
        print "Dans F5_clic...\n";
        my $stack_ed = $clic_ed;
        if ( $clic_ed->name ne 'clic' ) {
            # F5 commun entre 'call_stack' et 'clic'
            $clic_ed = Text::Editor::Easy->whose_name('clic');
        }
        else {
            $stack_ed = Text::Editor::Easy->whose_name('call_stack');
        }
        my $info_ref = $stack_ed->load_info;
        my $sequence = $info_ref->{'sequence'};

        return if ( ! $sequence );
        $sequence += 1;

        my $new_code = $info_ref->{'comment_' . $sequence};
        if ( ! defined $new_code ) {
            return;
        }
        $info_ref->{'sequence'} = $sequence;
        
        $stack_ed->save_info( $info_ref );

        $clic_ed->empty;
        
        print "Après vidage : new_code = $new_code\n";
        $clic_ed->insert( $new_code, {
            'display' => [ 'line_0' => { 'at' => 'top' } ]
        } );
        $clic_ed->at_top;

        my $macro = Text::Editor::Easy->whose_name('macro');
        $macro->empty;
        $macro->insert( $info_ref->{'macro'} );        
    },
  
    'comment_3' => <<'comment_3'
# An example of huge interruptible task. As the event is done by
# the thread "Demo12", the graphic user interface is not
# freezed, even if this event last 5 seconds.

# A second 'clic' during the sequence will interrupt it and restart it.

use Text::Editor::Easy::Comm;

my ( $editor, $info_ref ) = @_;

for ( 1..5) {
    return if ( anything_for_me );
    
    $info_ref->{'line'}->set( $_ x 12 );

    sleep 1;
}
comment_3
    ,
    
    'comment_4' => <<'comment_4'
# An endless task, still interruptible.
#
# There are 2 ways to interrupt the blinking : either
# by another clic, or by adding a space (or any useless
# character) in the 'macro' editor. In the last case,
# we ask the thread 'Demo12' to update its event
# code, so there is something for it.

use Text::Editor::Easy::Comm;

my ( $editor, $info_ref ) = @_;

my $color = $editor->load_info('color');
if ( $color ne $editor->background ) {
    $editor->set_background( $color );
    return;
}
while ( 1 ) {
    $editor->set_background('blue');
    
    sleep 1;
    return if ( anything_for_me() );
    $editor->set_background('red');
    sleep 1;
    return if ( anything_for_me() );
}
comment_4
    ,
    
    'comment_5' => <<'comment_5'
# This is the last example
#
# It only prints info, but you should
# see these prints appear in the 'dynamic log'
# which is the editor ... 'Editor'.
#
# As this is dynamic, you can change the
# code of the 'clic' event yourself,
# and have it known by the "Demo12" thread
# simply by adding or removing a useless
# character in the 'macro' editor at the 
# bottom.
#
# If you do that, the code of your 'clic'
# event will be nowhere but in memory. All the
# previous 'clic' codes were in the file 'demo12.pl'.
#

my ( $editor, $info_ref ) = @_;

# Make the dynamic log visible (if hidden and/or not at end)
my $log_ed = Text::Editor::Easy->whose_name('Editor');
$log_ed->at_top;
$log_ed->set_at_end;


print "In clic event of editor ", $editor->name, " :\n";

while ( my ($key, $value) = each %$info_ref ) {
  if ( ! defined $value ) {
      $value = '<undef>';
  }
  print "\t$key => $value\n";
}


comment_5
    ,
    
}