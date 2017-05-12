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

our $integer : shared = 9;


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
    
use Text::Editor::Easy {
    #'trace' => {
    #    'all' => 'tmp/',
    #    'trace_print' => 'full',
    #},
};

Text::Editor::Easy->set_events( 
    {
        'motion' => {
            'sub'    => 'add_3',
            'thread' => 'Motion',
            'sync'   => 'true',
        },
    },
    { 'values' => 'defined' },
);


Text::Editor::Easy->set_events( 
    {
        'drag' => {
            'sub'    => 'div_3',
            'thread' => 'Motion',
            'sync'   => 'true',
        },
    },
    { 'values' => 'undefined' },
);

Text::Editor::Easy->set_event(
    'clic',
    {
        'sub'    => 'sub_3',
        'thread' => 'Clic',
        'sync'   => 'true',
    },
    { 'names' => qr/toto/ },
);

Text::Editor::Easy->set_event(
    'clic',
    {
        'sub'    => 'mul_3',
    },
    { 'values' => 'undefined' },
);

my $editor = Text::Editor::Easy->new({  
	'bloc'   => "use Text::Editor::Easy;\nmy \$editor = Text::Editor::Easy->new\n",
	'focus'  => 'yes',
    'events' => {
        'clic' => {
            'sub' => 'mul_3',
        },    
    },
    'name'   => 'toto1',
});

is ( ref($editor), "Text::Editor::Easy", "Object type");

$editor->clic( {
    'x' => 1,
    'y' => 1, 
    'meta_hash' => {},
    'meta' => 'ctrl_',
});

is ( $integer, 9, 'Meta key');

my $event_ref = {
    'x' => 1,
    'y' => 1, 
    'meta_hash' => {}, 
    'meta' => '',
}; 

$editor->clic( $event_ref );

is ( $integer, 6, 'Simple clic event');

$editor->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor->cursor->set_shape ( 'arrow' );

is ( $integer, 9, 'Motion event');

$editor->drag( $event_ref );

is ( $integer, 9, 'Simple drag event');

Text::Editor::Easy->set_event( 
    'change', 
    {
        'sub' => 'div_3',
        'thread' => 'Tata',
        'sync'   => 'true',
    },
    { 'instances' => 'all', },
);

$editor->number(1)->set('New content for line 1');

is ( $integer, 3, 'set_event, instance call, change event added');

Text::Editor::Easy->set_event( 
    'motion', {
        'sub' => 'mul_3',
    },
    { 'instances' => 'existing', },
);

$editor->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor->cursor->set_shape ( 'arrow' );

is ( $integer, 9, 'set_event for existing instances, event updated');

Text::Editor::Easy->set_event( 'motion', undef, {'names' => qr/toto/} );

is ( $integer, 9, 'set_event for class call, event deleted');

#Text::Editor::Easy->print_default_events;

my $editor2 = Text::Editor::Easy->new( { 'name' => 'titi' } );

$editor2->clic( $event_ref );

is ( $integer, 27, 'default clic initialization');

$editor2->drag( $event_ref );

is ( $integer, 9, 'default drag initialization');

$editor2->number(1)->set('New content for line 1');

is ( $integer, 3, 'default change initialization');

$editor2->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor2->cursor->set_shape ( 'arrow' );

is ( $integer, 3, 'checking motion for new editor');

Text::Editor::Easy->set_events( {
    'motion' => {
        'sub' => 'div_3',
    }
} );

$editor2->clic( $event_ref );

is ( $integer, 3, 'set_events, key deleted for editor2');

$editor->clic( $event_ref );

is ( $integer, 3, 'set_events, key deleted for editor');

$editor2->motion( $event_ref );

# Réinitialisation du curseur modifié par move et initiant une séquence de resize pour le prochain clic
$editor2->cursor->set_shape ( 'arrow' );

is ( $integer, 1, 'set_events key added');

$editor->drag( $event_ref );

is ( $integer, 1, 'Checking drag after set_event');

