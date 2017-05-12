use Test::More;
use Config;
BEGIN {
    if ( ! $Config{'useithreads'} ) {
        plan skip_all => "Perl not compiled with 'useithreads'";
    }
    elsif ( ! -f 'tk_is_ok' ) {
        plan skip_all => "Tk is not working properly on this machine";
    }
    else {
        plan no_plan;
    }
}

use strict;
use lib '../lib';

use threads;
use threads::shared;

our $integer : shared = 3;

sub mul_3 {
    $integer = $integer * 3;
}

sub add_3 {
    my ( $editor ) = @_;
    
    $integer = $integer + 3;
}

sub sub_3 {
    $integer = $integer - 3;
}

sub sub_6 {
    $integer = $integer - 6;
}

sub div_3 {
    $integer = $integer / 3;
}

use Text::Editor::Easy;
use Text::Editor::Easy::Comm;


my $editor = Text::Editor::Easy->new({  
	'bloc' => "use Text::Editor::Easy;\nmy \$editor = Text::Editor::Easy->new\n",
	'focus' => 'yes',
    'events' => {
        'clic' => {
            'sub' => 'mul_3',
        },    
        'motion' => [
		    { 
                'sub' => 'add_3',
            },
		    { 
                'sub'    => 'sub_6',
                'thread' => 'Toto',
                'sync'   => 'true',
            },
        ],
		'drag' => {
				'sub' => 'add_3',
		},
    }
});



is ( ref($editor), "Text::Editor::Easy", "Object type");

$editor->clic( {
    'x' => 1,
    'y' => 1, 
    'meta_hash' => {},
    'meta' => 'ctrl_',
});

is ( $integer, 3, 'Meta key');

my $event_ref = {
    'x' => 1,
    'y' => 1, 
    'meta_hash' => {}, 
    'meta' => '',
}; 

$editor->clic( $event_ref );

is ( $integer, 9, 'Simple clic event');

$editor->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor->cursor->set_shape ( 'arrow' );

is ( $integer, 6, 'Motion event, multiple action with different threads, synchronous');

$editor->drag( $event_ref );

is ( $integer, 9, 'Simple drag event');

$editor->set_event( 'change', {
    'sub' => 'div_3',
    'thread' => 'Tata',
    'sync'   => 'true',
} );
        
$editor->number(1)->set('New content for line 1');

is ( $integer, 3, 'set_event, instance call, change event added');

$editor->set_event( 
    'motion', {
        'sub' => 'mul_3',
    }
);

$editor->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor->cursor->set_shape ( 'arrow' );

is ( $integer, 9, 'set_event for instance call, event updated');

$editor->set_event( 'motion' );

is ( $integer, 9, 'set_event for instance call, event deleted');

my $editor2 = Text::Editor::Easy->new;

Text::Editor::Easy->set_event( 
    'clic', {
        'sub' => 'add_3',
    }
);

$editor->clic( $event_ref );

print "editor id = ", $editor->id, "\n";

$editor2->clic( $event_ref );

print "editor2 id = ", $editor2->id, "\n";

is ( $integer, 15, 'set_event for class call');

$editor2->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor2->cursor->set_shape ( 'arrow' );

is ( $integer, 15, 'checking motion for new editor');

$editor2->set_events( {
    'motion' => {
        'sub' => 'div_3',
    }
} );

$editor2->clic( $event_ref );

is ( $integer, 15, 'set_events, instance call, key deleted');

$editor2->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor2->cursor->set_shape ( 'arrow' );

is ( $integer, 5, 'set_events, instance call, key added');

$editor->drag( $event_ref );

is ( $integer, 8, 'Checking drag after set_event, key kept');

Text::Editor::Easy->set_events( {
    'drag' => {
        'sub' => 'mul_3',
    }
} );

$editor->drag( $event_ref );

is ( $integer, 24, 'set_events, class call, key changed');

$editor2->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor2->cursor->set_shape ( 'arrow' );

is ( $integer, 24, 'set_events, key suppressed');

$editor2->drag( $event_ref );

is ( $integer, 72, 'set_events, key added');

