package Text::Editor::Easy::Graphic;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Graphic::Console_glue - Link between "Text::Editor::Easy::Abstract" and a terminal. Does not actually work.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

#require Term::Screen;
require Term::Screen::Win32;

use Scalar::Util qw(refaddr);
use IO::File;

use threads;
use threads::shared;
my %editor
  ;    # A un canevas, on fait correspondre un éditeur, l'éditeur qui a le focus

#share ( %editor);
#my %canva; # A un éditeur, on fait correspondre un canevas : inutile, car contenu
# dans l'objet Graphic et accessible par ->[CANVA]

use constant {
    TERM      => 0,
    RESIZE    => 1,
    KEY_PRESS => 2,
    TEXT => 3, # Hachage artificiel des bouts de texte demandés pour l'affichage
    MARKED => 4
    , # Hachage articificiel des bouts de textes marqués (pour éventuel déplacement)
    ID      => 5,    # Dernier identifiant attribué pour un bout de texte
    FIC     => 6,    # Descripteur de fichier pour debug
    EXAMINE => 7,    # Descripteur de fichier pour debug

    # Pour garder le positionnement du curseur
    CURSOR => 8,

    META_KEYS => 9,    # Sauvegarder l'appui sur ALT, SHIFT et CTRL

    ABS => 0,
    ORD => 1,
};

sub new {
    my ( $class, $hash_ref ) = @_;

    my $self = [];
    bless $self, $class;
    $self->initialize($hash_ref);
    return $self;
}

sub initialize {
    my ( $self, $hash_ref ) = @_;
    my $mw;
    if ( $hash_ref->{main_window} ) {

        #print "La fenêtre principale a déjà été créée\n";
        $mw = $hash_ref->{main_window};
    }
    else {
        $mw = create_main_window(
            $hash_ref->{width},    $hash_ref->{height},
            $hash_ref->{x_offset}, $hash_ref->{y_offset},
            $hash_ref->{title},
        );
    }
    $self->[TERM] = $mw;

#open ( $self->[FIC], ">console_debug.txt") or die "Impossible d'ouvrir console_debug.txt : $!\n";
#$| = 1;
#print {$self->[FIC]} "SELF : $self\n";

    #   my $canva;
    #  if ( $hash_ref->{canvas} ) {
    #		$canva = $hash_ref->{canvas};
    #  }
    #  else {
    #    $canva = create_canva (
    #    $mw,
    #	$hash_ref->{background},
    #	  -xscrollincrement => 0,
    #	  -yscrollincrement => 0,
    #    );
    #  }
    if ( $hash_ref->{editor_ref} ) {
        $editor{ refaddr $mw} = $hash_ref->{editor_ref};
    }

# Pour l'instant on ne gère pas la fonction manage_event, on
#$canva->CanvasBind( '<Configure>', [ \&resize, $hash_ref->{resize}, Ev('w'), Ev('h') ] );
    $self->[RESIZE] = $hash_ref->{resize};

#$canva->CanvasBind( '<KeyPress>' => [ \&key_press, $hash_ref->{key_press}, Ev('K'), Ev('A') ] );
#$canva->CanvasBind('<KeyRelease>' => [ \&redirect, $hash_ref->{key_release}, Ev('K')]);
    $self->[KEY_PRESS] = $hash_ref->{key_press};

    $self->[EXAMINE] = $hash_ref->{repeat};

#$mw->repeat(80, [ $hash_ref->{repeat}, $editor{refaddr $canva} ] ); # Gestion des évènements externes : dans manage_event
}

sub redirect {
    my ( $mw, $sub_ref, @data ) = @_;

    my $editor_ref = $editor{ refaddr $mw};
    $sub_ref->( $editor_ref, @data );
}

sub create_main_window {
    my ( $width, $height, $x, $y, $title ) = @_;

    #my $mw =new Term::Screen;
    my $mw = new Term::Screen::Win32;
    $mw->noecho();

    #$mw->resize( $width, $height );

    #my $mw = {};

    return $mw;
}

my %key = (
    'ku'   => 'Up',
    'kd'   => 'Down',
    'kr'   => 'Right',
    'kl'   => 'Left',
    'end'  => 'End',
    'home' => 'Home',
    'ins'  => 'Insert',
    'del'  => 'Delete',
    'ctrl' => 'Control_L',
    'alt'  => 'Alt_L',
    'pgup' => 'Prior',
    'pgdn' => 'Next',
);
my %ascii = (
    1          => 'ctrl_A',
    2          => 'ctrl_B',
    3          => 'ctrl_C',
    4          => 'ctrl_D',
    5          => 'ctrl_E',
    6          => 'ctrl_F',
    7          => 'ctrl_G',
    9          => 'ctrl_I',
    10         => 'ctrl_J',
    11         => 'ctrl_K',
    12         => 'ctrl_L',
    14         => 'ctrl_N',
    15         => 'ctrl_O',
    16         => 'ctrl_P',
    17         => 'ctrl_Q',
    18         => 'ctrl_R',
    19         => 'ctrl_S',
    20         => 'ctrl_T',
    21         => 'ctrl_U',
    22         => 'ctrl_V',
    23         => 'ctrl_W',
    24         => 'ctrl_X',
    25         => 'ctrl_Y',
    26         => 'ctrl_Z',
    13         => "Return",
    8          => "BackSpace",
    127        => "Delete",
    4294967289 => '¨',
    4294967170 => 'é',
    4294967178 => 'è',
    4294967175 => 'ç',
    4294967173 => 'à',
    4294967288 => '°',
    4294967196 => '£',
    4294967270 => 'µ',
    4294967191 => 'ù',
    4294967285 => '§',
    4294967293 => '²',
    4294967247 => '¤',
);

sub clear_screen {
    my ($self) = @_;

    $self->[TERM]->clrscr();
}

sub manage_event {
    my ($self) = @_;

    # Génération du premier resize
    $self->[TERM]->clrscr();

    #my $hash_ref = $self->[TERM]->resize( );

#$self->[RESIZE]->( $editor{refaddr $self->[TERM]}, $hash_ref->{COLS}, $hash_ref->{ROWS});
#my $console = Term::ANSIScreen->new;
#$console->Cls;

    #my $term =new Term::Screen;

    $self->[RESIZE]->( $editor{ refaddr $self->[TERM] }, 120, 35 );

 #threads->new( \&manage_keyboard, refaddr $self->[TERM], $self->[KEY_PRESS] );#

    # Pour l'instant pas de gestion des changements de la taille d'écran
    #EVENT: while ( my $char = $self->[TERM]->getch() ){
    use Time::HiRes qw (sleep );
    while (1) {

        #use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;
        #print colored ("TAPER $char", "bold blue");

        #$self->[KEY_PRESS]->( $editor{refaddr $self->[TERM]}, $char, $char);
        #last EVENT if ($char eq "&");
        $self->[EXAMINE]->( $editor{ refaddr $self->[TERM] } );

      KEY: while ( $self->[TERM]->key_pressed ) {
            my $char = $self->[TERM]->getch();
            $char = $ascii{ ord($char) } if ( $ascii{ ord($char) } );
            $char = $key{$char}          if ( $key{$char} );
            if ( $char eq 'Control_L' ) {
                $self->[META_KEYS]{'ctrl'} = 5;
                next KEY;
            }
            if ( $char eq 'Alt_L' ) {
                $self->[META_KEYS]{'alt'} = 5;
                next KEY;
            }
            if ( $char eq 'shift' ) {
                $self->[META_KEYS]{'shift'} = 5;
                next KEY;
            }
            if ( $char =~ /ctrl_(\w)/ ) {
                $self->[META_KEYS]{'ctrl'} = 5;
                $char = $1;
            }
            my @options;
            if ( $self->[META_KEYS]{'ctrl'} ) {
                push @options, 'ctrl', 1;
            }
            if ( $self->[META_KEYS]{'alt'} ) {
                push @options, 'alt', 1;
            }
            if ( $self->[META_KEYS]{'shift'} ) {
                push @options, 'shift', 1;
            }
            $self->[KEY_PRESS]
              ->( $editor{ refaddr $self->[TERM] }, $char, $char, {@options} );
        }
        sleep(0.1);
        for ( keys %{ $self->[META_KEYS] } ) {
            if ( $self->[META_KEYS]{$_} ) {
                $self->[META_KEYS]{$_} -= 1;
            }
        }
    }
}

# After initialisation

sub length_text {
    my ( $self, $text, $font ) = @_;

    return length $text;
}

my %color = (
    "black"     => "white",
    "dark blue" => "bold blue",
    "dark red"  => "bold red",
);

sub create_text_and_mark_it {
    my ( $self, $hash_ref ) = @_;
    use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;

    $self->[ID] += 1;
    my $id = $self->[ID];
    $self->[TEXT]{$id}   = $hash_ref;
    $self->[MARKED]{$id} = 1;

    my $color = $color{ $hash_ref->{color} } || "bold green";

    #    $self->[TERM]->at($hash_ref->{ord}, $hash_ref->{abs});
    locate( $hash_ref->{ord}, $hash_ref->{abs} );
    print colored ( $hash_ref->{text}, $color );

    #    $self->[TERM]->puts($hash_ref->{text});
    replace_cursor($self);
    return $id;
}

sub delete_mark_from_text {
    my ($self) = @_;

    for ( keys %{ $self->[MARKED] } ) {
        delete $self->[MARKED]{$_};
    }
}

sub move_marked_text_one_line_up {
    my ($self) = @_;

    #$self->[CANVA]->move( 'just_created', 0, -17 );
}

sub change_text_item_property {
    my ( $self, $text_id, $text ) = @_;

    #$self->[CANVA]->itemconfigure($text_id, -text, $text);
}

sub delete_text_item {
    my ( $self, $text_id ) = @_;

    my $hash_ref = $self->[TEXT]{$text_id};
    my $abs      = $hash_ref->{abs};
    my $ord      = $hash_ref->{ord};
    my $text     = $hash_ref->{text};
    locate( $hash_ref->{ord}, $hash_ref->{abs} );
    print " " x length( $hash_ref->{text} );

    #print locate($abs,$ord), " " x length($text);
    #print "delete ($abs,$ord)", length($text), "\n";
    delete $self->[TEXT]{ID};
    replace_cursor($self);
}

sub position_cursor_in_text_item {
    my ( $self, $text_id, $position ) = @_;

    #print {$self->[FIC]} "Dans position cursor : $text_id|$position|\n";

    my $hash_ref = $self->[TEXT]{$text_id};
    my $abs      = $hash_ref->{abs};
    my $ord      = $hash_ref->{ord};
    $self->[CURSOR][ORD] = $hash_ref->{ord} - 1;
    $self->[CURSOR][ABS] = $hash_ref->{abs} - 1 + $position;
    $self->[TERM]->at( $self->[CURSOR][ORD], $self->[CURSOR][ABS] );

    #print "Dans position cursor : $abs + $position,$ord)\n";
}

sub replace_cursor {
    my ($self) = @_;

    $self->[TERM]->at( $self->[CURSOR][ORD], $self->[CURSOR][ABS] );
}

sub resize {
    my ( $canva, $sub_ref, $height, $width ) = @_;

}

sub move {
    my ( $self, $x, $y ) = @_;

    #  $self->[CANVA]->move( 'text', $x, $y );
}

sub get_regexp {
    my ( $self, $sub_ref, $title ) = @_;

}

sub look_for {
    my ( undef, $self, $sub_ref ) = @_;

}

sub destroy_find {
    my ( $find, $self ) = @_;

}

sub change_reference {

    # Avant d'appeler cette fonction, faire le ménage sur le canevas
    my ( $self, $edit_ref, $file_name ) = @_;

    #  $editor{refaddr $self->[CANVA]} = $edit_ref;
    #  $self->[TERM]->configure( -title => $file_name );
}

sub get_displayed_editor {
    my ($editor) = @_;

    #  my $canva = $editor->[CANVA];
    #  return $editor{ refaddr $canva };
}

sub set_font_size {
    my ( $self, $font, $size ) = @_;

}

sub create_font {
    return 1;
}

sub line_height {
    return 1;
}

sub margin {
    return 1;
}

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
