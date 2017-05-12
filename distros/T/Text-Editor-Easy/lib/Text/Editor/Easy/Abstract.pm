package Text::Editor::Easy::Abstract;

my $zzz = 0;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Abstract - The module that manages everything that is displayed.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

=head1 SYNOPSIS

This is an internal module. It implements the graphical part in an abstract way : it should be compatible with different user interfaces, but
at present, it works only with 'Tk'.

This module is used only by the graphical thread, with tid 0. All other threads that want to make graphic actions have to use the object interface :
calling graphical methods on "Text::Editor::Easy" instances will be redirected here, in this module, and will allways be executed by the
graphical thread.

Have a look at L<Text::Editor::Easy::Comm>  if you want more explanations about thread communications.

Have a look at L<Text::Editor::Easy>, L<Text::Editor::Easy::Line>, L<Text::Editor::Easy::Cursor>, L<Text::Editor::Easy::Display> if you want 
more explanations about the object interface.

=head1 PRINCIPLE

There are 2 (or 3 if we include the L<Text::Editor::Easy::File_manager> module) complex modules in the "Text::Editor::Easy" tree.
This module and the L<Text::Editor::Easy::Comm> which handles communication between threads.

If you create a "Text::Editor::Easy" object, this 'Abstract' module will be called very often. Lots of methods are
redirected here (but you don't even have to know that this module exists).

At the beginning (in 2006), there was only this "module-program". Little by little, this module has grown and
has soon become an ugly mess (well, it still is !).
When I decided to access the "text data" to be displayed in an another module, it became much simpler. At this
very moment, I began to use more than one thread, and the number of different modules grew rapidly. This was
the very good thing threads have brougth me : simplification by partition.

This module has only limited knowledge of what is in the file. It knows only what it has to display according
to the police size and to the screen size.

When there is space to fill up, it asks "File_manager" for data. "File_manager" can provide data before or after
a referenced line. When the user modify something, this module informs "File_manager".

As soon a line is no more on the screen, this module forgets it (destroy it for speed reason) : it relies
entirely on "File_manager" to memorize what should be.

This trick has a big advantage. In fact, with my module, you can Edit text file of unlimited size with the same
speed as little file. Not much Editors can do that. For huge file, my perl Editor is still usable whereas most C
Editors are not. Of course, you could develop a C Editor with the same principle, ... good luck. With
perl, it's just funny. In C, it's hard work.

=cut

# Affichage
use Text::Editor::Easy::Graphic::Tk_glue;

# Syntaxe
use Text::Editor::Easy::Syntax::perl_assist;

# Touches
use Text::Editor::Easy::Abstract::Key;

# Communication
use Text::Editor::Easy::Comm
  qw(anything_for_me get_task_to_do execute_this_task );

# Evènements
use Text::Editor::Easy::Events qw(execute_events);

# Provisoire
use Text::Editor::Easy::Motion;

use Data::Dump qw(dump);
use Scalar::Util qw(refaddr);
use Devel::Size qw(size total_size);

my $origin = 'graphic';    # Gestion de la provenance des actions
my $sub_origin;            # Idem
my $sub_sub_origin;            # Idem
my $last_graphic_event; # Interruptible task which takes into account user events
# Chaque element ligne de la liste chaînée fera référence à un tableau contenant les elements suivants

use constant {

    #------------------------------------
    # LINE_REF : Lignes de texte
    #------------------------------------
    TEXT => 0,             # Texte de la ligne
    # Element texte qui suit cet element (juste à droite ou premier de la ligne suivante)
    NEXT => 1, 
     # Element texte qui precède cet element (juste à gauche ou dernier element de la ligne precedente)
    PREVIOUS => 2,
    FIRST => 3,   # Premier element texte de la ligne, première ligne du segment
                  #LINE_NUMBER => 4,  # A supprimer
    SIZE  => 5,   # Absisse maximum de la ligne
    PREVIOUS_SAME =>
      6,          # booléen : la ligne précédente est "la même" : mode "wrap"
    HEIGHT    => 7,
    NEXT_SAME => 10,           # booléen : la ligne suivante est "la même" : mode "wrap"
    DISPLAYED => 8,    # booléen : la ligne est affichée à l'écran
    # Référence à stoker pour communiquer avec le thread gestionnaire du fichier et des mises à jour
    REF       => 9,
    ORD => 11,

    LAST =>
      13,    # Référence au dernier élément texte du segment : jamais utilisé !
     # alors que seulement la 1ère et la dernière sont utiles pour le positionnement de la scollbar
     # Zones sélectionnées
     #------------------------------------
     # CURSOR_REF
     #------------------------------------
    VIRTUAL_ABS         => 0,
    POSITION_IN_TEXT    => 1,
    POSITION_IN_DISPLAY => 2,
    TEXT_REF            => 3,

    #ABS => 4,
    POSITION_IN_LINE => 5,
    RESIZE => 6,
    # LINE_REF => 7,

#------------------------------------
# TEXT_REF
#------------------------------------
# Element texte (element FIRST de chaque element de ligne, $text_ref ...)
#TEXT          => 0,
#NEXT          => 1, # Element texte suivant (juste à droite ou premier de la ligne suivante)
#PREVIOUS    => 2, # Element texte précédant (juste à gauche ou dernier element de la ligne precedente)
    ID =>
      3, # Identifiant affecté par Tk à l'element texte du canevas correspondant
    ABS   => 4,
    FONT  => 5,
    # Indique la largeur de l'element (compte-tenu de la fonte), équivalent à :
    WIDTH => 6,
    # Reference à l'element ligne (c'est-à-dire à une reference de tableau)
    LINE_REF => 7,

    COLOR           => 8,    # Couleur d'affichage
    #------------------------------------
    # SCREEN
    #------------------------------------
    MARGIN          => 0,
    VERTICAL_OFFSET => 1,

    #HORIZONTAL_OFFSET => 2, # Supprimé
    WRAP        => 4,
    LINE_HEIGHT => 8,
    FONT_HEIGHT => 9,

    #HEIGHT => 7,
    #------------------------------------
    # $self->[?]
    #------------------------------------
    INSER     => 0,
    SCREEN    => 1,
    SEGMENT   => 2,
    #ID    => 3,    # Text::Editor::Easy unique identifier
    GRAPHIC   => 4,
    REGEXP    => 5,
    CALC_LINE => 6,
    CURSOR    => 7,
    FILE      => 8,
    RETURN    => 10,    # Test de redirection
    SUB_REF   => 11,
    INIT_TAB  => 12,
    PARENT    => 13,
    ASSIST    => 14,
    KEY => 15,
    H_FONT => 16,
    SELECTION => 17,
    AT_END => 18,
    EVENTS => 19,
    SEQUENCES => 20,
};

use Text::Editor::Easy::Key;
my %key = (
    'Insert' => \&Text::Editor::Easy::Key::inser,
    'Prior'  => [ \&Text::Editor::Easy::Abstract::Key::page_up, 'Abstract' ],
    'Next'   => [ \&Text::Editor::Easy::Abstract::Key::page_down, 'Abstract' ],

    'Down'  => [ \&Text::Editor::Easy::Abstract::Key::down, 'Abstract' ],
    'Up'    => [ \&Text::Editor::Easy::Abstract::Key::up, 'Abstract' ],
    'Home'  => [ \&Text::Editor::Easy::Abstract::Key::home, 'Abstract' ],
    'End'   => [ \&Text::Editor::Easy::Abstract::Key::end, 'Abstract' ],
    'Left'  => [ \&Text::Editor::Easy::Abstract::Key::left, 'Abstract' ],
    'Right' => [ \&Text::Editor::Easy::Abstract::Key::right, 'Abstract' ],
    'Return'   => [ \&Text::Editor::Easy::Abstract::Key::enter, 'Abstract' ],
    'KP_Enter' => [ \&Text::Editor::Easy::Abstract::Key::enter, 'Abstract' ],
    'Delete'   => [ \&Text::Editor::Easy::Abstract::Key::delete, 'Abstract' ],
    'BackSpace'  => [ \&Text::Editor::Easy::Abstract::Key::backspace, 'Abstract' ],

    'ctrl_End'   => [ \&Text::Editor::Easy::Abstract::Key::end_file, 'Abstract' ],
    'ctrl_Home'  => \&Text::Editor::Easy::Key::top_file,
    'ctrl_Right' => \&Text::Editor::Easy::Key::jump_right,
    'ctrl_Left'  => \&Text::Editor::Easy::Key::jump_left,

    'F3' => \&Text::Editor::Easy::next_search,

    'ctrl_c' => [ \&Text::Editor::Easy::Abstract::Key::copy, 'Abstract' ],
    'ctrl_C' => [ \&Text::Editor::Easy::Abstract::Key::copy, 'Abstract' ],
    'ctrl_f'    => \&Text::Editor::Easy::Key::search,
    'ctrl_F'    => \&Text::Editor::Easy::Key::search,

    'ctrl_i'    => [ \&Text::Editor::Easy::Abstract::test_new_insert, 'Abstract' ],
    'ctrl_I'    => [ \&Text::Editor::Easy::Abstract::test_new_insert, 'Abstract' ],
    
    'ctrl_j'    => \&Text::Editor::Easy::Abstract::print_clipboard,
    'ctrl_J'    => \&Text::Editor::Easy::Abstract::print_clipboard,

    'ctrl_l' => \&Text::Editor::Easy::Key::close,
    'ctrl_L' => \&Text::Editor::Easy::Key::close,
    'ctrl_m'    => \&decrease_line_space,
    'ctrl_M'    => \&decrease_line_space,
    'ctrl_p'    => \&increase_line_space,
    'ctrl_P'    => \&increase_line_space,

    'ctrl_q'     => \&Text::Editor::Easy::Key::query_segments,
    'ctrl_Q'     => \&Text::Editor::Easy::Key::query_segments,

    'ctrl_r' => \&revert,
    'ctrl_R' => \&revert,
    'ctrl_s'     => \&Text::Editor::Easy::Key::save,
    'ctrl_S'     => \&Text::Editor::Easy::Key::save,

    'ctrl_v' => [ \&Text::Editor::Easy::Abstract::Key::paste, 'Abstract' ],
    'ctrl_V' => [ \&Text::Editor::Easy::Abstract::Key::paste, 'Abstract' ],
    #'ctrl_v' => \&paste,
    #'ctrl_V' => \&paste,

    'ctrl_w' => \&Text::Editor::Easy::Key::wrap,
    'ctrl_W' => \&Text::Editor::Easy::Key::wrap,

    'ctrl_x'    => [ \&Text::Editor::Easy::Abstract::Key::cut, 'Abstract' ],
    'ctrl_X'    => [ \&Text::Editor::Easy::Abstract::Key::cut, 'Abstract' ],
    'F3'    => \&Text::Editor::Easy::Key::f3_search,
    
    'ctrl_Up'   => \&Text::Editor::Easy::Key::jump_up,
    'ctrl_Down' => \&Text::Editor::Easy::Key::jump_down,
    'alt_Up'    => \&Text::Editor::Easy::Key::move_up,
    'alt_Down'  => \&Text::Editor::Easy::Key::move_down,

    'ctrl_plus' => \&increase_font,

    'ctrl_shift_n' => \&Text::Editor::Easy::Key::print_screen_number,
    'ctrl_shift_N' => \&Text::Editor::Easy::Key::print_screen_number,
    'ctrl_shift_l' => \&Text::Editor::Easy::Key::display_cursor_display,
    'ctrl_shift_L' => \&Text::Editor::Easy::Key::display_cursor_display,
    'ctrl_shift_p' => \&Text::Editor::Easy::Key::list_display_positions,
    'ctrl_shift_P' => \&Text::Editor::Easy::Key::list_display_positions,

    'alt_ampersand' => \&Text::Editor::Easy::Key::sel_first,
    'alt_eacute'    => \&Text::Editor::Easy::Key::sel_second,
    
    # Selection
    'shift_Down'  => [\&Text::Editor::Easy::Abstract::Key::shift_down, 'Abstract' ],
    'shift_Up'    => [ \&Text::Editor::Easy::Abstract::Key::shift_up, 'Abstract' ],
    'shift_Left'  => [ \&Text::Editor::Easy::Abstract::Key::shift_left, 'Abstract' ],
    'shift_Right' => [ \&Text::Editor::Easy::Abstract::Key::shift_right, 'Abstract' ],
    'shift_Home'  => [ \&Text::Editor::Easy::Abstract::Key::shift_home, 'Abstract' ],
    'shift_End'   => [ \&Text::Editor::Easy::Abstract::Key::shift_end, 'Abstract' ],
    'shift_Prior'  => [ \&Text::Editor::Easy::Abstract::Key::shift_page_up, 'Abstract' ],
    'shift_Next'   => [ \&Text::Editor::Easy::Abstract::Key::shift_page_down, 'Abstract' ],

    'alt_F4' => \&Text::Editor::Easy::Abstract::exit,
);

Text::Editor::Easy::Comm::manage_debug_file( __PACKAGE__, *DBG );

my %color;
my @window; # For now, only one window managed (the main window)
my $window_destroyed;

# A une référence d'éditeur unique, on fait correspondre un objet Abstract
my %abstract;
my $pointed_by_mouse;
my %zone_events;
my %use;

sub new {
    my ( $classe, $hash_ref, $editor, $id ) = @_;
    
    print DBG "Dans new de Abstract, classe $classe, id = $id\n";

    #print "Dans Abstract::new : force_resize = $force_resize\n";

    # Début construction
    my $edit_ref = bless [], $classe;
    $edit_ref->[ID] = $id;

    if ( ! %abstract ) {
        $hash_ref->{'destroy'} = \&window_destroy;
    }


    #$edit_ref->[QUEUE] = $hash_ref->{graphic_queue};
    $edit_ref->[INSER] = 1;

    if ( $hash_ref->{return} ) {
        $edit_ref->[RETURN] = $hash_ref->{return};
    }

    #print "Création dans abstract growing = ", $hash_ref->{'growing'}, "\n";
    $edit_ref->[EVENTS] = $hash_ref->{'events'};
    $edit_ref->[SEQUENCES] = $hash_ref->{'sequences'};

    $abstract{$id} = $edit_ref;

    #$edit_ref->[FILE] = $ARGV[0] || "../test.hst";
    $edit_ref->[FILE] = $hash_ref->{file} || '*buffer*';

    $edit_ref->[SCREEN][VERTICAL_OFFSET] = 0;
    $edit_ref->[SCREEN][WRAP]            = 0;

    #$edit_ref->[CALC_LINE] = 0;
    print "Dans init de Abstract self PARENT = ", $editor, "\n";
    $edit_ref->[PARENT] = $editor;

    $edit_ref->[ASSIST] = 0;
    if ( my $tab_ref = $hash_ref->{'highlight'} ) {
        set_highlight( $edit_ref, $tab_ref );
    }
    my @width;
    my @height;
    my @x_offset;
    my @y_offset;
    #my ( $width, $height, $x_offset, $y_offset ) =
    #  ( 1140, 774, 0, 0 );    # for my screen
    if ( defined $hash_ref->{'width'} ) {
        @width = ( 'width' => $hash_ref->{'width'} );
    }
    if ( defined $hash_ref->{'height'} ) {
        @height = ( 'height' => $hash_ref->{'height'} );
    }
    if ( defined $hash_ref->{'x'} ) {
        @x_offset = ( 'x_offset' => $hash_ref->{'x'} );
    }
    if ( defined $hash_ref->{'y'} ) {
        @y_offset = ( 'y_offset' => $hash_ref->{'y'} );
    }
    $edit_ref->[GRAPHIC] = Text::Editor::Easy::Graphic->new(
        {
            'title'                       => $edit_ref->[FILE],
            @width,
            @height,
            @x_offset,
            @y_offset,
            'vertical_scrollbar_sub'      => \&scrollbar_move,
            'vertical_scrollbar_position' => 'right',
            'background'                  => 'light grey',
            'clic'                        => \&clic,
            'motion'                  => \&motion,
            'drag'                     => \&drag,
            'resize'                      => \&resize,
            'key_press'                   => \&key,
            'mouse_wheel_event'           => \&wheel,
            'double_clic'                 => \&double_clic,
            'right_clic'                 => \&right_clic,

            #'key_release' => \&key_release,
            %{$hash_ref},
            'editor_ref' => $edit_ref,
        }
    );

    $edit_ref->[SCREEN][FONT_HEIGHT] = $hash_ref->{'font_size'} || 15;
    #print "FONTE : font_size = ", $hash_ref->{'font_size'}, ", HEIGHT = ", $edit_ref->[SCREEN][FONT_HEIGHT], "\n";
    $edit_ref->[SCREEN][LINE_HEIGHT] = $edit_ref->[GRAPHIC]->line_height;
    $edit_ref->[SCREEN][MARGIN]      = $edit_ref->[GRAPHIC]->margin;

    # Gestion des fontes à étudier ...
    my $default_font = $edit_ref->[GRAPHIC]->create_font(
        {
            'family' => 'courier',
            'size'   => $edit_ref->[SCREEN][FONT_HEIGHT],
            'weight' => 'normal',
        }
    );
    my $bold_font = $edit_ref->[GRAPHIC]->create_font(
        {
            'family' => 'courier',

            #'size'   => $edit_ref->[SCREEN][FONT_HEIGHT] +15,
            'size'   => $edit_ref->[SCREEN][FONT_HEIGHT],
            'weight' => 'bold',
        }
    );
    my $underline_font = $edit_ref->[GRAPHIC]->create_font(
        {
            'family' => 'courier',
            'size'   => $edit_ref->[SCREEN][FONT_HEIGHT],
            'weight' => 'normal',

            #   'underline' => 1,
            'slant' => 'italic',
        }
    );
    my $font_comment = $edit_ref->[GRAPHIC]->create_font(
        {
            'family' => 'lucidabright',
            'size'   => $edit_ref->[SCREEN][FONT_HEIGHT],
            'weight' => 'normal',

            #'slant' => 'italic',
        }
    );

    $edit_ref->[H_FONT] = {
        'default'           => $default_font,
        'comment'           => $font_comment,
        'error'             => $default_font,
        'blue'              => $default_font,
        'dark red'          => $default_font,
        'dark green'        => $default_font,
        'green'             => $default_font,
        'dark blue'         => $default_font,
        'dark purple'       => $default_font,
        'yellow'            => $default_font,
        'black'             => $default_font,
        'red'               => $default_font,
        'pink'              => $default_font,
        'Comment_Normal'    => $font_comment,
        'Comment_POD'       => $font_comment,
        'Directive'         => $bold_font,
        'Label'             => $default_font,
        'Quote'             => $default_font,
        'String'            => $default_font,
        'Subroutine'        => $bold_font,
        'Variable_Scalar'   => $default_font,
        'Variable_Array'    => $bold_font,
        'Variable_Hash'     => $bold_font,
        'Variable_Typeglob' => $bold_font,
        'Whitespace'        => $default_font,
        'Character'         => $default_font,
        'Keyword'           => $bold_font,
        'Builtin_Function'  => $bold_font,
        'Builtin_Operator'  => $bold_font,
        'Operator'          => $default_font,
        'Bareword'          => $default_font,
        'Package'           => $bold_font,
        'Number'            => $default_font,
        'Symbol'            => $bold_font,
        'CodeTerm'          => $bold_font,
        'DATA'              => $default_font,
        'DEFAULT'           => $default_font,
    };
    %color = (
        'default'           => '#000000000000',
        'comment'           => 'blue',
        'error'             => 'red',
        'blue'              => 'blue',
        'dark red'          => 'dark red',
        'dark green'        => 'dark green',
        'green'             => 'green',
        'dark blue'         => 'dark blue',
        'dark purple'       => 'purple',
        'yellow'            => 'orange',
        'black'             => 'black',
        'red'               => 'red',
        'pink'              => 'black',
        'Comment_Normal'    => 'dark green',
        'Comment_POD'       => 'orange',
        'Directive'         => 'dark blue',
        'Label'             => 'dark red',
        'Quote'             => 'firebrick',
        'String'            => 'deep pink',
        'Subroutine'        => 'dark green',
        'Variable_Scalar'   => 'dark blue',
        'Variable_Array'    => 'navy blue',
        'Variable_Hash'     => 'dark green',
        'Variable_Typeglob' => 'purple',
        'Whitespace'        => 'blue',
        'Character'         => 'dark cyan',
        'Keyword'           => 'black',
        'Builtin_Function'  => 'black',
        'Builtin_Operator'  => 'black',
        'Operator'          => 'firebrick',
        'Bareword'          => 'dark red',
        'Package'           => 'gold4',
        'Number'            => 'black',
        'Symbol'            => 'black',
        'CodeTerm'          => 'brown',
        'DATA'              => 'RoyalBlue4',
        'DEFAULT'           => 'violet red',
    );

    $edit_ref->[INIT_TAB] = $hash_ref->{'config'};

    return $edit_ref;
}    # Fin new

sub set_highlight {
    my ( $edit_ref, $tab_ref ) = @_;

    if ( my $use = $tab_ref->{'use'} ) {
        eval "use $use";

        #print "EVAL use $use en erreur\n$@\n" if ($@);
        if ( $use eq 'Text::Editor::Easy::Syntax::Perl_glue' ) {
            $edit_ref->[ASSIST] = 1;
        }
    }
    my $package;
    $package = $tab_ref->{'package'};
    $package = 'main' if ( !defined $package );
    my $sub = $tab_ref->{'sub'};
    $edit_ref->[SUB_REF] = eval "\\&${package}::$sub";
}

my %ref_sub;

sub examine_external_request {

    #while ( anything_for_me ) { # Ne marche pas bien sous Linux (?)
    if ( anything_for_me() ) {
        my ( $what, $call_id, @param ) = get_task_to_do();
        $origin     = $call_id;
        if ( defined $sub_origin ) {
            # Il y a eu un évènement graphique
            $last_graphic_event = $sub_origin;
        }    
        $sub_origin = $what;
        # Inter-thread call, not to be shown in trace
        execute_this_task( $what, $call_id, @param );
        #print "Retour de execute task $sub_origin, $param[2]\n";
    }
    $origin     = "graphic";
    $sub_origin = undef;
}

sub test {
    my ( $self, @param ) = @_;

    # Génération d'un dead lock
    print "Début test : ", cursor_position_in_display($self), "\n";

    if (wantarray) {
        print "Dans test : Contexte de liste\n";
        $self->[PARENT]->append("Dans test : Contexte de liste");
        return ( $param[4]->{cursor_pos_in_line}, $param[3] );
    }
    elsif ( defined(wantarray) ) {
        print "Dans test : Contexte scalaire\n";
        if ( $param[1] eq 'test undef' ) {
            return;
        }
        else {
            return $param[2];
        }
    }
    else {
        print "Dans TEST : Contexte vide\n";
    }
}

# On donne la main au gestionnaire d'évènement : le thread principal n'exécutera plus que examine_external_request périodiquement
sub manage_event {
    my $compteur = 0;
    for ( keys %abstract ) {
        $compteur += 1;
        $abstract{$_}->[GRAPHIC]->manage_event();
        last;
    }
    if ( !$compteur ) {
        print STDERR
"Can't call manage_event loop when no Text::Editor::Easy object is created\n";
    }
}

sub clipboard_set {
    my ( $self, $string ) = @_;

    print "Dans clipboard_set de abstract : |$string|\n";
    for ( keys %abstract ) {
        return $abstract{$_}->[GRAPHIC]->clipboard_set( $string );
    }
    print STDERR
"Can't call clipboard_set when no Text::Editor::Easy object is created\n";
    return;
}

sub clipboard_get {
    for ( keys %abstract ) {
        return $abstract{$_}->[GRAPHIC]->clipboard_get();
    }
    print STDERR
"Can't call clipboard_get when no Text::Editor::Easy object is created\n";
    return;
}

sub print_clipboard {
    my $clipboard = clipboard_get();
    
    my @lines = split( /\n/, $clipboard );
    for my $line ( @lines ) {
        print "$line|\n\t";
        for my $indice ( 0..length($line) - 1 ) {
            my $char = substr( $line, $indice, 1 );
            print ord($char), ":";
        }
        print "\n";
    }
}

#-------------------------------------------------
# "From file to memory" functions
#-------------------------------------------------

sub read_next_line {
    my ( $edit_ref, $prev_line_ref ) = @_;

    my $ref;
    if ($prev_line_ref) {
        $ref = $prev_line_ref->[REF];
    }
    my ( $last, $text ) = $edit_ref->[PARENT]->next_line($ref);

    if ( !$last ) {
        return;
    }
    my $line_ref;
    $line_ref->[REF] = $last;

    chomp $text;

# Suppression des \r éventuels : lecture d'un fichier Windows sous UNIX
# voir aussi l'instruction "read PRG" qui utilise le binmode dans write_file() lors de la sauvegarde du fichier édité
    $text =~ s/\r//g;

    # Suppression des tabulations ...
    $text =~ s/\t/    /g;

    $line_ref->[TEXT] = $text;

    if ($prev_line_ref) {
        $line_ref->[PREVIOUS]  = $prev_line_ref;
        $prev_line_ref->[NEXT] = $line_ref;
    }

    create_text_in_line( $edit_ref, $line_ref );

    return $line_ref;
}

sub create_line_ref_from_ref {    # Création d'une ligne isolée pour affichage
    my ( $edit_ref, $ref, $text ) = @_;

    if ( !defined($text) ) {
        $text = $edit_ref->[PARENT]->line_text($ref);
    }

    return if ( !defined $text );

    my $line_ref;
    $line_ref->[REF] = $ref;

    chomp $text;

# Suppression des \r éventuels : lecture d'un fichier Windows sous UNIX
# voir aussi l'instruction "read PRG" qui utilise le binmode dans write_file() lors de la sauvegarde du fichier édité
    $text =~ s/\r//g;

    # Suppression des tabulations ...
    $text =~ s/\t/    /g;

    $line_ref->[TEXT] = $text;

    create_text_in_line( $edit_ref, $line_ref );

    return $line_ref;
}

sub read_previous_line {
    my ( $edit_ref, $next_line_ref ) = @_;

    my $ref;
    if ($next_line_ref) {
        $ref = $next_line_ref->[REF];
    }

    my ( $first, $text ) = $edit_ref->[PARENT]->previous_line($ref);

    if ( !$first ) {

        # On est au début du fichier
        return;
    }
    my $line_ref;
    $line_ref->[REF] = $first;

    chomp $text;

# Suppression des \r éventuels : lecture d'un fichier Windows sous UNIX
# voir aussi l'instruction "read PRG" qui utilise le binmode dans write_file() lors de la sauvegarde du fichier édité
    $text =~ s/\r//g;

    # Suppression des tabulations ...
    $text =~ s/\t/    /g;

    $line_ref->[TEXT] = $text;

    if ($next_line_ref) {
        $line_ref->[NEXT]          = $next_line_ref;
        $next_line_ref->[PREVIOUS] = $line_ref;
    }

    create_text_in_line( $edit_ref, $line_ref );
    return $line_ref;
}

#----------------------------------------------------------
# "In memory" functions
#----------------------------------------------------------

sub create_text_in_line {
    my ( $edit_ref, $line_ref ) = @_;

    # Suppression de tous les éventuels éléments texte contenus dans la ligne
    # Affichage de la mémoire avant / après : gain ?

    my @text_element;
    if ( $edit_ref->[SUB_REF] ) {
# Une procédure de gestion de la coloration syntaxique a été donnée : on l'appelle
        @text_element = $edit_ref->[SUB_REF]->( $line_ref->[TEXT] );
    }
    else {
    # Pas de procédure de coloration syntaxique récupérée :
    # il n'y aura qu'un seul élément texte sur la ligne avec la police "default"
        $text_element[0] = [ $line_ref->[TEXT], 'default' ];
    }

    my $previous_element_ref;
    my $abs = $edit_ref->[SCREEN][MARGIN];

    my $total_letters = 0;
  ELT: for my $element_ref (@text_element) {
        
        my $text_ref;
         # Cette variable est locale, mais elle subsitera après le 'for' (références créées)

        $text_ref->[TEXT] = $element_ref->[0];
        if (    ( length( $text_ref->[TEXT] ) == 0 )
            and ( length( $line_ref->[TEXT] ) != 0 ) )
        {
            next ELT;
        }
        $total_letters += length( $text_ref->[TEXT] );
        my $format = $element_ref->[1];
        if ( ! $edit_ref->[H_FONT]{$format} ) {
            print "Pas de font pour le format : $format\n";
            exit 1;
        }
        $text_ref->[FONT]  = $edit_ref->[H_FONT]{$format};
        $text_ref->[COLOR] = $color{$format};
        if ( !$color{$format} ) {
            print "Pas de couleur pour le format : $format\n";
            exit 1;
        }

 #print "graphic = $edit_ref->[GRAPHIC],$text_ref->[TEXT]:$text_ref->[FONT]:\n";
        if ( $zzz ) {
            print "Recherche longueur de |$text_ref->[TEXT]|$text_ref->[FONT]|\n";
        }
 
        $text_ref->[WIDTH] =
          $edit_ref->[GRAPHIC]
          ->length_text( $text_ref->[TEXT], $text_ref->[FONT] );
        $text_ref->[ABS] = $abs;
        $abs += $text_ref->[WIDTH];
        $text_ref->[LINE_REF] = $line_ref;

        #$line_ref->[SIZE]  += $text_ref->[WIDTH];

        if ($previous_element_ref) {
            $previous_element_ref->[NEXT] = $text_ref;
            $text_ref->[PREVIOUS]         = $previous_element_ref;
        }
        else {
            $line_ref->[FIRST] = $text_ref;
        }
        $previous_element_ref = $text_ref;
    }
    $line_ref->[SIZE] = $abs;
    if ( $total_letters != length( $line_ref->[TEXT] ) ) {
        print
"Eléments renvoyés incohérents pour la ligne |$total_letters|$line_ref->[TEXT]|",
          length( $line_ref->[TEXT] ), "|\n";
        print "\n\n===> pas de coloration syntaxique pour cette ligne\n";
        print "$line_ref->[TEXT]\n";

        # Suppression des éléments précédemment créés
        my $text_ref = $line_ref->[FIRST];
        print "$text_ref->[TEXT]";
        while ( $text_ref->[NEXT] ) {
            if ( $text_ref->[PREVIOUS] ) {
                undef $text_ref->[PREVIOUS][NEXT];
                undef $text_ref->[PREVIOUS];
            }
            print "$text_ref->[NEXT][TEXT]";

            #undef $text_ref->[LINE_REF];
            $text_ref = $text_ref->[NEXT];
        }
        $line_ref->[FIRST][TEXT] = $line_ref->[TEXT];
        $text_ref->[FONT]        = $edit_ref->[H_FONT]{"default"};
        $text_ref->[COLOR]       = $color{"default"};
        $text_ref->[WIDTH]       =
          $edit_ref->[GRAPHIC]
          ->length_text( $text_ref->[TEXT], $text_ref->[FONT] );
        $text_ref->[ABS]      = $edit_ref->[SCREEN][MARGIN];
        $text_ref->[LINE_REF] = $line_ref;
        $line_ref->[SIZE] = $text_ref->[WIDTH] + $edit_ref->[SCREEN][MARGIN];
    }
    return $line_ref;    # Valeur de retour sans intérêt ?
}

sub delete_text_in_line {
    my ( $edit_ref, $line_ref ) = @_;

    # On ne sait pas travailler avec des morceaux de lignes (mode wrap)
    # --> concaténation, il faudra réafficher...
    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
    }
    while ( $line_ref->[NEXT_SAME] ) {
        concat( $edit_ref, $line_ref, 'bottom' );
    }
    my $text_ref = $line_ref->[FIRST];
    my $next_text_ref;
    while ( $text_ref->[NEXT] ) {
        $next_text_ref = $text_ref->[NEXT];
        undef $text_ref->[NEXT];
        undef $next_text_ref->[PREVIOUS];
        $text_ref = $next_text_ref;
    }
    undef $next_text_ref->[PREVIOUS];
    undef $line_ref->[FIRST];
    return $line_ref;
}

#----------------------------------------------------------
# From memory to display functions
#----------------------------------------------------------

sub display_text_from_memory {
    my ( $edit_ref, $text_ref, $ord, $tag_ref ) = @_;

    my @tag;
    if ( defined $tag_ref ) {
        @tag = ( 'tag', $tag_ref );
    }
    else {
        @tag = ( 'tag', [ 'text', 'just_created' ] );
    }
    my ( $width, $height );
    ( $text_ref->[ID], $width, $height ) =
      $edit_ref->[GRAPHIC]->create_text_and_mark_it(
        {
            'abs'    => $text_ref->[ABS] - $edit_ref->[SCREEN][VERTICAL_OFFSET],
            'ord'    => $ord,
            'text'   => $text_ref->[TEXT],
            'anchor' => 'sw',
            'font'   => $text_ref->[FONT],
            'color'  => $text_ref->[COLOR],
            @tag
        }
      );

    #    if (!$text_ref->[WIDTH]) {
    $text_ref->[WIDTH] =
    $edit_ref->[GRAPHIC]->length_text( $text_ref->[TEXT], $text_ref->[FONT] );

#$text_ref->[ORD] = $ord;
#print "|", $text_ref->[TEXT], "|", $width, "|", $text_ref->[WIDTH], "|", $height, "|\n";
#    }
    return ( $text_ref->[WIDTH], $height );
}

sub check_cursor {
    # Une ligne complète vient d'être affichée
    my ( $edit_ref, $line_ref ) = @_;

    if (    $edit_ref->[CURSOR]
        and $edit_ref->[CURSOR][LINE_REF]
        and $line_ref->[REF] == $edit_ref->[CURSOR][LINE_REF][REF] )
    {

        # On utilise maintenant [CURSOR][POSITION_IN_LINE]
        my $prev_line_ref = start_line($line_ref);
        my $position      = $edit_ref->[CURSOR][POSITION_IN_LINE];
        DISP: while ( $position > length( $prev_line_ref->[TEXT] ) ) {
            $position -= length( $prev_line_ref->[TEXT] );
            $prev_line_ref = $prev_line_ref->[NEXT];
            if ( ! defined $prev_line_ref ) {
                print STDERR "Can't position cursor in display \"$edit_ref->[CURSOR][LINE_REF]\" or following (position $position)\n";
                $position = 0;
                $prev_line_ref = start_line($line_ref);
                last DISP;
            }
        }
        position_cursor_in_display( $edit_ref, $prev_line_ref, $position );
    }
}

sub trunc {

# Appelée lorsque l'on est en mode 'wrap' et que la ligne est trop longue par rapport à la largeur de l'écran
# On vient de lire un élément texte de trop qu'il va falloir tronquer :
#   $current_curs est trop grand (il comprend la totalité du mot à tronquer),
#   mais on ne sait pas de combien
    my ( $edit_ref, $line_ref, $text_ref, $current_curs, $where ) = @_;

    my $position = 0;
    {
        my $length_substr = 0;
        while ( ( $text_ref->[ABS] + $length_substr ) <
            ( $edit_ref->[SCREEN][WIDTH] - $edit_ref->[SCREEN][MARGIN] ) )
        {
            $position += 1;
            my $substr = substr( $text_ref->[TEXT], 0, $position );
            $length_substr =
              $edit_ref->[GRAPHIC]->length_text( $substr, $text_ref->[FONT] );
        }
    }
    if ($position) {
# On ne peut pas avoir un nombre de caractères négatifs : on sait que le texte précédent rentre
# (il n'a pas dépassé la longueur pour déclencher le trunc avant, mais il peut être tombé sur la limite : égalité)
# Il est possible de ne mettre aucun caractère du "$text_ref" actuel mais pas -1
#  ==> Le test de "$position" à vrai est donc pour le cas où l'on ne rentre même pas dans la
# boucle "while" précédente
# Ce cas très particulier arrive uniquement lorsqu'il y a égalité entre $text_ref->[ABS] et la partie droite
        $position -= 1;
    }
#print "Dans trunc MT |", length($line_ref->[TEXT]), "| M1 |",  $position, "| M2 |", length($line_ref->[TEXT]) - $position, "|\n";
    return divide_line( $edit_ref, $line_ref, $text_ref,
        $current_curs - length( $text_ref->[TEXT] ) + $position,
        $position, $where );
}

sub divide_line {
# On divise une ligne en 2 (création d'une nouvelle ligne) :
#    - soit parce que l'on est en mode 'wrap' et que la ligne est trop longue (dans
#         ce cas, $new est 'false')
#    - soit parce que l'on en crée une (appui sur "return"), $new est 'true'
#
#
    my ( $edit_ref, $line_ref, $text_ref, $position_in_line, $position_in_text,
        $where, $new )
      = @_;

    $edit_ref->[GRAPHIC]->change_text_item_property( $text_ref->[ID],
        substr( $text_ref->[TEXT], 0, $position_in_text ),
    );

    my $new_line_ref;
    $new_line_ref->[TEXT] = substr( $line_ref->[TEXT], $position_in_line );
    $line_ref->[TEXT] = substr( $line_ref->[TEXT], 0, $position_in_line );
    my $first_text_ref;
    @{$first_text_ref} =
      @{$text_ref};    # Eléments égaux, mais référence différente
    $first_text_ref->[TEXT] = substr( $text_ref->[TEXT], $position_in_text );
    $text_ref->[TEXT] = substr( $text_ref->[TEXT], 0, $position_in_text );
    undef $first_text_ref->[PREVIOUS];

    if ( $position_in_text == 0 ) {
        undef $text_ref->[PREVIOUS][NEXT];
        undef $text_ref->[PREVIOUS];
    }
    undef $text_ref->[NEXT];

    # Mise à jour de $first_text_ref->[WIDTH] à voir
    if ( $first_text_ref->[NEXT] ) {
        $first_text_ref->[NEXT][PREVIOUS] = $first_text_ref;
    }

    # Recalcul de la hauteur de la ligne fraichement tronquée
    $line_ref->[HEIGHT] = 0;
    my $temp_text_ref = $line_ref->[FIRST];
    while ($temp_text_ref) {
        my ( $width, $height ) =
          $edit_ref->[GRAPHIC]->size_id( $temp_text_ref->[ID] );
        $line_ref->[HEIGHT] = $height if ( $height > $line_ref->[HEIGHT] );
        $temp_text_ref = $temp_text_ref->[NEXT];
    }

    $new_line_ref->[FIRST]    = $first_text_ref;
    $new_line_ref->[PREVIOUS] = $line_ref;
    if ( !$new ) {
        $new_line_ref->[PREVIOUS_SAME] = 1;
    }

    $new_line_ref->[NEXT]       = $line_ref->[NEXT];
    $new_line_ref->[NEXT_SAME]  = $line_ref->[NEXT_SAME];
    $line_ref->[NEXT][PREVIOUS] = $new_line_ref;
    $line_ref->[NEXT]           = $new_line_ref;
    if ( !$new ) {
        $line_ref->[NEXT_SAME] = 1;
    }
    else {
        $line_ref->[NEXT_SAME] = 0;
    }
    while ($first_text_ref) {
        $first_text_ref->[LINE_REF] = $new_line_ref;
        $first_text_ref = $first_text_ref->[NEXT];
    }
    if ( length( $text_ref->[TEXT] ) == 0 ) {
        suppress_text( $edit_ref, $text_ref );
    }
    $new_line_ref->[REF] = $line_ref->[REF];

    if ( $edit_ref->[CURSOR][LINE_REF] == $line_ref ) {
        if ( $edit_ref->[CURSOR][POSITION_IN_DISPLAY] >
            length( $line_ref->[TEXT] ) )
        {
            $edit_ref->[CURSOR][POSITION_IN_DISPLAY] -=
              length( $line_ref->[TEXT] );
            $edit_ref->[CURSOR][LINE_REF] = $new_line_ref;

# Impossible de positionner le curseur à ce stade : les éléments texte ne sont pas encore créés
        }
    }
    return $new_line_ref;
}

sub concat {
    my ( $edit_ref, $line_ref, $where ) = @_;

  # Si l'on concatène, c'est que l'on n'a pas encore affiché :
  # par précaution, il faut supprimer tous les éléments texte canevas
  # des 2 lignes à concaténer, car si sur une des 2 lignes concaténées, il
  # y en a une qui est déjà affichée, on va la réafficher et perdre la référence
  # des éléments texte canevas précédents (qui ne seront donc plus supprimables)
    suppress_from_screen_line( $edit_ref, $line_ref );
    suppress_from_screen_line( $edit_ref, $line_ref->[NEXT] );

    $line_ref->[TEXT] = $line_ref->[TEXT] . $line_ref->[NEXT][TEXT];

    if ( $line_ref->[NEXT][NEXT] ) {
        $line_ref->[NEXT][NEXT][PREVIOUS] = $line_ref;
    }
    $line_ref->[NEXT_SAME] = $line_ref->[NEXT][NEXT_SAME];
    my $text_ref = $line_ref->[FIRST];
    while ( $text_ref->[NEXT] ) {
        $text_ref = $text_ref->[NEXT];
    }
    $text_ref->[NEXT] = $line_ref->[NEXT][FIRST];
    $line_ref->[NEXT][FIRST][PREVIOUS] = $text_ref;
    while ( $text_ref->[NEXT] ) {
        $text_ref = $text_ref->[NEXT];
        $text_ref->[LINE_REF] = $line_ref;
    }

    if ( $edit_ref->[CURSOR][LINE_REF] == $line_ref->[NEXT] ) {
        $edit_ref->[CURSOR][LINE_REF] = $line_ref;
        $edit_ref->[CURSOR][POSITION_IN_DISPLAY] +=
          length( $line_ref->[TEXT] ) - length( $line_ref->[NEXT][TEXT] );
    }
    $line_ref->[NEXT] = $line_ref->[NEXT][NEXT];

    return $line_ref;
}

sub suppress_from_screen_line {
    my ( $edit_ref, $line_ref, $speed ) = @_;

    my $text_ref = $line_ref->[FIRST];

    while ($text_ref) {

        #print "$text_ref->[TEXT]|";
        $edit_ref->[GRAPHIC]->delete_text_item( $text_ref->[ID], $speed );
        delete $text_ref->[ID];
        my $next_ref = $text_ref->[NEXT];
        delete $text_ref->[PREVIOUS];
        delete $text_ref->[NEXT];
        $text_ref = $next_ref;

        #last TEXT if ( !$text_ref );
    }

    #print "\n";
    $line_ref->[DISPLAYED] = 0;

    # Libération de la référence et ménage interne à Abstract.pm
}

sub suppress_from_screen_complete_line {
    my ( $edit_ref, $line_ref ) = @_;

    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
    }
    suppress_from_screen_line( $edit_ref, $line_ref );
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
        suppress_from_screen_line( $edit_ref, $line_ref );
    }
}

sub suppress_text {
    my ( $edit_ref, $text_ref ) = @_;
    if ( $text_ref->[ID] ) {
        $edit_ref->[GRAPHIC]->delete_text_item( $text_ref->[ID] );
    }
    if ( $text_ref->[PREVIOUS] ) {
        $text_ref->[PREVIOUS][NEXT] = $text_ref->[NEXT];
    }
    if ( $text_ref->[NEXT] ) {
        $text_ref->[NEXT][PREVIOUS] = $text_ref->[PREVIOUS];
    }
}

# Event management

# Hash of default labels

my %label = (
    '_calc_line_pos' => \&calc_line_pos,
    '_test_resize'   => \&test_resize,
    '_set_cursor'    => \&set_cursor,
    '_update_cursor' => \&update_cursor,
    '_show_editor'   => \&show_editor,
    '_zone_resize'   => \&zone_resize,
    '_drag_select'   => \&drag_select,
    '_wheel_move'    => \&wheel_move,
    '_key_code'      => \&key_code,
    '_key_default'   => \&key_default,
    '_exit',         => \&sequence_exit,
    '_jump',         => \&jump,
);

sub jump {
    my ( $self, $info_ref ) = @_;
    
    my $jump = $info_ref->{'jump'};
    if ( defined $jump ) {
        return ( $info_ref, $jump );
    }
    return ( $info_ref, q{} );
}

sub manage_sequence {
    my ( $edit_ref, $info_ref, $name, $default_ref ) = @_;
    
    my $sequence_ref = $default_ref;
    my $forced_ref = $edit_ref->[SEQUENCES]{$name};
    if ( defined $forced_ref and ref $forced_ref eq 'ARRAY' ) {
        $sequence_ref = $forced_ref;
    }
    execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
}

sub execute_sequence {
    my ( $edit_ref, $sequence_ref, $info_ref ) = @_;

    return if ( ! defined $sequence_ref or ref $sequence_ref ne 'ARRAY' );

    my $event_ref = $edit_ref->[EVENTS];
    my $editor = $edit_ref->[PARENT];
    my $label = q{}; # Avoid warning when testing undef value

    for my $step ( @$sequence_ref ) {
        #print STDERR "SEQUENCE $step\n";
        if ( ! ref $step ) {        
            if ( $label and $step ne $label ) {
                next;
            }
            my $sub_ref = undef;
            if ( $step =~ /^_/ ) {
                $sub_ref = $label{$step};
            
                return ($info_ref, q{}) if ( ! defined $sub_ref );
                
                # Séquence nommée
                ( $info_ref, $label ) = $sub_ref->( $edit_ref, $info_ref );
                return ( undef, $label ) if ( ! defined $info_ref );
                
            }
            elsif ( my $event = $event_ref->{$step} ) {
                $info_ref->{'label'} = $step;
                ( $info_ref, $label ) = execute_events( $event, $editor, $info_ref );
                if ( ref $label ) {
                    ( $info_ref, $label ) = execute_sequence ( $edit_ref, $label, $info_ref );
                }
                return ( undef, $label ) if ( ! defined $info_ref );
            }
            else {
                $label = q{};
            }
        }
        else {
            next if ( ref $step ne 'HASH' );
            my $dyn_label = $step->{'label'};
            next if ( $label and ( ! defined $dyn_label or $dyn_label ne $label ) );
            # Séquence dynamique : faire un reference_event suivi d'un execute_event
            # Tester aussi le libellé $step->{'label'}
        }
    }
    return ( $info_ref, $label );
}

sub wheel_move {
    my ( $edit_ref, $info_ref ) = @_;
    
    screen_move( $edit_ref, 0, $info_ref->{'move'} );
    return ( $info_ref, q{} );
}

sub calc_line_pos {
   my ( $edit_ref, $info_ref ) = @_;

    my $line_ref = get_line_ref_from_ord( $edit_ref, $info_ref->{'y'} );
    my $pos = get_position_from_line_and_abs( $edit_ref, $line_ref, $info_ref->{'x'} );
    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
        $pos += length ( $line_ref->[TEXT] );
    }
    $info_ref->{'line'} = $line_ref->[REF];
    $info_ref->{'pos'} = $pos;
    return ( $info_ref, q{} );
}

sub update_cursor {
    my ( $edit_ref, $info_ref ) = @_;

    my $x = $info_ref->{'x'};
    my $y = $info_ref->{'y'};
    
    if ( $x < 5 or $x > ( $edit_ref->[SCREEN][WIDTH] - 5 ) ) {
        #print "Il faut changer le curseur\n";
        cursor_set_shape ( $edit_ref, 'sb_h_double_arrow' );
    }
    elsif ( $y < 5 or $y > ( $edit_ref->[SCREEN][HEIGHT] - 5 ) ) {
        cursor_set_shape ( $edit_ref, 'sb_v_double_arrow' );
    }
    else {
        cursor_set_shape ( $edit_ref, 'arrow' );
    }

    return ( $info_ref, q{} );
}

sub show_editor {
    my ( $edit_ref, $info_ref ) = @_;

    make_visible( $edit_ref );

    return ( $info_ref, q{} );
}

sub wheel {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;

    $edit_ref = $pointed_by_mouse if ( defined $pointed_by_mouse );
    # Un peu trop lié à Tk... à revoir
    $info_ref->{'move'} = ( 3 * $info_ref->{'unit'} * $edit_ref->[SCREEN][LAST][HEIGHT] ) / 120;

    my $meta = $info_ref->{'meta'};
    $info_ref->{'true'} = $meta . 'wheel';
    
    my $caller = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID], 
        "User rolls the mouse wheel",
        $info_ref
    );
    $info_ref->{'caller'} = $caller;

    if ( defined $sequence_ref and ref $sequence_ref eq 'ARRAY' ) {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }
    elsif ( $meta ) {
        manage_sequence( $edit_ref, $info_ref, "${meta}wheel", [ 'any_wheel', "${meta}wheel" ] );
    }
    else {
        manage_sequence( $edit_ref, $info_ref, 'wheel', [ 'any_wheel', 'wheel', '_wheel_move', 'after_wheel' ] );
    }
    return $caller;
}

sub test_resize {
    my ( $edit_ref, $info_ref ) = @_;
    
    my $shape = $edit_ref->[GRAPHIC]->cursor_get_shape;

    if ( defined $shape and $shape =~ /^sb/ ) {
        # start of drag sequence for resize according to cursor shape
        if ( $shape eq 'sb_h_double_arrow' ) {
            if ( $info_ref->{'x'} < 5 ) {
                $edit_ref->[CURSOR][RESIZE] = 'left';
            }
            else {
                $edit_ref->[CURSOR][RESIZE] = 'right';
            }
        }
        else {
            if ( $info_ref->{'y'} < 5 ) {
                $edit_ref->[CURSOR][RESIZE] = 'top';
            }
            else {
                $edit_ref->[CURSOR][RESIZE] = 'bottom';
            }
        }
        $info_ref->{'resize'} = 1;
        return ($info_ref, 'any_after_clic');
    }
    return ( $info_ref, q{} );
}

sub set_cursor {
    my ( $edit_ref, $info_ref ) = @_;
    
    cursor_set( $edit_ref, $info_ref->{'pos'}, $info_ref->{'line'} );
    $edit_ref->[GRAPHIC]->canva_focus;
    Text::Editor::Easy::Abstract::Key::delete_start_selection_point ( $edit_ref );
    cursor_make_visible($edit_ref);
    
    return ( $info_ref, q{} );
}

sub double_clic {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;

    my $x     = $info_ref->{'x'};
    my $y     = $info_ref->{'y'};
    my $meta = $info_ref->{'meta'};
    
    my $name = $meta . 'double_clic';
    $info_ref->{'true'} = $name;
    $info_ref->{'caller'} = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID], 
        "User double-clicked at X = $x and Y = $y",
        $info_ref,
    );
    if ( ! defined $sequence_ref or ref $sequence_ref ne 'ARRAY' ) {
        $sequence_ref = [ 'calc_line_pos', 'any_any_clic', 'any_double_clic', "${meta}double_clic" ];
        manage_sequence( $edit_ref, $info_ref, $name, $sequence_ref );
    }
    else {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }
}

sub right_clic {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;

    my $x     = $info_ref->{'x'};
    my $y     = $info_ref->{'y'};
    my $meta = $info_ref->{'meta'};
    
    my $name = $meta . 'right_clic';
    $info_ref->{'true'} = $name;
    $info_ref->{'caller'} = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID], 
        "User right-clicked at X = $x and Y = $y",
        $info_ref,
    );
    if ( ! defined $sequence_ref or ref $sequence_ref ne 'ARRAY' ) {
        $sequence_ref = [ 'calc_line_pos', 'any_any_clic', 'any_right_clic', "${meta}right_clic" ];
        manage_sequence( $edit_ref, $info_ref, $name, $sequence_ref );
    }
    else {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }
}

sub clic {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;

    my $x     = $info_ref->{'x'} || 0; # Valeur 0 inutile.. àterme
    my $y     = $info_ref->{'y'} || 0; # Valeur 0 inutile.. àterme
    my $meta = $info_ref->{'meta'} || '';
    
    my $name = $meta . 'clic';
    $info_ref->{'true'} = $name;
    $info_ref->{'caller'} = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID], 
        "User clicked at X = $x and Y = $y",
        $info_ref
    );

    if ( ! defined $sequence_ref or ref $sequence_ref ne 'ARRAY' ) {
        if ( $meta ) {
            $sequence_ref = [ 
                '_calc_line_pos', 
                'any_any_clic',
                'any_clic',
                "${meta}clic",
                'any_after_clic',
            ];
        }
        else {
            $sequence_ref = [ 
                '_calc_line_pos', 
                'any_any_clic',
                'any_clic',
                'clic',
                '_test_resize',
                '_set_cursor',
                'any_after_clic',
                'after_clic',
            ];
        }
        manage_sequence( $edit_ref, $info_ref, $name, $sequence_ref );
    } 
    else {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }
}

sub motion {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;
    
    $pointed_by_mouse = $edit_ref;
    
    my $x     = $info_ref->{'x'};
    my $y     = $info_ref->{'y'};
    my $meta = $info_ref->{'meta'} || '';
    
    my $name = $meta . 'motion';
    $info_ref->{'true'} = $name;
    $info_ref->{'caller'} = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID], 
        "User moved mouse to X = $x and Y = $y", {
            'x' => $x,
            'y' => $y,
            'meta' => $meta,
        }
    );

    if ( ! defined $sequence_ref or ref $sequence_ref ne 'ARRAY' ) {
        if ( $meta ) {
            $sequence_ref = [ 
                '_calc_line_pos', 
                'any_motion',
                "${meta}motion",
                'any_after_motion',
            ];
        }
        else {
            $sequence_ref = [ 
                '_calc_line_pos', 
                'any_motion',
                'motion',
                '_show_editor',
                '_update_cursor',
                'any_after_motion',
                'after_motion',
            ];
        }
        manage_sequence( $edit_ref, $info_ref, $name, $sequence_ref );
    }
    else {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }

}

sub drag {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;

    $info_ref->{'shape'} = $edit_ref->[GRAPHIC]->cursor_get_shape;    
    my $x     = $info_ref->{'x'};
    my $y     = $info_ref->{'y'};
    
    my $meta = $info_ref->{'meta'};
    my $name = $meta . 'drag';
    $info_ref->{'true'} = $name;

    $info_ref->{'caller'} = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID], 
        "User 'dragged' to X = $x and Y = $y", {
            'x' => $x,
            'y' => $y,
            'meta' => $meta,
        }
    );
    if ( ! defined $sequence_ref or ref $sequence_ref ne 'ARRAY' ) {
        if ( $meta ) {
            $sequence_ref = [ 
                '_calc_line_pos',
                'any_drag', 
                "${meta}drag",
                'any_after_drag',
            ];
        }
        else {
            $sequence_ref = [ 
                '_calc_line_pos', 
                'any_drag', 
                'drag',
                '_zone_resize',
                '_drag_select',
                'any_after_drag',
                'after_drag',
            ];
        }
        manage_sequence( $edit_ref, $info_ref, $name, $sequence_ref );
    } 
    else {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }
}

sub zone_resize {
    my ( $edit_ref, $info_ref ) = @_;

    #print "Dans zone resize : x = $info_ref->{'x'}, y = $info_ref->{'y'}\n";
    my $shape;
    
    $shape = $info_ref->{'shape'} if ( defined $info_ref );
    if ( defined $shape and $shape =~ /^sb/ ) {
        Text::Editor::Easy::Motion::zone_resize(
            $edit_ref->[GRAPHIC]->get_zone,
            $edit_ref->[CURSOR][RESIZE],
            $info_ref,
        );
        return ( $info_ref, 'any_after_drag' );
    }
    
    return ( $info_ref, q{} );
}

#sub zone {
#    my ( $edit_ref ) = @_;
#    
#    return $edit_ref->[GRAPHIC]->get_zone;
#}

sub drag_select {
    my ( $edit_ref, $info_ref ) = @_;
   
    my $shape;
    $shape = $info_ref->{'shape'} if ( defined $info_ref );
    if ( defined $shape and $shape !~ /^sb/ ) {
        Text::Editor::Easy::Abstract::Key::motion_select( $edit_ref, $info_ref );
    }
    return ( $info_ref, q{} );
}

sub sequence_exit {
    return;
}

sub deselect {

    my ($self) = @_;

    $self->[GRAPHIC]->delete_select;
}

sub get_position_from_line_and_abs {
    my ( $edit_ref, $line_ref, $x ) = @_;

    my $position = 0;
    my $text_ref = $line_ref->[FIRST];
    while (
        $text_ref->[ NEXT
        ]   # Ne pas creer de tableau par autovivification si pas d'element NEXT
        and $text_ref->[NEXT][ABS] - $edit_ref->[SCREEN][VERTICAL_OFFSET] < $x
      )
    {
        $position += length( $text_ref->[TEXT] );
        $text_ref = $text_ref->[NEXT];
    }

# On pourrait, pour optimisation, renvoyer $text_ref (on va le rechercher à nouveau par la suite)
    my $text                         = $text_ref->[TEXT];
    my $abs                          = $text_ref->[ABS];
    my $cursor_position_in_text_item = 0;

    # On travaille par moitie de caractère
    return $position if ( !defined $text );    # Bug à voir
  CAR: for ( 1 .. length($text) ) {
        my $sous_chaine = substr( $text, $_ - 1, 1 );
        my $increment =
          $edit_ref->[GRAPHIC]->length_text( $sous_chaine, $text_ref->[FONT] );
        if ( ( $abs + $increment / 2 ) >
            ( $x + $edit_ref->[SCREEN][VERTICAL_OFFSET] ) )
        {
            last CAR;
        }
        $abs                          += $increment;
        $cursor_position_in_text_item += 1;
    }
    return $position + $cursor_position_in_text_item;
}

sub get_line_number_from_ord {
    my ( $edit_ref, $y ) = @_;

    my $line = $y / $edit_ref->[SCREEN][LINE_HEIGHT];
    return ( int($line) );
}

sub select_text_element {
    my ( $edit_ref, $text_ref, $cursor_position_in_text, $start_text ) = @_;

    $edit_ref->[CURSOR][TEXT_REF] = $text_ref;
    $edit_ref->[CURSOR][LINE_REF] = $text_ref->[LINE_REF];

    $edit_ref->[GRAPHIC]->position_cursor_in_text_item(
        $edit_ref->[CURSOR][TEXT_REF][ID],
        $cursor_position_in_text,

        # Pour GTK2, manipulation du curseur incompréhensible... ou impossible
        $edit_ref->[CURSOR][ABS],
        $edit_ref->[CURSOR][LINE_REF][ORD],
    );

    if ( defined($start_text) ) {
        $edit_ref->[CURSOR][POSITION_IN_DISPLAY] =
          $cursor_position_in_text + $start_text;
        $edit_ref->[CURSOR][POSITION_IN_LINE] =
          calc_line_position_from_display_position( $edit_ref->[CURSOR] );
    }
    $edit_ref->[CURSOR][POSITION_IN_TEXT] = $cursor_position_in_text;
}

sub calc_line_position_from_display_position {
    my ($cursor_ref) = @_;

    my $line_ref = $cursor_ref->[LINE_REF];
    my $position = $cursor_ref->[POSITION_IN_DISPLAY];
    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
        $position += length( $line_ref->[TEXT] );
    }
    return $position;
}

sub resize {
    my ( $edit_ref, $width, $height ) = @_;

    if ( $origin eq 'graphic' and !$sub_origin ) {
        $sub_origin = 'resize';
    }

    @window = $edit_ref->[GRAPHIC]->get_geometry;

    my $old_width = $edit_ref->[SCREEN][WIDTH];
    my $old_height = $edit_ref->[SCREEN][HEIGHT];

    $edit_ref->[SCREEN][WIDTH]  = $width;
    $edit_ref->[SCREEN][HEIGHT] = $height;

    if ( !$edit_ref->[SCREEN][FIRST] ) {

        # Au premier resize
        $edit_ref->[PARENT]->get_synchronized;
        init($edit_ref);
# On lance le "serveur" de thread mais uniquement lorsque l'éditeur est affiché entièrement (revoir dans le cas multi-fichier
# ==> désactivation puis réactivation ?)
#print "Dans Abstract resize, lancement de examine_external_request\n";

# Cette boucle, "multi-instances", ne doit être lancée qu'une seule fois (==> dans verify_graphic ?)
# Donc pas dans le premier resize de chaque éditeur
        my $id = $edit_ref->[GRAPHIC]->launch_loop( \&examine_external_request, 0.015 );
        $edit_ref->[GRAPHIC]->set_repeat_id( $id );
        
        return;
    }

    if ( $height == $old_height and ! $edit_ref->[SCREEN][WRAP] ) {
        # Optimisation à checker : en particulier, en cas d'offset, il faudrait déplacer éventuellement le canevas vers la gauche
        # pour voir plus de choses si l'on agrandit et que l'on était en limite droite à l'affichage
        check_offset( $edit_ref );
        return;
    }

# En cas de resize, on réaffiche en gardant constante la position de départ de la première ligne entière
    my $line_ref = get_first_complete_line($edit_ref);

    $edit_ref->display( $line_ref->[REF], { 'at' => 'top' } );
    check_offset( $edit_ref, 'end' );
}

sub check_offset {
    my ( $edit_ref, $end ) = @_;
    
    my $screen_ref = $edit_ref->[SCREEN];
    #if ( defined $end ) {
    #    print "Check_offset called from end\n";
    #}
    my $line_ref = $screen_ref->[FIRST];
    my $x_max = $line_ref->[SIZE];
    $line_ref = $line_ref->[NEXT];
    while ( $line_ref ) {
        my $x = $line_ref->[SIZE];
        $x_max = $x if ( $x > $x_max );
        $line_ref = $line_ref->[NEXT];
    }
    $x_max += $screen_ref->[MARGIN];
    my $offset = $screen_ref->[VERTICAL_OFFSET];
    my $shift = $screen_ref->[WIDTH] - ( $x_max - $offset );
    #print "VER OFFSET = $offset, x_max = $x_max, width ", $screen_ref->[WIDTH], "shift $shift\n";
    
    if ( $shift > 0 and $shift > $offset ) {
         $shift = $offset;
    }
    elsif ( $shift < 0 and $shift < $offset ) {
        $shift = $offset;
    }
    #print "VER OFFSET = $offset, x_max = $x_max, width ", $screen_ref->[WIDTH], "shift $shift\n";
    $screen_ref->[VERTICAL_OFFSET] -= $shift;
    $edit_ref->[GRAPHIC]->move_tag( 'all', $shift, 0 );
}

sub repeat {
    my ( $self, $seconds, $options_ref ) = @_;
    
    my $use = $options_ref->{'use'};
    if ( defined $use ) {
        if ( !$use{$use} ) {
            eval "use $use";
            if ($@) {
                print STDERR "Wrong code for module $use :\n$@\n";
            }
            $use{$use}{'messages'} = $@;
        }
    }
    my $package = $options_ref->{'package'} || 'main';
    my $sub = $options_ref->{'sub'};
    my $sub_ref = eval "\\&${package}::$sub";

    return $self->[GRAPHIC]->launch_loop( $sub_ref, $seconds );
}

sub repeat_class_method {
   # Cette méthode permet de ne pas réévaluer un autre module pour faire une tâche répétitive :
   # => le thread 0 est l'horloge qui donne le top mais il ne faut ni le saturer en traitements, ni charger sa mémoire en évaluation
   # de modules qu'il n'utiliserait pas
   my ( $self, $seconds, $method ) = @_;
      
   # Tk est plutôt moyen en ce sens que l'on ne peut pas donner de paramètre en plus de la callback 
   # aux procédures du genre "after"
   #              Mais perl est tellement dynamique !
   # ====>  Création de la nouvelle sub à la volée qui appelle la méthode de classe donnée en paramètre !!!
   my $sub_ref = sub { Text::Editor::Easy::Async->$method };
   
   return $self->[GRAPHIC]->launch_loop( $sub_ref, $seconds );
}

sub repeat_instance_method {
   my ( $self, $seconds, $method ) = @_;
      
   # Tk est plutôt moyen en ce sens que l'on ne peut pas donner de paramètre en plus de la callback 
   # aux procédures du genre "after"
   #              Mais perl est tellement dynamique !
   # ====>  Création de la nouvelle sub à la volée qui appelle la méthode d'instance donnée en paramètre !!!
   my $async = $self->[PARENT]->async;
   my $sub_ref = sub { $async->$method };
   
   return $self->[GRAPHIC]->launch_loop( $sub_ref, $seconds );
}

sub init {
    my ($edit_ref) = @_;

    my $ref = $edit_ref->[INIT_TAB]{'line_ref'};
    
    if ( ! defined $ref or ! defined ( $edit_ref->[PARENT]->line_text($ref) ) ) {
        if ( my $line_number = $edit_ref->[INIT_TAB]{'first_line_number'} ) {
            my $line = $edit_ref->[PARENT]->number( $line_number );
            $ref = $line->ref if ($line);
        }
        else {
            my $line = $edit_ref->[PARENT]->number(1);
            $ref = $line->ref if ($line);
            $edit_ref->[INIT_TAB]{'first_line_pos'} = 0;
        }
    }

    my $line_ref = undef;
    if ( ! $ref ) {
        $line_ref = read_next_line($edit_ref);
        if ( !$line_ref ) {

            print "Fichier vide : en pratique, pour affichage, une ligne vide\n";
            $line_ref->[TEXT] = "";
            $line_ref->[REF] = $edit_ref->[PARENT]->get_ref_for_empty_structure;
            create_text_in_line( $edit_ref, $line_ref );
            print "après création ligne vide : LINE REF = $line_ref\n";
            print "   REF = |", $line_ref->[REF], "|\n";
            print "   TEXTE = |", $line_ref->[TEXT], "|\n";
        }
        else {
            print "Récupéré line_ref de read_next_line : $line_ref\n";
        }
    }
    else {
        $line_ref = create_line_ref_from_ref( $edit_ref, $ref );

        # Cas où la ligne est indéfinie à gérer

    }
    if ( my $line_ord = $edit_ref->[INIT_TAB]{'first_line_ord'} ) {
        $edit_ref->display( $line_ref->[REF], { 'at' => $line_ord, 'from' => 'bottom', 'no_check' => 1 } );
    }
    elsif ( my $line_at = $edit_ref->[INIT_TAB]{'first_line_at'} ) {
        $edit_ref->display( $line_ref->[REF], { 'at' => $line_at } );
    }
    else {
        print "Pas de configuration trouvée pour l'affichage de LINE REF = ", $line_ref->[REF], "\n";
        $edit_ref->display( $line_ref->[REF], { 'at' => 'top' } );
    }

    # Positionnement du curseur
    my $ref_cursor;
    if ( my $cursor_number = $edit_ref->[INIT_TAB]{'cursor_line_number'} ) {
        my $line = $edit_ref->[PARENT]->number( $cursor_number );
    if ( defined $line ) {
            $ref_cursor = $line->ref;
        }
    }
    if ( ! defined $ref_cursor ) {
        $ref_cursor = $line_ref->[REF];
        $edit_ref->[INIT_TAB]{'cursor_pos'} = 0;
    }

#print "Référence trouvée pour le curseur : $ref\n";
# Recherche de la référence parmi les lignes déjà créées lors du display_from_top_line
    my $cursor_line_ref = $edit_ref->[SCREEN][FIRST];
  REF: while ( $cursor_line_ref->[REF] != $ref_cursor ) {

        #print "Référence courante : ", $cursor_line_ref->[REF], "\n";
        if ( $cursor_line_ref->[NEXT] ) {
            $cursor_line_ref = $cursor_line_ref->[NEXT];
        }
        else {
            last REF;
        }
    }
    if ( $cursor_line_ref->[REF] != $ref_cursor ) {
# A la dernière sauvegarde de session, le curseur n'était pas dans la zone affichable
# Pour l'instant non géré : on le place au début de la première ligne affichée à l'écran
# A modifier éventuellement lorsque le curseur pourra être hors de l'écran à l'initialisation
        $cursor_line_ref = $line_ref;
        $edit_ref->[INIT_TAB]{'cursor_pos'} = 0;
    }
    $edit_ref->[CURSOR][LINE_REF] = $cursor_line_ref;
    cursor_set( $edit_ref, $edit_ref->[INIT_TAB]{'cursor_pos'} );
    #print "Fin de init\n";
}

sub get_first_complete_line {
    my ($edit_ref) = @_;

# A partir de quelle ligne afficher et à quelle position : on regarde la position de $edit_ref->[SCREEN][FIRST]
    if ( !$edit_ref->[SCREEN][FIRST] ) {
        return;
    }
    my $line_ref = $edit_ref->[SCREEN][FIRST];
    while ($line_ref->[ORD] + $line_ref->[HEIGHT] < 0
        or $line_ref->[PREVIOUS_SAME] )
    {

# Très rare de ne pas avoir de NEXT==> uniquement si la ligne occupe plus d'un écran
        if ( !$line_ref->[NEXT] ) {
            return $edit_ref->[SCREEN][FIRST];
        }
        $line_ref = $line_ref->[NEXT];
    }
    return $line_ref;
}

sub clear_screen {
    my ($edit_ref) = @_;

    my $line_to_suppress_ref = $edit_ref->[SCREEN][FIRST];
    $edit_ref->[GRAPHIC]->delete_select;
    return if ( !$line_to_suppress_ref );

    #SUPP: while ($line_to_suppress_ref->[DISPLAYED] ) {
  SUPP: while ( $line_to_suppress_ref->[NEXT] ) {
        suppress_from_screen_line( $edit_ref, $line_to_suppress_ref );
        $line_to_suppress_ref = $line_to_suppress_ref->[NEXT];
        last SUPP if ( !$line_to_suppress_ref );
    }

    # Vérification pour traquer le bug des lignes qui ne s'effacent pas

    $edit_ref->[GRAPHIC]->clear_screen;
}

sub key {
    my ( $edit_ref, $info_ref, $sequence_ref ) = @_;


    #print STDERR "Dans l'évènement key de Abstract\n";
    my $key   = $info_ref->{'key'};

    if ( $origin eq 'graphic' and !$sub_origin ) {
        $sub_origin = 'key';
    }

    my $special;
    if ( $info_ref->{'meta_hash'}{'ctrl'} or $info_ref->{'meta_hash'}{'alt'} ) {
        $special = 1;
    }
    my $key_code = $info_ref->{'meta'} . $key;
    $info_ref->{'key_code'} = $key_code;
    $info_ref->{'true'} = $key_code . '_key';
    #print "KEY CODE : $key_code\n";
    #return;
    my $caller = Text::Editor::Easy->trace_user_event( 
        $edit_ref->[ID],
        "User pressed key $key_code",
        $info_ref
    );
    $sub_sub_origin = $key_code;
    $info_ref->{'caller'} = $caller;
    
    if ( ! defined $sequence_ref or $sequence_ref ne 'ARRAY' ) {
        $sequence_ref = [
            'any_any_key',
            "any_${key}_key",
            "${key_code}_key",
            '_key_code',
            '_key_default',
        ];
        manage_sequence( $edit_ref, $info_ref, $key_code, $sequence_ref );
    }
    else {
        execute_sequence ( $edit_ref, $sequence_ref, $info_ref );
    }
    return $caller;
}

sub key_code {
    my ( $edit_ref, $info_ref ) = @_;
    
    my $key_code = $info_ref->{'key_code'};
    
    #print STDERR "Dans key_code $key_code\n";
    
    my $reference = $edit_ref->[KEY]{$key_code};
    if ( ! $reference ) {
        $reference = $key{$key_code};
    }

    if ( $reference ) {

        # Une touche speciale a ete appuyee
        if ( ref( $reference ) eq "CODE" ) {

            #print STDERR "Touche spéciale...\n";
            #$key{$key_code}->( $edit_ref );
            #eval {
                $reference->( $edit_ref->[PARENT], $info_ref );
            #};
            #print "Wrong code for key $key_code : $@\n" if ( $@ );
        }
        else {
            #print STDERR "Touche spéciale...avec tableau\n";
            my @tab      = @{ $reference };
            my $code_ref = shift @tab;

            #$code_ref->( $edit_ref, @tab );
            my $first_parameter = shift @tab;
            if ( $first_parameter eq 'Abstract' ) {
                $first_parameter = $edit_ref;
            }
            else {
                $first_parameter = $edit_ref->[PARENT];
            }
            $code_ref->( $first_parameter, @tab );
        }
        #Text::Editor::Easy::Async->end_of_user_event( $edit_ref->[ID] );
        return;
    }
    return ( $info_ref, q{} );
}

sub key_default {
    my ( $edit_ref, $info_ref ) = @_;
    
    my $text = $info_ref->{'text'};
    my $special;
    if ( $info_ref->{'meta_hash'}{'ctrl'} or $info_ref->{'meta_hash'}{'alt'} ) {
        $special = 1;
    }

    #if ( length($text) != 1 or $special ) {
    if ( $special ) {
        #Text::Editor::Easy::Async->end_of_user_event( $edit_ref->[ID] );
        return ( $info_ref, q{} );
    }
    else {
        #print STDERR "Ascii = $ascii\n";
        #print STDERR "special = $special\n";
    }
    
    if ( defined $edit_ref->[SELECTION] ) {
        Text::Editor::Easy::Abstract::Key::delete_selection($edit_ref);
    }
    
    # assist doit pointer sur une référence à un package ou une fonction
    insert( $edit_ref, $text,
        { 'assist' => $edit_ref->[ASSIST], 'indent' => 'auto' } );
    #Text::Editor::Easy::Async->end_of_user_event( $edit_ref->[ID] );
    return ( $info_ref, q{} );
}

sub cursor_make_visible {
    my ($edit_ref) = @_;

    #print "Dans cursor_make_visible $edit_ref|", $edit_ref->[ID], "|\n";
    verify_if_cursor_is_visible_horizontally($edit_ref);
    verify_if_cursor_is_visible_vertically($edit_ref);
}

sub verify_if_cursor_is_visible_horizontally {
    my ($edit_ref) = @_;

    # bottom
    my ( $top, $bottom, $displayed );
    my $cursor_line_ref = $edit_ref->[CURSOR][LINE_REF];
    
# Vérification que la ligne qui porte le curseur fait bien partie des lignes affichées
    if ( $cursor_line_ref == $edit_ref->[SCREEN][FIRST] ) {
        $top       = 1;
        $displayed = 1;
    }
    else {
        my $line_ref = $edit_ref->[SCREEN][FIRST];
      LINE: while ( $line_ref->[NEXT] ) {
            $line_ref = $line_ref->[NEXT];
            if ( $line_ref == $cursor_line_ref ) {
                $displayed = 1;
                last LINE;
            }
        }
        if ( $edit_ref->[SCREEN][LAST] == $cursor_line_ref ) {
            $bottom = 1;
        }
    }
    if ( !$displayed ) {
        #print "Ligne non affichée : display\n";
        return $edit_ref->display( $cursor_line_ref->[REF],
            { 'at' => 'middle' } );
    }

    # La ligne qui contient le curseur est déjà affichée sur le 'canevas'
    # ==> il est possible qu'elle ne soit pas visible ou qu'elle soit tronquée

# Inutile d'essayer de caser la ligne si l'écran est trop petit : tests supplémentaires à faire

# On suppose maintenant que l'écran est assez grand pour positionner au moins 2 lignes entières en hauteur

    # Vérification en haut
    if ( !$cursor_line_ref->[PREVIOUS] ) {
        my $previous_line_ref =
          read_previous_line( $edit_ref, $cursor_line_ref );
        if ( !$previous_line_ref ) {

            # On positionne la ligne qui contient le curseur en haut de l'écran
            my $ord = $cursor_line_ref->[ORD];
            return screen_move( $edit_ref, 0,
                $cursor_line_ref->[HEIGHT] - $ord );
        }
        $edit_ref->[SCREEN][FIRST] =
          display_line_from_bottom( $edit_ref, $previous_line_ref,
            $cursor_line_ref->[ORD] - $cursor_line_ref->[HEIGHT] );
    }

# On a une ligne précédente
# Le curseur est bien positionné vis-à-vis du haut si la ligne précédente est vue entièrement
    my $previous_line_ref = $cursor_line_ref->[PREVIOUS];
    
    if ( $previous_line_ref->[ORD] - $previous_line_ref->[HEIGHT] < 0 ) {
        screen_move( $edit_ref, 0,
            $previous_line_ref->[HEIGHT] - $previous_line_ref->[ORD] );
    }
    #print "Dicho : avant Plantage ?\n";
    # Le curseur est assez loin du haut, on regarde en bas
    my $next_line_ref = $cursor_line_ref->[NEXT];
    if ( !$next_line_ref ) {
        #print "Dicho : est-on avant le Plantage ?\n";
        #$zzz = 1;
        
        $next_line_ref = read_next_line( $edit_ref, $cursor_line_ref );
        if ( !$next_line_ref ) {

            #print "Pas de référence trouvée...\n";
            # On positionne la ligne qui contient le curseur en bas de l'écran
            my $shift = $edit_ref->[SCREEN][HEIGHT] - $cursor_line_ref->[ORD];
            return if ( $shift > 0 );
            return screen_move( $edit_ref, 0, $shift );
        }

        #print "Dicho : encore avant Plantage ?\n";
        $edit_ref->[SCREEN][LAST] =
          display_line_from_top( $edit_ref, $next_line_ref, $cursor_line_ref->[ORD] );
        add_tag_complete( $edit_ref, $edit_ref->[SCREEN][LAST], 'bottom' );
    }
    


# On a une ligne suivante
# Le curseur est bien positionné vis-à-vis du bas si la ligne suivante est vue entièrement
    #print "Avant appel screen_move : \$next_line_ref = $next_line_ref\n",
    #    "\t\$edit_ref->[SCREEN][HEIGHT] = ", $edit_ref->[SCREEN][HEIGHT], "\n",
    #    "\t\$next_line_ref->[ORD] = ", $next_line_ref->[ORD], "\n",
    #    "\t\$cursor_line_ref = ", $cursor_line_ref, "\n",
    #    "\t\$cursor_line_ref->[ORD] = ", $cursor_line_ref->[ORD], "\n"; # 
    
    if ( $next_line_ref->[ORD] > $edit_ref->[SCREEN][HEIGHT] ) {
        if ( ! defined $next_line_ref->[ORD] ) {
            print "Abstract : problème à venir :\n",
              "\tligne $next_line_ref->[TEXT]\n";
        }
        #print "Avant retour de verify_if_cursor_is_visible_horizontally\n";
        return screen_move( $edit_ref, 0,
            $edit_ref->[SCREEN][HEIGHT] - $next_line_ref->[ORD] );
    }
}

sub verify_if_cursor_is_visible_vertically {
    my ($edit_ref) = @_;

    if ( $edit_ref->[SCREEN][WRAP] ) {

#                # On fait confiance au mode "wrap" pour ne pas être obligé de se décaler à droite ou à gauche
#                if ( $edit_ref->[SCREEN][VERTICAL_OFFSET] ) {
#                # On annule donc tout éventuel décalage
#                    my $decalage = -$edit_ref->[SCREEN][VERTICAL_OFFSET];
#                    $edit_ref->[CURSOR][ABS] -= $decalage;
#                    $edit_ref->[SCREEN][VERTICAL_OFFSET] = 0;
#                    $canva->move( 'text', -$decalage, 0 );
#                }
        return;
    }
    if ( $edit_ref->[CURSOR][ABS] + 20 > $edit_ref->[SCREEN][WIDTH] ) {
        my $decalage =
          $edit_ref->[CURSOR][ABS] + 20 - $edit_ref->[SCREEN][WIDTH];
        $edit_ref->[CURSOR][ABS]         -= $decalage;
        $edit_ref->[CURSOR][VIRTUAL_ABS] -= $decalage;
        $edit_ref->[SCREEN][VERTICAL_OFFSET] += $decalage;
        #$edit_ref->[GRAPHIC]->move_tag( 'text', -$decalage, 0 );
        $edit_ref->[GRAPHIC]->move_tag( 'all', -$decalage, 0 );
    }
    if ( $edit_ref->[CURSOR][ABS] < $edit_ref->[GRAPHIC]->margin ) {
        my $decalage = 10 - $edit_ref->[CURSOR][ABS];
        $edit_ref->[CURSOR][ABS]         += $decalage;
        $edit_ref->[CURSOR][VIRTUAL_ABS] += $decalage;
        $edit_ref->[SCREEN][VERTICAL_OFFSET] -= $decalage;
        #$edit_ref->[GRAPHIC]->move_tag( 'text', $decalage, 0 );
        $edit_ref->[GRAPHIC]->move_tag( 'all', $decalage, 0 );
    }
}

sub update_vertical_scrollbar {
    my ($edit_ref) = @_;
    return ( 0.2, 0.4 );

# Seules les positions dans le fichier nous interesse
# Non, impossible : les positions dans le fichier sont trop lourdes à mettre à jour en cas de saisie
# Il faut utiliser le nombre de lignes. Lorsque ce nombre n'est pas connu au départ (lecture d'un
# morceau de fichier) il faut calculer la taille moyenne d'une ligne en caractères et faire une
# estimation du nombre total de lignes à partir de cette taille moyenne

    my $start_cursor = get_line_number_from_ord( $edit_ref, 0 );
    my $end_cursor =
      get_line_number_from_ord( $edit_ref, $edit_ref->[SCREEN][HEIGHT] ) - 2;
    if ( $end_cursor < $start_cursor ) {
        $end_cursor = $start_cursor + 1;
    }
    my ( $first_ln, $last_ln ) = get_extreme_line_number();

    my $real_end = $last_ln - $first_ln;
    return $edit_ref->[GRAPHIC]->set_scrollbar(
        ( $start_cursor - $first_ln ) / $real_end,
        ( $end_cursor - $first_ln ) / $real_end,
    );
}

sub scrollbar_move {
    my ( $edit_ref, $action, $value, $unit ) = @_;

    #    print "Action $action, value $value, unit $unit\n";

    if ( $action eq "moveto" ) {
        my ( $x, $y ) = $edit_ref->[GRAPHIC]->get_scrollbar();
        if ( $value < 0 ) {
            $value = 0;
        }
        if ( $value > 1 ) {
            $value = 1;
        }

# Il ne faut pas forcément agir : si l'on veut descendre alors que l'on est déjà en bas...
        $edit_ref->[GRAPHIC]->set_scrollbar( $value, $value + $y - $x );
        print "Action $action, value $value\n";

        move_to($value);
    }
    else {

        # $action = 'scroll'
        if ( ( $value == 1 ) and ( $unit eq 'units' ) ) {
            screen_move( $edit_ref, 0, 1 );
        }
        if ( ( $value == -1 ) and ( $unit eq 'units' ) ) {
            screen_move( $edit_ref, 0, -1 );
        }
    }
}

sub suppress_top_invisible_lines {
    my ($edit_ref) = @_;

    my $screen_ref = $edit_ref->[SCREEN];

# On ne suprrime les "lignes fichier" qu'entièrement (avec le mode wrap, certaines "lignes fichiers" s'étalent sur
# plusieurs "lignes écran")
    my $line_ref = $screen_ref->[FIRST];
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
    }
    if ( $line_ref->[ORD] < 0 ) {
        if ( ! $line_ref->[NEXT] ) {
            #print STDERR "Screen too small !\n"; # Lines won't be suppressed
            return;
        }
        $screen_ref->[FIRST] = $line_ref->[NEXT];
        suppress_from_screen_line( $edit_ref, $line_ref, 'for_speed' );
        $line_ref->[NEXT][PREVIOUS] = undef;

        # Peut-être plusieurs lignes à supprimer ...
        while ( $line_ref->[PREVIOUS] ) {
            $line_ref = $line_ref->[PREVIOUS];
            suppress_from_screen_line( $edit_ref, $line_ref, 'for_speed' );
            $line_ref->[NEXT][PREVIOUS] = undef;
        }
    }
}

sub suppress_bottom_invisible_lines {
    my ($edit_ref) = @_;

    my $screen_ref = $edit_ref->[SCREEN];

# On ne suprrime les "lignes fichier" qu'entièrement (avec le mode wrap, certaines "lignes fichiers" s'étalent sur
# plusieurs "lignes écran")
    my $line_ref = $screen_ref->[LAST];
    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
    }
    if ( $line_ref->[ORD] - $line_ref->[HEIGHT] > $screen_ref->[HEIGHT] ) {
        $screen_ref->[LAST] = $line_ref->[PREVIOUS];
        $line_ref->[PREVIOUS][NEXT] = undef;

        # Peut-être plusieurs lignes à supprimer ...
        suppress_from_screen_line( $edit_ref, $line_ref, 'for_speed' );
        while ( $line_ref->[NEXT] ) {
            $line_ref = $line_ref->[NEXT];
            suppress_from_screen_line( $edit_ref, $line_ref, 'for_speed' );
            $line_ref->[PREVIOUS][NEXT] = undef;
        }
    }
}


sub screen_set_wrap {
    my ($edit_ref) = @_;

    return if ( $edit_ref->[SCREEN][WRAP] );

    wrap($edit_ref);
}

sub screen_unset_wrap {
    my ($edit_ref) = @_;

    return if ( !$edit_ref->[SCREEN][WRAP] );

    wrap($edit_ref);
}

sub wrap {
    my ($edit_ref) = @_;

# A partir de quelle ligne afficher et à quelle position : on regarde la position de screen_ref->[FIRST]
    my $line_ref = get_first_complete_line($edit_ref);

    clear_screen($edit_ref);

    if ( $edit_ref->[SCREEN][WRAP] ) {
        $edit_ref->[SCREEN][WRAP] = 0;
    }
    else {
        $edit_ref->[SCREEN][WRAP] = 1;

        # Suppression de l'éventuel décalage vertical
        $edit_ref->[SCREEN][VERTICAL_OFFSET] = 0;
    }

    $edit_ref->display( $line_ref->[REF], { 'at' => 'top' } );

    #cursor_make_visible ( $edit_ref );
}

sub change_title {
    my ( $edit_ref, $title ) = @_;

    #rint "Dans change title : $title\n";
    $edit_ref->[GRAPHIC]->change_title($title);
    #rint "Après change title\n";
}

sub inser {
    my ($edit_ref) = @_;

    if ( $edit_ref->[INSER] ) {
        $edit_ref->[INSER] = 0;
    }
    else {
        $edit_ref->[INSER] = 1;
    }
}

sub insert_mode {
    my ($edit_ref) = @_;

    return $edit_ref->[INSER];
}

sub set_insert {
    my ($edit_ref) = @_;

    $edit_ref->[INSER] = 1;
}

sub set_replace {
    my ($edit_ref) = @_;

    $edit_ref->[INSER] = 0;
}

sub editor_visual_search {
    my ( $edit_ref, $exp, $ref, $end, $not_first_call_ref ) = @_;
    # Maybe a useless complicated sub that will be suppressed
    # Could be replaced by a search call with good options followed by a line->select
    # Just a try to realise a long task in the graphic thread that can be stopped
    # (recursive asynchronous call with $last_graphic_event tested)
    
    #print "Dans visual_search : \$exp = $exp, \$ref = $ref, \$end = $end\n";

    my ( $start_ref, $stop_pos );
    if ( $not_first_call_ref ) {
        if ( defined $last_graphic_event ) {
            #print "Fin de editor_visual_search \$last_graphic_event = $last_graphic_event, sub_sub = $sub_sub_origin\n";
            return;
        }
        $start_ref = $not_first_call_ref->{'start_ref'};
        $stop_pos = $not_first_call_ref->{'stop_pos'};
    }
    else {
        ( $start_ref, $stop_pos ) = cursor_get ( $edit_ref );
        $not_first_call_ref->{'start_ref'} = $start_ref;
        $not_first_call_ref->{'stop_pos'} = $stop_pos;
        $not_first_call_ref->{'can_restart'} = 1;
    }

    #print "Mise à undef de \$last_graphic_event = $last_graphic_event, sub_sub = $sub_sub_origin\n";

    $last_graphic_event = undef;
    $sub_origin = undef; # devrait être inutile...
    my $line_ref = get_line_ref_from_ref ( $edit_ref, $ref );
    my $can_restart = $not_first_call_ref->{'can_restart'};
    if ( ! $line_ref ) {
        $line_ref = $edit_ref->[SCREEN][FIRST];
        $end = 0;
        $can_restart = 0;
    }
    $not_first_call_ref->{'can_restart'} = $can_restart;
    #print "2 : \$start_ref = $start_ref, \$stop_pos = $stop_pos, \$can_restart = $can_restart\n";

    my $text = $line_ref->[TEXT];
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
        $text .= $line_ref->[TEXT];
    }
    pos($text) = $end;
    if ( $text =~ m/($exp)/g ) {
        my $length    = length($1);
        my $end_pos   = pos($text);
        my $start_pos = $end_pos - $length;
        if ( $line_ref->[REF] == $start_ref and $start_pos > $stop_pos ) {
            return;
        }
        line_select ( $edit_ref, $ref, $start_pos, $end_pos, 'white' );
        $edit_ref->[PARENT]->async->editor_visual_search($exp, $ref, $end_pos, $not_first_call_ref );
        return;
    }
    return if ( $line_ref->[REF] == $start_ref and ! $can_restart);
    # Ligne suivante
    $line_ref = $line_ref->[NEXT];
    while ( $line_ref and $line_ref->[REF] != $start_ref ) {
        $text = $line_ref->[TEXT];
        while ( $line_ref->[NEXT_SAME] ) {
            $line_ref = $line_ref->[NEXT];
            $text .= $line_ref->[TEXT];
        }
        pos($text) = 0;
        if ( $text =~ m/($exp)/g ) {
            my $length    = length($1);
            my $end_pos   = pos($text);
            my $start_pos = $end_pos - $length;
            line_select ( $edit_ref, $line_ref->[REF], $start_pos, $end_pos, 'white' );
            $edit_ref->[PARENT]->async->editor_visual_search($exp, $line_ref->[REF], $end_pos, $not_first_call_ref );
            return;
        }
        $line_ref = $line_ref->[NEXT];
        if ( ! $line_ref and $can_restart ) {
            $line_ref = $edit_ref->[SCREEN][FIRST];
            $can_restart = 0;
            $not_first_call_ref->{'can_restart'} = 0;
        }
    }
    if ( $line_ref and $line_ref->[REF] == $start_ref ) {
        $edit_ref->[PARENT]->async->editor_visual_search($exp, $start_ref, 0, $not_first_call_ref );
    }
}

sub start_line {
    my ($line_ref) = @_;

    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
    }
    return $line_ref;
}

sub complete_line {
    my ($line_ref) = @_;

    $line_ref = start_line($line_ref);
    my $text = $line_ref->[TEXT];
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
        $text .= $line_ref->[TEXT];
    }
    return $text;
}

sub get_line_number {
    my ( $edit_ref, $line_ref ) = @_;

    return $edit_ref->[PARENT]->get_line_number_from_ref( $line_ref->[REF] );
}

sub get_displayed_editor {
    my ($edit_ref) = @_;

    #print "Dans Abstract : $edit_ref\n";
    return $edit_ref->[GRAPHIC]->get_displayed_editor();
}

sub get_screen_size {
    my ($edit_ref) = @_;

    return ( $edit_ref->[SCREEN][WIDTH], $edit_ref->[SCREEN][HEIGHT] );
}

sub change_reference {
    my ($edit_ref) = @_;

    $edit_ref->[GRAPHIC]->change_reference( $edit_ref, $edit_ref->[FILE] );
}

sub increase_font {
    my ($edit_ref) = @_;

    print "Taille de la fonte actuelle : $edit_ref->[SCREEN][FONT_HEIGHT]\n";
    $edit_ref->[SCREEN][FONT_HEIGHT] += 1;
    my %distinct_fonts;
    for my $font ( values %{$edit_ref->[H_FONT]} ) {
        $distinct_fonts{$font} = $font;
    }
    for my $font ( keys %distinct_fonts ) {
        $edit_ref->[GRAPHIC]->set_font_size( $distinct_fonts{$font},
            $edit_ref->[SCREEN][FONT_HEIGHT] );
    }
    $edit_ref->[SCREEN][LINE_HEIGHT] =
      17 * $edit_ref->[SCREEN][FONT_HEIGHT] / 13;
}

#sub get_positions {
#    return {
#        "first_line_number"  => $top_true_line_number,
#        "first_line_pos"     => $top_screen_line_number,
#        "cursor_line_number" => $cursor_true_line_number,
#        "cursor_pos_in_line" => $edit_ref->[CURSOR][POSITION_IN_DISPLAY]
#    };
#}

######################################################################
#
#  INTERFACE
#
######################################################################

sub test_new_insert {
    my ( $edit_ref ) = @_;

    my $text = $edit_ref->[GRAPHIC]->clipboard_get;
    my $options_ref = do 'options_ref.txt';
    # Test gros bloc
    #$text = "";
    #my $texte = " : ligne n° : ";
    #my $indice = 0;
    #while ( $indice++ < 100000 ) {
    #    $text .= "\n" . $indice . $texte . $indice;
    #}
    #
    #print "start time ", scalar(localtime), "\n";
    new_insert( $edit_ref, $text, $options_ref );
    #print "stop time ", scalar(localtime), "\n";
}

sub position_bottom_tag_from {
    my ( $edit_ref, $line_ref ) = @_;
    
    $edit_ref->[GRAPHIC]->delete_tag('bottom');
    
    while ( $line_ref ) {
        #print "Adding bottom tag to ", $line_ref->[TEXT], "\n";
        my $text_ref = $line_ref->[FIRST];
        while ( $text_ref ) {
            $edit_ref->[GRAPHIC]->add_tag( 'bottom', $text_ref->[ID] );
            $text_ref = $text_ref->[NEXT];
        }
        $line_ref = $line_ref->[NEXT];
    }
}

sub insert {
    my ( $edit_ref, $text, $options_ref ) = @_;

    if ( ! defined( $text ) or $text eq q{} ) {
        #print STDERR "No text to insert, no insert execution...\n";
        return;
    }
    
    $options_ref = {} if ( ! defined $options_ref );
    
    #print "Dans new insert : options_ref = ", dump( $options_ref ), "\n";
    #print "Text = |$text|\n";
    $text =~ s/\t/    /g;    # Suppression des tabulations

    my $display_should_be_done = 0;
    my $display_options = $options_ref->{'display'};
    my $search_ref = {};

    my @lines = split( /\n/, $text, -1 );
    my $size_line = scalar(@lines);

    if ( defined $display_options ) {
        if ( ref $display_options eq 'ARRAY' ) {
            $display_should_be_done = 1;
            my $line = $display_options->[0];
            if ( $line =~ /^line_(\d+)/ ) {
                $search_ref->{$1} = 0;
            }
            elsif ( $line eq 'line_end' ) {
                my $number = $size_line - 1;
                $search_ref->{$number} = 0;
                $display_options->[0] = "line_$number";
            }
        }
        else {
            $display_options = undef;
        }
    }

    # Insertion point
    # test du curseur
    my $ref = $edit_ref->[CURSOR][LINE_REF][REF];
    my $line_ref;
    $line_ref = get_line_ref_from_ref( $edit_ref, $ref );
    my $cursor_should_remain_visible = 0;
    if ( $line_ref ) {
        $cursor_should_remain_visible = 1;    
    }
    # option 'line'
    my $line_option = $options_ref->{'line'};
    my $insertion_point_is_given = 0;
    my $insert_is_visible = 0;
    if ( defined $line_option ) {
        $insertion_point_is_given = 1;
        $ref = $line_option;
        $line_ref = get_line_ref_from_ref( $edit_ref, $ref );        
        if ( defined $line_ref ) {
            $insert_is_visible = 1;
        }
    }
    elsif ( $cursor_should_remain_visible ) {
        $insert_is_visible = 1;        
    }
    my $initial_text = $edit_ref->[PARENT]->line_text( $ref );
    # options 'pos'
    my $pos_option = $options_ref->{'pos'};
    if ( defined $pos_option ) {
        $insertion_point_is_given = 1;
    }
    my $pos;
    my $initial_cursor_pos = $edit_ref->[CURSOR][POSITION_IN_LINE];
    if ( $insertion_point_is_given ) {
        if ( defined $pos_option ) {
            $pos = $pos_option;
            #print "Pos fixée à la valeur de pos_option, soit $pos\n";            
        }
        else {
            $pos = length( $initial_text );
            #print "Pos fixée à la fin de la ligne ref $ref, soit $pos\n";
        }
    }
    else {
        $pos = $initial_cursor_pos;
        #print "Pos fixée à la position actuelle du curseur, soit $pos\n";
    }
    
    my $replace = $options_ref->{'replace'}; 
    if ( ! defined $replace ) {
        if ( $edit_ref->[INSER] ) {
            $replace = 0;
        }
        else {
            $replace = 1;
        }
    }

    my $cursor_options = $options_ref->{'cursor'};
    if ( defined $cursor_options ) {
        if ( ref $cursor_options and ref $cursor_options eq 'ARRAY' ) {
            my $line = $cursor_options->[0];
            if ( $line =~ /^line_(\d+)/ ) {
                $search_ref->{$1} = 0;
            }
            elsif ( $line eq 'line_end' ) {
                $search_ref->{$size_line - 1} = 0;
            }
        }
    }
    #print "Search ref = ", dump( $search_ref ), "\n";

    my $answer_ref;
    if ( $size_line > 15 ) {
        #print "Insertion par bloc\n";
        my $wantarray = 0;
        if ( wantarray ) {
            $wantarray = 'true';
        }
        $answer_ref = bloc_insertion( $edit_ref, $ref, $pos, $replace, $search_ref, $wantarray, @lines );
        if ( $insert_is_visible ) {
            $display_should_be_done = 1;
        }
    }
    elsif ( $insert_is_visible ) {
        if ( $display_should_be_done ) {
            #print "Insertion non visuelle (display à venir)\n";
            $answer_ref = non_visual_insertion( $edit_ref, $ref, $initial_text, $pos, $replace, $search_ref, @lines );            
        }
        else {
            #visual_slurp( $edit_ref, 1 );
            $answer_ref = visual_insertion ( $edit_ref, $ref, $line_ref, $pos, $replace, $search_ref, @lines );
        }
    }
    else {
        #print "Insertion non visuelle\n";
        $answer_ref = non_visual_insertion( $edit_ref, $ref, $initial_text, $pos, $replace, $search_ref, @lines );
    }
    if ( $display_should_be_done ) {
        if ( defined $display_options ) {
            if ( $display_options->[0] =~ /^line_(\d+)/ ) {
                my $ref_line = $answer_ref->{'found'}{$1};
                if ( $ref_line ) {
                    display( $edit_ref, $ref_line, $display_options->[1] );
                    $cursor_should_remain_visible = 0;
                }
                else {
                    print STDERR "Can't find line_$1 for display call\n";
                    # Displaying things the same way
                    identical_display( $edit_ref );
                }
            }
            else {
                display( $edit_ref, @$display_options );
                $cursor_should_remain_visible = 0;
            }
        }
        else { # no $display_options but a display should be done
            identical_display( $edit_ref );
        }
    }
    # Vérification du curseur
    if ( defined $cursor_options ) {
        if ( ref $cursor_options ) {
            if ( ref $cursor_options eq 'ARRAY' ) {
                my $ref_line;
                if ( $cursor_options->[0] =~ /^line_(\d+)/ ) {
                    $ref_line = $answer_ref->{'found'}{$1};
                    if ( ! $ref_line ) {
                        print STDERR "Can't find line_$1 for setting cursor\n";
                    }
                }
                else {
                    $ref_line = $cursor_options->[0];
                }
                if ( $ref_line ) {
                    my $position = $cursor_options->[1];
                    if ( ! defined $position ) {
                        $position = length( $edit_ref->[PARENT]->line_text( $ref_line ) );
                    }
                    cursor_set( $edit_ref, $position, $ref_line );
                }
                else {
                    $cursor_options = 'at_end';
                }
            }
            else {
                print STDERR "Wrong reference type for cursor option in insert call|n";
                $cursor_options = 'at_end';
            }
        }
        elsif ( $cursor_options eq 'at_start' ) {
            cursor_set( $edit_ref, $pos, $ref );
        }
        elsif ( $cursor_options ne 'at_end' ) {
            print STDERR "Unknown cursor option $cursor_options during insert call\n";
            $cursor_options = 'at_end';
        }
    }
    elsif ( $insertion_point_is_given ) {
        if ( $ref == $edit_ref->[CURSOR][LINE_REF][REF] ) {
            if ( $initial_cursor_pos > $pos ) {
                #print "Le curseur doit être positionné dans la première partie de la dernière ligne\n";
                keep_cursor_position(
                    $edit_ref,
                    $initial_cursor_pos,
                    $pos,
                    $ref,
                    $answer_ref->{'last'},
                    $replace,
                    $lines[0],
                    $lines[$size_line - 1],
               );
            }
        }
        $cursor_options = 'no_move'; # useless but no warning (was undefined)
    }
    else {
        $cursor_options = 'at_end';
    }
    if ( $cursor_options eq 'at_end' ) {
        #print "Positionnement du curseur à la fin : cursor =", $edit_ref->[CURSOR], "\n";
        if ( $size_line > 1 ) {
            cursor_set( $edit_ref, length( $lines[$size_line - 1] ), $answer_ref->{'last'} ); 
        }
        else {
            cursor_set( $edit_ref, $pos + length( $lines[0] ), $ref ); 
        }
    }
    if ( $cursor_should_remain_visible ) {
        #print "Il faut vérifier et éventuellement faire un display\n";
        if ( ! cursor_visible( $edit_ref ) ) {
            display( $edit_ref, $edit_ref->[CURSOR][LINE_REF][REF], {
                'at' => 'bottom',
                'from' => 'bottom',
            } );
        }
    }
    #print "Réponse reçue ", dump( $answer_ref ), "\n";
    if ( $options_ref->{'assist'} ) {
        assist_on_inserted_text( $edit_ref->[PARENT], $text,
            $answer_ref->{'first_text'} );
    }
    
    test_insert_events( $edit_ref, $text, $initial_text );

    if ( wantarray ) {
        return @{ $answer_ref->{'return'} };
    }
    else {
        return $answer_ref->{'last'};
    }
}

sub keep_cursor_position {
    my ( $edit_ref, $cursor_pos, $insertion_pos, $insertion_line, $last_line, $replace, $text, $end_text ) = @_;
    
    print "Dans keep cursor position\n";
    my $length = length( $text );
    if ( $insertion_line == $last_line ) {
        print "Lignes identiques\n";
        if ( ! $replace ) {
            print "Mode replace\n";
            cursor_set( $edit_ref, $cursor_pos + $length, $insertion_line );
        }
        else {
            cursor_set( $edit_ref, $cursor_pos, $insertion_line );
        }
        return;
    }
    if ( $replace and ( $cursor_pos - $insertion_pos ) < $length ) {
        print "mode replace, longueur du texte importante\n";
        cursor_set( $edit_ref, $cursor_pos, $insertion_line );
        return;
    }
    if ( $replace ) {
        print "Mode replace, longueur du texte faible\n";
        cursor_set( $edit_ref, $cursor_pos - $length - $insertion_pos + length( $end_text ), $last_line );
    }
    else {
        print "Mode insert, plus d'une ligne\n";
        cursor_set( $edit_ref, $cursor_pos - $insertion_pos + length( $end_text ), $last_line );
    }
}

sub identical_display {
    my ( $edit_ref ) = @_;
    
    my $line_ref = $edit_ref->[SCREEN][FIRST];
    my $ref = $line_ref->[REF];
    my $top_ord = $line_ref->[ORD] - $line_ref->[HEIGHT];
    display( $edit_ref, $ref, { 'at' => $top_ord } );
}

sub visual_insertion {
    my ( $edit_ref, $ref, $line_ref, $pos, $replace, $search_ref, @lines ) = @_;
    
    print DBG "Début visual_insertion : LINES = ", dump(@lines), "\n";
    my $editor = $edit_ref->[PARENT];
    
    my ( $top_ord, $bottom_ord ) = get_line_ords( $line_ref );
    suppress_from_screen_line( $edit_ref, $line_ref );
    $line_ref = delete_text_in_line( $edit_ref, $line_ref );
    position_bottom_tag_from( $edit_ref, $line_ref->[NEXT] );
    
    my $complete_text = $line_ref->[TEXT];
    my $first = shift( @lines );
    my $text = substr ( $complete_text, 0, $pos ) . $first;

    my $inserted = 0;
    
    my $first_line_done = 0;
    my $bottom_line_ref;

    my $answer_ref = {};
    if ( scalar(@lines) ) {
        print DBG "Modif de la ligne 1 avec ref $ref\n $text\n", dump(@lines), "\n";
        
        $editor->modify_line( $ref, $text );
        $first_line_done = 1;
        $line_ref->[TEXT] = $text;
        create_text_in_line( $edit_ref, $line_ref );
        
        my $set_cursor = 'no_cursor';
        if ( $ref == $edit_ref->[CURSOR][LINE_REF][REF] ) {
            if ( $edit_ref->[CURSOR][POSITION_IN_LINE] <= length( $text ) ) {
                $set_cursor = undef;
            }
        }
        $bottom_line_ref = display_line_from_top( $edit_ref, $line_ref, $top_ord, $set_cursor );
        
        if ( defined $search_ref->{$inserted} ) {
            $search_ref->{$inserted} = $ref;
        }
        $answer_ref->{'first_text'} = $text;
        $text = pop( @lines );
        
        print DBG "visual_insertion, après ligne 1 : LINES = ", dump(@lines), "\n";
    }
    if ( ! $replace ) {
        $text .= substr ( $complete_text , $pos );
    }
    else {
        my $new_pos = $pos + length( $first );
        if ( length( $complete_text ) > $new_pos ) {
            $text .= substr ( $complete_text , $new_pos );
        }
    }
    if ( ! $first_line_done ) {
        print DBG "Modif l'unique ligne $ref\n $text\n";
        $editor->modify_line( $ref, $text );
        $line_ref->[TEXT] = $text;
        create_text_in_line( $edit_ref, $line_ref );
        $bottom_line_ref = display_line_from_top( $edit_ref, $line_ref, $top_ord, 'no_cursor' );
        if ( defined $search_ref->{$inserted} ) {
            $search_ref->{$inserted} = $ref;
        }
        if ( $bottom_line_ref->[ORD] != $bottom_ord ) {
            move_bottom( $edit_ref, $bottom_line_ref->[ORD] - $bottom_ord,
                $bottom_line_ref );
        }
        $answer_ref->{'first_text'} = $text;
        $answer_ref->{'found'} = $search_ref;
        $answer_ref->{'last'} = $ref;
        $answer_ref->{'return'} = [ $ref ];
        return $answer_ref;
    }
    
    my @return = ( $ref );
    # Intermediate lines
    print DBG "visual_insertion, avant while : LINES = ", dump(@lines), "\n";
    while ( @lines ) {
        print DBG "Ajout nouvelle ligne situé après $ref\n";
        $top_ord = $bottom_line_ref->[ORD];
        my $new_text = shift( @lines );
        $ref = $editor->new_line( $ref, 'after', $new_text );
        $inserted += 1;
        if ( defined $search_ref->{$inserted} ) {
            $search_ref->{$inserted} = $ref;
        }
        push @return, $ref;
        my $new_line_ref;
        my $next_ref = $bottom_line_ref->[NEXT];
        if ( defined $next_ref ) {
            $new_line_ref->[NEXT] = $next_ref;
            $next_ref->[PREVIOUS] = $new_line_ref;
        }
        $bottom_line_ref->[NEXT] = $new_line_ref;
        $new_line_ref->[PREVIOUS] = $bottom_line_ref;
        $new_line_ref->[REF] = $ref;

        $new_line_ref->[TEXT] = $new_text;
        create_text_in_line( $edit_ref, $new_line_ref );
        $bottom_line_ref = display_line_from_top( $edit_ref, $new_line_ref, $top_ord, 'no_cursor' );
    }
    
    # Last line
    print DBG "Ajout dernière ligne après $ref\n $text\n";
    
    $ref = $editor->new_line( $ref, 'after', $text );
    $inserted += 1;
    if ( defined $search_ref->{$inserted} ) {
        $search_ref->{$inserted} = $ref;
    }
    push @return, $ref;
    $top_ord = $bottom_line_ref->[ORD];
        
    my $new_line_ref;
    $new_line_ref->[REF] = $ref;
    $new_line_ref->[TEXT] = $text;

    my $next_ref = $bottom_line_ref->[NEXT];
    if ( defined $next_ref ) {
        $next_ref->[PREVIOUS] = $new_line_ref;
        $new_line_ref->[NEXT] = $next_ref;
    }
    $bottom_line_ref->[NEXT] = $new_line_ref;
    $new_line_ref->[PREVIOUS] = $bottom_line_ref;
    
    create_text_in_line( $edit_ref, $new_line_ref );
    $bottom_line_ref = display_line_from_top( $edit_ref, $new_line_ref, $top_ord, 'no_cursor' );
    
    if ( $bottom_line_ref->[ORD] != $bottom_ord ) {
        print DBG "Move de ", $bottom_line_ref->[ORD] - $bottom_ord, "\n";
        move_bottom( $edit_ref, $bottom_line_ref->[ORD] - $bottom_ord,
            $bottom_line_ref );
    }

    #visual_slurp( $edit_ref, 998 );
    
    $answer_ref->{'found'} = $search_ref;
    $answer_ref->{'last'} = $ref;
    $answer_ref->{'return'} = \@return;
    return $answer_ref;
}

sub non_visual_insertion {
    my ( $edit_ref, $ref, $complete_text, $pos, $replace, $search_ref, @lines ) = @_;

    my $editor = $edit_ref->[PARENT];

    my $inserted = 0;
    # FIRST LINE MODIFICATION
    #my $complete_text = $editor->line_text( $ref );
    my $first = shift( @lines );
    my $text = substr ( $complete_text, 0, $pos ) . $first;
    
    my $answer_ref = {};
    my $first_line_done = 0;
    if ( @lines ) {
        #print "Modification de la ligne avec ref $ref\n $text\n";
        $editor->modify_line( $ref, $text );
        if ( defined $search_ref->{$inserted} ) {
            $search_ref->{$inserted} = $ref;
        }
        $first_line_done = 1;
        $answer_ref->{'first_text'} = $text;
        $text = pop( @lines );
    }
    if ( ! $replace ) {
        $text .= substr ( $complete_text , $pos );
    }
    else {
        my $new_pos = $pos + length( $first );
        if ( length( $complete_text ) > $new_pos ) {
            $text .= substr ( $complete_text , $new_pos );
        }
    }
    if ( ! $first_line_done ) {
        #print "Modification de l'unique ligne $ref\n $text\n";
        $editor->modify_line( $ref, $text );
        if ( defined $search_ref->{$inserted} ) {
            $search_ref->{$inserted} = $ref;
        }
        $answer_ref->{'first_text'} = $text;
        $answer_ref->{'found'} = $search_ref;
        $answer_ref->{'last'} = $ref;
        $answer_ref->{'return'} = [ $ref ];
        return $answer_ref;
    }

    my @return = ( $ref );    
    # Intermediate lines
    while ( @lines ) {
        $ref = $editor->new_line( $ref, 'after', shift( @lines ) );
        $inserted += 1;
        if ( defined $search_ref->{$inserted} ) {
            $search_ref->{$inserted} = $ref;
        }
        push @return, $ref;
    }
    
    # Last line
    $ref = $editor->new_line( $ref, 'after', $text );
    $inserted += 1;
    if ( defined $search_ref->{$inserted} ) {
        $search_ref->{$inserted} = $ref;
    }
    push @return, $ref;

    $answer_ref->{'found'} = $search_ref;
    $answer_ref->{'last'} = $ref;
    $answer_ref->{'return'} = \@return;
    return $answer_ref;
}

sub bloc_insertion {
    my ( $edit_ref, $ref, $pos, $replace, $search_ref, $wantarray, @lines ) = @_;

    my $editor = $edit_ref->[PARENT];
    
    # FIRST LINE MODIFICATION
    my $complete_text = $editor->line_text( $ref );
    my $first = shift( @lines );
    my $text = substr ( $complete_text, 0, $pos ) . $first;
    $editor->modify_line( $ref, $text );
    if ( defined $search_ref->{'0'} ) {
        $search_ref->{'0'} = $ref;
    }
    my $first_text = $text;

    # LAST LINE MODIFICATION
    $text = pop( @lines );
    if ( ! $replace ) {
        $text .= substr ( $complete_text , $pos );
    }
    else {
        my $new_pos = $pos + length( $first );
        if ( length( $complete_text ) > $new_pos ) {
            $text .= substr ( $complete_text , $new_pos );
        }
    }
    push @lines, $text;

    # BLOC INSERTION

    my %options_insert = (
        'where' => $ref,
        'how' => 'after',
        'search' => $search_ref,
    );
    if ( $wantarray ) {
        $options_insert{'force_create'} = 1;
    }
    my $answer_ref = $editor->insert_bloc( join( "\n", @lines ), \%options_insert );
    $answer_ref->{'first_text'} = $first_text;
    unshift @{ $answer_ref->{'return'} }, $ref;
    return $answer_ref;
}

sub test_insert_events {
    my ( $edit_ref, $text, $initial_text ) = @_;
    
    my $editor = $edit_ref->[PARENT];
    my $event_ref = $edit_ref->[EVENTS];
    my $label = q{}; # Avoid warning when testing undef value

    my $step = 'change';
    if ( my $event = $event_ref->{$step} ) {
        ( undef, $label ) = execute_events( $event, $editor, {} );
    } 
}

# Valeurs de retour à gérer pour les 2 fonctions suivantes
sub delete_return {
    my ($edit_ref) = @_;

    cursor_make_visible($edit_ref) if ( $origin eq 'graphic' );

    my $cursor = $edit_ref->[CURSOR];

    # On supprimer un retour charriot : il y a donc forcément une ligne qui suit
    my $line_ref = $cursor->[LINE_REF];

    # Erreurs à l'appel, on renvoie undef
    return if ( !$line_ref );
    return if ( $cursor->[POSITION_IN_DISPLAY] != length( $line_ref->[TEXT] ) );
    return if ( $line_ref->[NEXT_SAME] );
    return if ( !$line_ref->[NEXT] );

    my ( $top_ord, undef ) = get_line_ords($line_ref);
    my ( undef, $bottom_ord ) = get_line_ords( $line_ref->[NEXT] );

    suppress_from_screen_line( $edit_ref, $line_ref );
    $line_ref = delete_text_in_line( $edit_ref, $line_ref );

# line_ref est une ligne entière (mode wrap annulé provisoirement pour cette ligne)

    suppress_from_screen_line( $edit_ref, $line_ref->[NEXT] );
    print "Avant appel delete_text_in_line...\n";
    $line_ref->[NEXT] = delete_text_in_line( $edit_ref, $line_ref->[NEXT] );
    
    position_bottom_tag_from( $edit_ref, $line_ref->[NEXT][NEXT] );
    
    print "Avant appel delete_key...\n";
    my ( $text, $concat ) = $edit_ref->[PARENT]->delete_key( 
        $line_ref->[TEXT], 
        $edit_ref->[CURSOR][POSITION_IN_DISPLAY],
        $line_ref->[REF],
    );
    # Le texte vaut le cumul des 2 lignes (travail de delete_key)
    $line_ref->[TEXT] = $text;
    die "Pas de concaténation sur suppression de \\n\n" if ( $concat ne "yes" );

    # Le texte a déjà été concaténé par la procédure delete_key
    # concat (modif liste chaînée) le ferai à nouveau
    $line_ref->[NEXT][TEXT] = "";
    concat( $edit_ref, $line_ref, 'bottom' );

    create_text_in_line( $edit_ref, $line_ref );

    my $bottom_line_ref = display_line_from_top( $edit_ref, $line_ref, $top_ord );

    # Déplacement des lignes du bas
    my $how_much = $bottom_line_ref->[ORD] - $bottom_ord;
    move_bottom( $edit_ref, $how_much, $bottom_line_ref );
}

sub erase {
    my ( $edit_ref, $number, $no_event_management ) = @_;

    return if ( $number == 0 );

    cursor_make_visible($edit_ref) if ( $origin eq 'graphic' );

    my $line_ref = $edit_ref->[CURSOR][LINE_REF];

# line_ref est une ligne entière (mode wrap annulé provisoirement pour cette ligne)

    # Par défaut, il faut supprimer un caractère, sauf...
    my $cursor_pos  = $edit_ref->[CURSOR][POSITION_IN_DISPLAY];
    my $length_line = length( $line_ref->[TEXT] );
    if ( $cursor_pos + $number > $length_line ) {

        # Pseudo-appels récursifs
        while ($number) {
            my $suppress;
            if ( $number > $length_line - $cursor_pos ) {
                $suppress = $length_line - $cursor_pos;
                erase( $edit_ref, $suppress, 'no_event_management' );
                delete_return($edit_ref);
                $length_line = length( $edit_ref->[CURSOR][LINE_REF] );
                $number -= $suppress + 1;
                $cursor_pos = 0;
            }
            else {
                $suppress = $number;
                erase( $edit_ref, $suppress, 'no_event_management' );
                $number = 0;
            }
        }
        my $editor = $edit_ref->[PARENT];
        my $event_ref = $edit_ref->[EVENTS];
        my $label = q{}; # Avoid warning when testing undef value

        my $step = 'change';
        if ( my $event = $event_ref->{$step} ) {
            ( undef, $label ) = execute_events( $event, $editor, {} );
        }
        return;
    }

    my ( $top_ord, $bottom_ord ) = get_line_ords($line_ref);

    suppress_from_screen_line( $edit_ref, $line_ref );
    $line_ref = delete_text_in_line( $edit_ref, $line_ref );
    
    position_bottom_tag_from( $edit_ref, $line_ref->[NEXT] );
    
    my $ref = $line_ref->[REF];
    my ($text) =
      $edit_ref->[PARENT]->erase_text( $number, $line_ref->[TEXT],
        $edit_ref->[CURSOR][POSITION_IN_DISPLAY],
        $line_ref->[REF], );
    $line_ref->[TEXT] = $text;

    create_text_in_line( $edit_ref, $line_ref );

    my $bottom_line_ref =
      display_line_from_top( $edit_ref, $line_ref, $top_ord );

    # Déplacement des lignes du bas
    my $how_much = $bottom_line_ref->[ORD] - $bottom_ord;
    move_bottom( $edit_ref, $how_much, $bottom_line_ref );


    if ( ! $no_event_management ) {

        my $editor = $edit_ref->[PARENT];
        my $event_ref = $edit_ref->[EVENTS];
        my $label = q{}; # Avoid warning when testing undef value

        my $step = 'change';
        if ( my $event = $event_ref->{$step} ) {
            ( undef, $label ) = execute_events( $event, $editor, {} );
        }
    }

    if (wantarray) {
        return 1;
    }
    else {
        return $ref;
    }
}

sub display {
    my ( $edit_ref, $ref, $options_ref ) = @_;

    if ( ! defined $options_ref ) {
        $options_ref = {};
    }
    if ( ref $options_ref ne 'HASH' ) {
        print STDERR "Second parameter of display method ignored : should be a hash\n";
        $options_ref = {};
    }
    my $at = $options_ref->{'at'};
    my $ord;
    if ( defined $at and $at =~ /^(\d+)$/ ) {
        #print "Dans display , ord précisée : $1\n";
        $ord = $1;
    }
    elsif ( defined $at ) {
        #print "dans display at = $at\n";
        if ( $at eq 'top' ) {
            $ord = 0;
        }
        elsif ( $at eq 'bottom' ) {
            $ord = $edit_ref->[SCREEN][HEIGHT];
        }
        elsif ( $at eq 'middle' ) {
            $ord = $edit_ref->[SCREEN][HEIGHT] / 2;
        }
        else {
            $ord = $edit_ref->[SCREEN][HEIGHT] / 4;
        }
    }
    else {
        # On positionne la ligne vers le haut (middle_top)
        $ord = $edit_ref->[SCREEN][HEIGHT] / 4;
    }

    # Vérification de la validité de la ligne avant effacement de l'écran
    if ( ! defined $ref ) {
        print STDERR "PAs de référence donnée pour un display\n";
        my $indice = 0;
        while ( my ( $pack, $file, $line ) = caller( $indice++ ) ) {
            print "PACK $pack, FILE $file, LINE $line\n";
        }
        return;
    }
    my $top_line_ref;
    if ( $ref =~ /^(\d+)_/ ) {
        ($top_line_ref) = get_line_ref_from_display_ref( $edit_ref, $ref );
    }
    else {
        $top_line_ref = create_line_ref_from_ref( $edit_ref, $ref );
    }
    if ( !$top_line_ref ) {
        print STDERR "Can't create the line associated with ref $ref for display\n";
        return;
    }

# Si on veut optimiser et ne pas tout supprimer, alors il ne faut pas appeler display
# Pour être propre, il faudrait supprimer toutes les références utilisées actuellement
    clear_screen($edit_ref);

    display_reference( $edit_ref, $ref, $ord, $options_ref->{'from'} );

    #if ( defined $at and $at =~ /^(\d+)$/ ) {
    #    my $line_ref = $edit_ref->[SCREEN][FIRST];
    #    while ( defined $line_ref ) {
        #    print $line_ref->[ORD], ":$line_ref:", $line_ref->[TEXT], "\n";
    #        $line_ref = $line_ref->[NEXT];
    #    }
    #}

    #Appel en boucle pour affichage de toutes les lignes
    # Recuperation de la derniere ligne qui devrait etre affichee
    display_bottom_of_the_screen($edit_ref);

# On a fini l'affichage du bas, mais il reste peut-être des lignes à afficher en haut de $top_line_ref
    display_top_of_the_screen($edit_ref);
    
    screen_check_borders ( $edit_ref ) unless ( $options_ref->{'no_check'} );

    #if ( defined $at and $at =~ /^(\d+)/ ) {
    #    my $line_ref = $edit_ref->[SCREEN][FIRST];
    #    while ( defined $line_ref ) {
        #    print $line_ref->[ORD], ":$line_ref:", $line_ref->[TEXT], "\n";
    #        $line_ref = $line_ref->[NEXT];
    #    }
    #}

    return update_vertical_scrollbar($edit_ref);
}

sub screen_check_borders {
        my ( $edit_ref ) = @_;


        my $line_ref = $edit_ref->[SCREEN][LAST];
        my $bottom = $edit_ref->[SCREEN][HEIGHT];
        if ( $line_ref->[ORD] < $bottom - 5 ) { # A variabiliser
            screen_move ( $edit_ref, 0, $bottom - $line_ref->[ORD] - 5 );
        }
        $line_ref = $edit_ref->[SCREEN][FIRST];
        my $top = $line_ref->[ORD] - $line_ref->[HEIGHT];
        if ( $top > 2 ) { # A variabiliser
            screen_move ( $edit_ref, 0, 2 - $top );
        }
}

sub display_reference {
    my ( $edit_ref, $ref, $ord, $from ) = @_;

    if ( $ref =~ /^(\d+)_/ ) {
        display_reference_line( $edit_ref, $1, $ord, $from );
        my ($line_ref) = get_line_ref_from_display_ref( $edit_ref, $ref );
        if ( !$line_ref )
        {    # On avait vérifié  avant ! Impossible, normalement ...
            print STDERR "Curieux...\n";
            $line_ref = $edit_ref->[SCREEN][LAST];
        }
        my $y;
        if ( !$from or $from eq 'top' ) {
            # Par défaut, on affiche à partir du haut
            $y = $ord - $line_ref->[ORD] + $line_ref->[HEIGHT];
        }
        elsif ( $from eq 'middle' ) {
            $y = $ord - $line_ref->[ORD] + int( $line_ref->[HEIGHT] / 2 );
        }
        else {
            $y = $ord - $line_ref->[ORD];
        }
        screen_move( $edit_ref, 0, $y );
        return;
    }
    display_reference_line( $edit_ref, $ref, $ord, $from );
    if ( defined $from and $from eq 'middle' ) {
        my ( $top_ord, $bottom_ord ) =
          get_line_ords( $edit_ref->[SCREEN][LAST] );
        my $y = $ord - $bottom_ord + int( ( $bottom_ord - $top_ord ) / 2 );
        screen_move( $edit_ref, 0, $y );
    }
    my ( $top_ord, $bottom_ord ) =  get_line_ords( $edit_ref->[SCREEN][LAST] );
    #print "Display reference : top_ord = $top_ord, bottom_ord = $bottom_ord\n";

}

sub display_reference_line {
    my ( $edit_ref, $ref, $ord, $from ) = @_;

    my $top_line_ref = create_line_ref_from_ref( $edit_ref, $ref );
    if ( !$from or $from eq 'top' ) {
        $edit_ref->[SCREEN][LAST] =
          display_line_from_top( $edit_ref, $top_line_ref, $ord );
        $edit_ref->[SCREEN][FIRST] = $top_line_ref;
    }
    else {
        $edit_ref->[SCREEN][FIRST] =
          display_line_from_bottom( $edit_ref, $top_line_ref, $ord );
        $edit_ref->[SCREEN][LAST] = $edit_ref->[SCREEN][FIRST];
        while ( $edit_ref->[SCREEN][LAST][NEXT_SAME] ) {
            $edit_ref->[SCREEN][LAST] = $edit_ref->[SCREEN][LAST][NEXT];
        }
    }
}

#-------------------------------------------------------------------
# Gestion des méthodes de l'objet interne "cursor"
#-------------------------------------------------------------------

sub cursor_position_in_display {
    my ($self) = @_;

    return $self->[CURSOR][POSITION_IN_DISPLAY];
}

sub cursor_position_in_text {
    my ($self) = @_;

    return $self->[CURSOR][POSITION_IN_TEXT];
}

sub cursor_visible {
   my ($self) = @_;

   my $ref = $self->[CURSOR][LINE_REF][REF];
   my $line_ref = $self->[SCREEN][FIRST];
   while ( $line_ref ) {
       if ( $line_ref->[REF] == $ref ) {
           return 1; # Cursor visible
       }
       $line_ref = $line_ref->[NEXT];
   }
   return 0; # Cursor not visible
}

sub cursor_abs {
    my ($self) = @_;

    return $self->[CURSOR][ABS];
}

sub cursor_virtual_abs {
    my ($self) = @_;

    return $self->[CURSOR][VIRTUAL_ABS];
}

sub cursor_line {
    my ($self) = @_;

    if (wantarray) {
        my $line_ref = $self->[CURSOR][LINE_REF];
        return ( complete_line($line_ref), $line_ref->[REF] );
    }
    else {
        return $self->[CURSOR][LINE_REF][REF];
    }
}

sub cursor_display {
    my ($self) = @_;

    return get_display_ref_from( $self->[CURSOR][LINE_REF] );
}

sub cursor_set {
    my ( $edit_ref, $options_ref, $ref ) = @_;

# Cas à traiter le plus rapidement car le plus fréquent : positionnement sur la même ligne fichier (pas de $ref)
    if ( !defined($ref) and !ref $options_ref ) {
        position_cursor_in_line( $edit_ref,
            $edit_ref->[CURSOR][LINE_REF], $options_ref );
        return cursor_get ( $edit_ref );
    }

    # Recherche du positionnement vertical (ligne fichier ou ligne écran)
    my ( $line_ref, $type ) =
      search_line_ref_and_type( $edit_ref, $options_ref, $ref );
    return if ( !$line_ref );

    if ( $type eq 'call' ) {

      #print STDERR "On n'a pas trouvé la ligne dans les lignes affichées...\n";
      # ===> on positionne quand même le curseur sur la ligne souhaitée, sans l'afficher
        $edit_ref->[CURSOR][LINE_REF] = [];
        $edit_ref->[CURSOR][LINE_REF][REF] = $ref;
        if ( ref $options_ref ) {
            $options_ref = 0;
        }
        $edit_ref->[CURSOR][POSITION_IN_LINE] = $options_ref;
        #my ( $top, $bottom ) = display( $edit_ref, $line_ref, { 'at' => 'middle' } );

# Attention, le positionnement peut planter si $ref est bidon ==> tester le code retour
        #return if ( !defined $top );

#print "Réaffichage pour positionnement éloigné |$top|$bottom|\n";
# Maintenant que la ligne est affiché, on peut positionner normalement (appel récursif)
        #return cursor_set( $edit_ref, $options_ref, $ref );
        return;
    }

# La ligne de positionnement et le type de positionnement sont connus ici (ordonnée 'y' connue)

    # Recherche de l'abscisse ('x')
    my $position;
    my $keep_virtual;
    if ( !ref $options_ref ) {
        $position = $options_ref;
    }
    else {
        $keep_virtual = $options_ref->{'keep_virtual'};
    }
    if ( !defined $position and ref $options_ref ) {
        if ( my $char = $options_ref->{'char'} ) {
            $position = $char;
        }
        if ( !defined $position and my $x = $options_ref->{'x'} ) {
            $position =
              get_position_from_line_and_abs( $edit_ref, $line_ref, $x );
            $type = 'display'; # On force le mode display puisque l'on a calculé
              # la position du curseur par rapport à une ligne affichée et à une abscisse (visuel)
        }
    }

    if ( $type eq 'display' ) {
        position_cursor_in_display( $edit_ref, $line_ref, $position,
            $keep_virtual );
    }
    else {
        position_cursor_in_line( $edit_ref, $line_ref, $position,
            $keep_virtual );
    }
    #print "Avant cursor_make_visible\n";
    cursor_make_visible ( $edit_ref ) unless ( ref $options_ref and $options_ref->{'do_not_make_visible'} );

    return cursor_get ($edit_ref);
}

sub cursor_set_shape {
    my ( $edit_ref, $shape ) = @_;
    
    $edit_ref->[GRAPHIC]->cursor_set_shape($shape);
}

sub search_line_ref_and_type {
    my ( $edit_ref, $options_ref, $ref ) = @_;

    my $line_ref;

    # Recherche d'une ligne écran ...
    # ...dans les options (prioritaires)
    if ( ref $options_ref eq 'HASH'
        and my $display = $options_ref->{'display'} )
    {
        ($line_ref) = get_line_ref_from_display_ref( $edit_ref, $display );
        return if ( !$line_ref );
        return ( $line_ref, 'display' );
    }

    # ...dans le 3ème paramètre $ref
    if ( defined $ref and $ref =~ /_/ ) {
        ($line_ref) = get_line_ref_from_display_ref( $edit_ref, $ref );
        return if ( !$line_ref );
        return ( $line_ref, 'display' );
    }

    # Recherche d'une ligne fichier ...
    # ... dans les options
    if ( ref $options_ref eq 'HASH' and my $line = $options_ref->{'line'} ) {
        $line_ref = get_line_ref_from_ref( $edit_ref, $line );
        if ( !$line_ref ) {
            # La référence n'est pas à l'écran
            return ( $ref, 'call' );
        }
        return ( $line_ref, 'line' );
    }

    # ... dans la référence (3ème paramètre)
    if ( defined $ref and $ref =~ /^\d+$/ ) {
        $line_ref = get_line_ref_from_ref( $edit_ref, $ref );
        if ( !$line_ref ) {
            # La référence n'est pas à l'écran
            return ( $ref, 'call' );
        }
        return ( $line_ref, 'line' );
    }

    # Recherche d'un positionnement par ordonnée à l'écran
    if ( ref $options_ref eq 'HASH' and my $ord = $options_ref->{'y'} ) {
        my $line_ref = get_line_ref_from_ord( $edit_ref, $ord );

        return ( $line_ref, 'display' );
    }

    # On n'a pas réussi à récupérer une ligne du paramétrage
    # ==> on se positionne sur la ligne courante
    $line_ref = $edit_ref->[CURSOR][LINE_REF];
    return ( $edit_ref->[CURSOR][LINE_REF], 'line' );
}

sub get_line_ref_from_ord {
    my ( $self, $ord ) = @_;

    my $line_ref = $self->[SCREEN][FIRST];
    while ($line_ref) {
        if ( $line_ref->[ORD] > $ord ) {
            return $line_ref;
        }
        $line_ref = $line_ref->[NEXT];
    }
    # Vérifier que c'est toujours ce que l'on souhaite
    return $self->[SCREEN][LAST];
    
    return;    # Pas trouvé
}

sub get_display_ref_from_ord {
    my ( $self, $ord ) = @_;

    my $line_ref = $self->[SCREEN][FIRST];
    my $indice   = 1;
    while ($line_ref) {
        if ( $line_ref->[ORD] > $ord ) {
            return $line_ref->[REF] . '_' . $indice;
        }
        if ( $line_ref->[NEXT_SAME] ) {
            $indice += 1;
        }
        else {
            $indice = 1;
        }
        $line_ref = $line_ref->[NEXT];
    }
    return;    # Pas trouvé
}

sub position_cursor_in_line {
    my ( $edit_ref, $line_ref, $position_in_line, $keep_virtual ) = @_;

    $position_in_line = 0 if ( !$position_in_line );
    my $position = $position_in_line;

    $line_ref = start_line($line_ref);
  LINE: while ( length( $line_ref->[TEXT] ) < $position ) {
        if ( !$line_ref->[NEXT_SAME] ) {
            $position = length( $line_ref->[TEXT] );
            last LINE;
        }
        $position -= length( $line_ref->[TEXT] );
        $line_ref = $line_ref->[NEXT];
    }
    return position_cursor_in_display( $edit_ref, $line_ref, $position,
        $keep_virtual, $position_in_line );
}

sub position_cursor_in_display {
    my ( $edit_ref, $line_ref, $position, $keep_virtual, $position_in_line ) =
      @_;

    $position = 0 if ( !defined $position );
    my $cursor_ref        = $edit_ref->[CURSOR];
    my $previous_line_ref = $cursor_ref->[LINE_REF];

    $cursor_ref->[LINE_REF]            = $line_ref;
    $cursor_ref->[POSITION_IN_DISPLAY] = $position;

    if ( !defined $position_in_line ) {
        $cursor_ref->[POSITION_IN_LINE] =
          calc_line_position_from_display_position($cursor_ref);
    }
    else {
        $cursor_ref->[POSITION_IN_LINE] = $position_in_line;
    }

    my $text_ref    = $line_ref->[FIRST];
    my $length_text = length( $text_ref->[TEXT] );
  TXT: while ( $length_text < $position ) {
        $position -= $length_text;
        if ( !$text_ref->[NEXT] ) {

     # Il n'y a pas assez de caractères pour effectuer le positionnement demandé
     # ==> on se positionne sur le dernier élément texte de la ligne
            $position = $length_text;
            last TXT;
        }
        else {
            $text_ref = $text_ref->[NEXT];
        }
        $length_text = length( $text_ref->[TEXT] );
    }

    select_text_element( $edit_ref, $text_ref, $position );


    my $increment =
      $edit_ref->[GRAPHIC]->length_text(
        substr( $text_ref->[TEXT], 0, $cursor_ref->[POSITION_IN_TEXT] ),
        $text_ref->[FONT], );
    $cursor_ref->[ABS] =
      $text_ref->[ABS] + $increment - $edit_ref->[SCREEN][VERTICAL_OFFSET];

    if ( !defined $keep_virtual or !$keep_virtual ) {
        $cursor_ref->[VIRTUAL_ABS] = $cursor_ref->[ABS];
    }
    
    # Positionnement correct du tag "bottom'
    # ==>  Couteux : à ne faire que si la "hauteur" du curseur à changé
    if ( $line_ref != $previous_line_ref ) { #

#print "Tag BOTTOM de $cursor_ref->[LINE_REF][ORD] à $edit_ref->[SCREEN][LAST][ORD]\n";

        if ( ! defined $cursor_ref->[LINE_REF][ORD] ) {
           print STDERR "Abstract : problème à venir :\n",
           "\t\$cursor_ref = $cursor_ref\n",
           "\t\$cursor_ref->[LINE_REF] = $cursor_ref->[LINE_REF]\n",
           "\t\$cursor_ref->[LINE_REF][TEXT] = $cursor_ref->[LINE_REF][TEXT]\n";
       }
    }

    my $editor = $edit_ref->[PARENT];
    my $event_ref = $edit_ref->[EVENTS];    
    my $step = 'cursor_set';
    if ( my $event = $event_ref->{$step} ) {
        my $info_ref = {
            'line'        => $line_ref->[REF],
            'display'     => get_display_ref_from($line_ref),
            'pos'    => $cursor_ref->[POSITION_IN_LINE],
            'origin'      => $origin,
            'sub_origin'  => $sub_origin,
        };

        execute_events( $event, $editor, $info_ref );
    }

    if ( wantarray ) {
        my $ref = $line_ref->[REF];
        return ( $ref, $cursor_ref->[POSITION_IN_LINE] );
    }
    else {
        return $cursor_ref->[POSITION_IN_LINE];
    }
}

sub cursor_get {
    my ($self) = @_;

    my $cursor_ref   = $self->[CURSOR];
    my $position = $cursor_ref->[POSITION_IN_DISPLAY];
    my $line_ref = $cursor_ref->[LINE_REF];
    my $count = 1;
    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
        $position += length( $line_ref->[TEXT] );
        $count += 1;
    }
    my $ref = $line_ref->[REF];
    if (wantarray) {
        return (
            $ref, 
            $position,
            $ref . '_' . $count, 
            $cursor_ref->[POSITION_IN_DISPLAY],
            $cursor_ref->[ABS],
            $cursor_ref->[VIRTUAL_ABS],
            $cursor_ref->[POSITION_IN_TEXT],
            $cursor_ref->[LINE_REF][ORD],
        );
    }
    else {
        return $position;
    }
}

#-------------------------------------------------------------------
# Gestion des méthodes de l'objet interne "screen"
#-------------------------------------------------------------------

sub screen_first {
    my ($self) = @_;

    return get_display_ref_from( $self->[SCREEN][FIRST] );
}

sub screen_font_height {
    my ($self) = @_;

    return $self->[SCREEN][FONT_HEIGHT];
}

sub screen_height {
    my ($self) = @_;

    return $self->[SCREEN][HEIGHT];
}

sub height {
    my ($self) = @_;

    return $self->[SCREEN][HEIGHT];
}

sub screen_x_offset {
    my ($self) = @_;

    return $self->[SCREEN][VERTICAL_OFFSET];
}

sub screen_last {
    my ($self) = @_;

    return get_display_ref_from( $self->[SCREEN][LAST] );
}

sub screen_margin {
    my ($self) = @_;

    return $self->[SCREEN][MARGIN];
}

sub screen_width {
    my ($self) = @_;

    return $self->[SCREEN][WIDTH];
}

sub width {
    my ($self) = @_;

    return $self->[SCREEN][WIDTH];
}

sub screen_wrap {
    my ($self) = @_;

    return $self->[SCREEN][WRAP];
}

sub screen_set_width {
    my ( $self, $width ) = @_;

    my ( undef, $height, $x, $y ) = $self->[GRAPHIC]->get_geometry;
    $self->[GRAPHIC]->set_geometry( $width, $height, $x, $y );

# Le set_width va être générateur d'un resize
# Ce resize va commencer au moment où le thread qui a lancé set_width aura a nouveau la main
# (les threads travaillent "simultanément")
#
    return "Fin de set_width";
}

sub screen_set_height {
    my ( $self, $height ) = @_;

    my ( $width, undef, $x, $y ) = $self->[GRAPHIC]->get_geometry;
    $self->[GRAPHIC]->set_geometry( $width, $height, $x, $y );
}

sub screen_set_x_corner {
    my ( $self, $x ) = @_;

    my ( $width, $height, undef, $y ) = $self->[GRAPHIC]->get_geometry;
    $self->[GRAPHIC]->set_geometry( $width, $height, $x, $y );
}

sub screen_set_y_corner {
    my ( $self, $y ) = @_;

    my ( $width, $height, $x, undef ) = $self->[GRAPHIC]->get_geometry;
    $self->[GRAPHIC]->set_geometry( $width, $height, $x, $y );
}

sub window_get {
    my ( $self ) = @_;

    print "Dans window_get\n";

   my @geometry;

   if ( $window_destroyed ) {
        @geometry = @window;
    }
    else {
        @geometry = $self->[GRAPHIC]->get_geometry;
    }

    if ( wantarray ) {
        return @geometry;
    }
    else {
        my ( $width, $height, $x, $y ) = @geometry;
        return {
            'width' => $width,
            'height' => $height,
            'x' => $x,
            'y' => $y,
        }
    }
}

sub window_set {
    my ( $self, $width, $height, $x, $y ) = @_;

    my ( $old_width, $old_height, $old_x, $old_y ) = $self->[GRAPHIC]->get_geometry;
    
    if ( ref $width ) {
        $height = $width->{'height'};
        $x = $width->{'x'};
        $y = $width->{'y'};
        $width = $width->{'width'};
    }
    $width = $old_width if ( ! defined $width );
    $height = $old_height if ( ! defined $height );
    $x = $old_x if ( ! defined $x );
    $y = $old_y if ( ! defined $y );
    
    $self->[GRAPHIC]->set_geometry( $width, $height, $x, $y );
    @window = ( $width, $height, $x, $y );
}

sub window_destroy {
    @window = @_;
    $window_destroyed = 1;
    print "Dans Window Destroy : @window\n";
}


sub screen_number {
    my ( $self, $number ) = @_;

  # Renvoie le nombre de lignes affichées dans la zone visible :
  #Attention ! Parfois [SCREEN][FIRST] et/ou [SCREEN][LAST] ne sont pas visibles
  # Les lignes peuvent avoir des hauteurs différentes

    # Si $number est renseigné, renvoie la '$number' ligne écran

    my $line_ref = $self->[SCREEN][FIRST];
    while ( $line_ref->[ORD] < 0 and $line_ref->[NEXT] ) {
        $line_ref = $line_ref->[NEXT];
    }
    if ( $line_ref->[ORD] < 0 ) {    # En principe impossible !
        return if ( defined $number );
        return 0;
    }
    my $current_number;
    while ( $line_ref->[ORD] - $line_ref->[HEIGHT] < $self->[SCREEN][HEIGHT] ) {
        $current_number += 1;
        if ( defined $number and $number == $current_number ) {
            return get_display_ref_from($line_ref);
        }
        $line_ref = $line_ref->[NEXT];
        last if ( !$line_ref );
        last if ( !$line_ref );
    }
    return $current_number;
}

sub get_line_ref_from_ref {
    my ( $self, $ref ) = @_;

    my $line_ref = $self->[SCREEN][FIRST];
    while ( $line_ref->[REF] != $ref and $line_ref->[NEXT] ) {
        $line_ref = $line_ref->[NEXT];
    }
    if ( $line_ref->[REF] == $ref ) {
        return $line_ref;
    }
    else {
        return;
    }
}

sub line_displayed {
    my ( $self, $ref ) = @_;

    #print "Dans line_displayed : $ref\n";
    my @ref;
    my $indice   = 1;
    my $line_ref = $self->[SCREEN][FIRST];
    while ( defined $line_ref and $line_ref != $self->[SCREEN][LAST] ) {
        if ( $line_ref->[REF] == $ref ) {
            push @ref, $ref . "_" . $indice++;
        }
        $line_ref = $line_ref->[NEXT];
    }
    if ( $self->[SCREEN][LAST][REF] == $ref ) {
        push @ref, $ref . "_" . $indice++;
    }

    return @ref;
}

sub line_deselect {
    my ( $self, $ref ) = @_;

    #print "Dans line_deselect : $ref\n";
    $self->[GRAPHIC]->delete_whose_tag( 'L' . $ref );
    
}

sub line_set {
    my ( $edit_ref, $ref, $text ) = @_;

    #print "Dans line_set : $ref, $text\n";
    return if ( !defined $ref );

    $edit_ref->[PARENT]->modify_line( $ref, $text );
    my $line_ref = get_line_ref_from_ref ( $edit_ref, $ref );
    if ( defined $line_ref ) {
            #print "La ligne est à l'écran, il faut la réafficher\n";
            my ( $top_ord, $bottom_ord ) = get_line_ords($line_ref);
            suppress_from_screen_line( $edit_ref, $line_ref );

            $line_ref = delete_text_in_line( $edit_ref, $line_ref );
            $line_ref->[TEXT] = $text;
            create_text_in_line( $edit_ref, $line_ref );

            my $bottom_line_ref =
              display_line_from_top( $edit_ref, $line_ref, $top_ord );
            my ( $new_top_ord, $new_bottom_ord ) = get_line_ords($bottom_line_ref);

            if ( $bottom_line_ref->[ORD] != $bottom_ord ) {

                #print "Move de ", $bottom_line_ref->[ORD] - $bottom_ord, "\n";
                move_bottom( $edit_ref, $bottom_line_ref->[ORD] - $bottom_ord,
                    $bottom_line_ref );
            }
    }
    
    my $editor = $edit_ref->[PARENT];
    my $event_ref = $edit_ref->[EVENTS];
    my $label = q{}; # Avoid warning when testing undef value

    my $step = 'change';
    if ( my $event = $event_ref->{$step} ) {
        ( undef, $label ) = execute_events( $event, $editor, {} );
    }

    return $ref;
}

sub line_select {
    my ( $self, $ref, $first, $last, $options_ref ) = @_;

    return if ( !defined $ref );

    my ( $force, $color, $display );
    if ( defined $options_ref ) {
        if ( ref $options_ref ) {
            $force = $options_ref->{'force'};
            $color = $options_ref->{'color'};
            $display = $options_ref->{'display'};
        }
        else {
            $color = $options_ref;
        }
    }
    if ( ref $first eq 'HASH' ) {
        $options_ref = $first;
        $first   = $options_ref->{'first'};
        $last    = $options_ref->{'last'};
        $force   = $options_ref->{'force'};
        $color   = $options_ref->{'color'};
        $display = $options_ref->{'display'};       
    }
    my $line_ref = get_line_ref_from_ref( $self, $ref );
    if ( !$line_ref )
    {    # La ligne fichier n'est pas à l'écran, on ne peut pas la sélectionner
        if ( ! $force ) {
            print STDERR "Line not on screen, selection not yet managed...\n";
            return;
        }
        else {
            if ( defined $display ) {
                display( $self, $ref, $display );
            }
            else {
                display( $self, $ref, { 'at' => $force } );
            }
            $line_ref = get_line_ref_from_ref( $self, $ref );
            if ( ! $line_ref ) {
                print STDERR "Can't display line with reference $ref\n";
                return;       
            }
            #return line_select ( $self, $ref, $first, $last, $options_ref );
        }
    }
    if ( !defined $first ) {
        $first = 0;
    }
    my $text   = $self->[PARENT]->line_text($ref);
    my $length = length($text);
    $last = $length if ( !defined $last );

    if ( $first > $last ) {
        my $temp = $last;
        $last  = $first;
        $first = $temp;
    }
    if ( $first < 0 ) {
        if ( my $previous_ref = $line_ref->[PREVIOUS] ) {
            my $new_ref     = $previous_ref->[REF];
            # Le +1 correspond au retour chariot
            my $length_text =
              length( $self->[PARENT]->line_text($new_ref) ) + 1;
            my $new_first = $length_text + $first;
            my $new_last  = $length_text + $last;
            return $self->line_select( $new_ref, $new_first, $new_last,
                $color );
        }
        else {
            $first = 0;
        }
    }
    if ( $first > $length ) {
        my $next_ref = $line_ref->[NEXT];
        while ( $next_ref and $next_ref->[NEXT_SAME] ) {
            $next_ref = $next_ref->[NEXT];
        }
        if ($next_ref) {
            my $new_ref = $next_ref->[REF];
            # Le -1 correspond au retour chariot
            return $self->line_select(
                $new_ref,
                $first - $length - 1,
                $last - $length - 1, $color
            );
        }
        else {
            return;
        }
    }

    #print "4 |$first|$last|\n";
    return q{} if ( $last == $first );

    #print "OK, on va sélectionner...|$first|$last|\n";

    my $return_value = q{};

    #print "Line select : 1 |$return_value|\n";
    my $offset = $self->[SCREEN][VERTICAL_OFFSET];
  DISPLAY: while ($last) {

        # On ne réutilise pas display_select pour un peu plus d'efficacité
        if ( !defined $line_ref ) {
            print STDERR
              "Problème de cohérence entre Abstract et File_manager\n";
            return $return_value;
        }
        my $text   = $line_ref->[TEXT];
        my $length = length($text);
        if ( $first > $length ) {
            $line_ref = $line_ref->[NEXT];
            $first -= $length;
            $last  -= $length;
            next DISPLAY;
        }
        my $left   = line_ref_abs( $self, $line_ref, $first );
        my $bottom = $line_ref->[ORD];
        my $top    = $bottom - $line_ref->[HEIGHT];

        my $right;

        #print "Line select : 2 |$return_value|\n";
        if ( $last <= $length ) {
            $right = line_ref_abs( $self, $line_ref, $last );
            $return_value .= substr( $text, $first, $last - $first );
            $last = 0;
        }
        else {
            $right = line_ref_abs( $self, $line_ref, $length );
            if ( $line_ref->[NEXT] and !$line_ref->[NEXT_SAME] ) {
                $return_value .=
                  substr( $text, $first, $length - $first ) . "\n";
            }
            # mises à jour pour display suivante (éventuellement)
            $first = 0;
            $last -= $length + 1;
        }
        $self->[GRAPHIC]
          ->select( $left - $offset, $top, $right - $offset, $bottom, $color, 'L' . $line_ref->[REF] );
        $line_ref = $line_ref->[NEXT];
    }

    #print "Line select : retourne $return_value\n";
    return $return_value;
}

sub line_top_ord {
    my ( $self, $ref ) = @_;

    return if ( !defined $ref );

    my $line_ref = get_line_ref_from_ref( $self, $ref );
    
    return if ( ! $line_ref );
    
    return $line_ref->[ORD] - $line_ref->[HEIGHT];
}

sub line_bottom_ord {
    my ( $self, $ref ) = @_;

    return if ( !defined $ref );

    my $line_ref = get_line_ref_from_ref( $self, $ref );
    return if ( ! $line_ref );
    
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
    }
    
    return $line_ref->[ORD];
}


sub bind_key { # instance call
    my ( $self, $hash_ref ) = @_;

    print "Dans bind_key simple...\n";

    my $use = $hash_ref->{'use'};
    eval "use $use"                       if ( defined $use );
    print "EVAL use $use en erreur\n$@\n" if ($@);

    my $sub     = $hash_ref->{'sub'};
    my $package = $hash_ref->{'package'};
    my $key     = $hash_ref->{'key'};
    my $sub_ref = $hash_ref->{'sub_ref'};

    #print "Dans bind key...$sub, $package, $key, $use\n";
    if ( !defined $sub and !defined $sub_ref ) {
        if ( $self->[KEY]{$key} ) {
            delete $self->[KEY]{$key};
        }
        return;
    }

    if ( defined $sub ) {
        # Vérification de la bonne valeur de key_code à faire (ctrl, alt et shift)
        my $string = "\\&" . $package . "::$sub";

        #print "STRING $string|$package\n";
        $self->[KEY]{$key} = eval $string;

        #$key{$key} = eval "\\&$package::$sub";
        print "key_code =$self->[KEY]{$key}\n";
    }
    else {
        $self->[KEY]{$key} = $sub_ref;
    }

    return;
}

sub bind_key_global { # class call
    my ( $self, $hash_ref ) = @_;

    print "Dans bind_key_global\n";

    my $use = $hash_ref->{'use'};
    eval "use $use"                       if ( defined $use );
    print "EVAL use $use en erreur\n$@\n" if ($@);

    my $sub     = $hash_ref->{'sub'};
    my $package = $hash_ref->{'package'};
    my $key     = $hash_ref->{'key'};

    #print "Dans bind key...$sub, $package, $key, $use\n";
    if ( !defined $sub and $key{$key} ) {
        delete $key{$key};
        return;
    }

    # Vérification de la bonne valeur de key_code à faire (ctrl, alt et shift)
    my $string = "\\&" . $package . "::$sub";

    #print "STRING $string|$package\n";
    $key{$key} = eval $string;

    #$key{$key} = eval "\\&$package::$sub";
    #print "key_code =$key{$key}\n";
    return;
}

sub display_text {
    my ( $self, $ref_display ) = @_;

    #print "REF NUM dans <text ; $ref_display\n";
    my ( $line_ref, $ref, $count ) =
      get_line_ref_from_display_ref( $self, $ref_display );
    if ($line_ref) {
        return $line_ref->[TEXT];
    }
    print "Pas trouvé\n";
    return;
}

sub display_next {
    my ( $self, $ref_display ) = @_;

    my ( $line_ref, $ref, $count ) =
      get_line_ref_from_display_ref( $self, $ref_display );
    if ( $line_ref and $line_ref->[NEXT] ) {
        return get_display_ref_from( $line_ref->[NEXT] );
    }
    return;
}

sub display_ord {
    my ( $self, $ref_display ) = @_;

    my ($line_ref) = get_line_ref_from_display_ref( $self, $ref_display );
    if ($line_ref) {
        return $line_ref->[ORD];
    }
    return;
}

sub display_height {
    my ( $self, $ref_display ) = @_;

    my ($line_ref) = get_line_ref_from_display_ref( $self, $ref_display );
    if ($line_ref) {
        return $line_ref->[HEIGHT];
    }
    return;
}

sub display_middle_ord {
    my ( $self, $ref_display ) = @_;

    my ($line_ref) = get_line_ref_from_display_ref( $self, $ref_display );
    if ($line_ref) {
        return $line_ref->[ORD] - $line_ref->[HEIGHT]/2;
    }
    return;
}

sub display_number {
    my ( $self, $ref_display ) = @_;

    # Renvoie le numéro de la ligne écran (peut être négatif)

    my ($search_ref) = get_line_ref_from_display_ref( $self, $ref_display );
    return if ( !$search_ref );

    # Si $number est renseigné, renvoie la '$number' ligne écran

    my $trouve;
    my $current_number = 0;
    my $line_ref       = $self->[SCREEN][FIRST];
    if ( $search_ref == $line_ref ) {
        $trouve = $current_number;
    }
    while ( $line_ref->[ORD] < 0 and $line_ref ) {
        $current_number += 1;
        $line_ref = $line_ref->[NEXT];
        if ( $search_ref == $line_ref ) {
            $trouve = $current_number;
        }
    }
    if ( defined $trouve ) {
        return $trouve - $current_number + 1;
    }
    $current_number = 0;
    while ($line_ref) {
        $current_number += 1;
        if ( $search_ref == $line_ref ) {
            return $current_number;
        }
        $line_ref = $line_ref->[NEXT];
    }
    return;
}

sub display_previous {
    my ( $self, $ref_display ) = @_;

    my ( $line_ref, $ref, $count ) =
      get_line_ref_from_display_ref( $self, $ref_display );
    if ( $line_ref and $line_ref->[PREVIOUS] ) {
        return get_display_ref_from( $line_ref->[PREVIOUS] );
    }
    return;
}

sub get_line_ref_from_display_ref {
    my ( $self, $ref_display ) = @_;

    my ( $ref, $num ) = split( /_/, $ref_display );

    my $count    = 0;
    my $line_ref = $self->[SCREEN][FIRST];
    my $next;
    while ($line_ref) {
        if ( $line_ref->[REF] == $ref ) {
            $count += 1;
            if ( $count == $num ) {
                return ( $line_ref, $ref, $count );
            }
        }
        $line_ref = $line_ref->[NEXT];
    }
    return;
}

sub get_display_ref_from {
    my ($line_ref) = @_;

    return if ( !$line_ref );
    my $ref   = $line_ref->[REF];
    my $count = 1;
    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
        $count += 1;
    }
    return $ref . '_' . $count;
}

sub display_next_is_same {
    my ( $self, $ref_display ) = @_;

    my ( $line_ref, $ref, $count ) =
      get_line_ref_from_display_ref( $self, $ref_display );
    if ($line_ref) {
        if ( $line_ref->[NEXT_SAME] ) {    # peut ne pas être défini
            return 1;
        }
        return 0;
    }
    return;
}

sub display_previous_is_same {
    my ( $self, $ref_display ) = @_;

    my ( $line_ref, $ref, $count ) =
      get_line_ref_from_display_ref( $self, $ref_display );
    if ($line_ref) {
        if ( $line_ref->[PREVIOUS_SAME] ) {    # peut ne pas être défini
            return 1;
        }
        return 0;
    }
    return;
}

sub display_abs {
    my ( $edit_ref, $display_ref, $pos ) = @_;

    my ($line_ref) = get_line_ref_from_display_ref( $edit_ref, $display_ref );
    return if ( !$line_ref );
    if ( !defined $pos ) {
        $pos = length( $line_ref->[TEXT] );
    }
    return line_ref_abs( $edit_ref, $line_ref, $pos );
}

sub line_ref_abs {
    my ( $edit_ref, $line_ref, $pos ) = @_;

    my $text_ref = $line_ref->[FIRST];
    while ( $text_ref and $pos > length( $text_ref->[TEXT] ) ) {
        $pos -= length( $text_ref->[TEXT] );
        $text_ref = $text_ref->[NEXT];
    }
    print "Hors display!\n" if ( !$text_ref );
    return                  if ( !$text_ref );  # position demandée hors display

    #print "$pos|", $text_ref->[TEXT], "\n";

    my $abs = $text_ref->[ABS];
    return $abs if ( $pos == 0 );

    my $sous_chaine = substr( $text_ref->[TEXT], 0, $pos );
    my $increment =
      $edit_ref->[GRAPHIC]->length_text( $sous_chaine, $text_ref->[FONT] );
    return $increment + $abs;
}

sub display_select {
    my ( $self, $display_ref, $first, $last, $mode ) = @_;

    my ($line_ref) = get_line_ref_from_display_ref( $self, $display_ref );
    return if ( !$line_ref );

    $first = 0 if ( !defined $first );
    my $max = length( $line_ref->[TEXT] );
    $last = $max if ( !defined $last or $last > $max );

# Bug à voir : si l'on ne met pas à jour la ligne de l'onglet, la ligne existe dans Abstract mais pas dans Tk ?
#print "DISPLAY ", $line_ref->[TEXT], "|$first|$last|\n";

    my $left = line_ref_abs( $self, $line_ref, $first );

    #print "last = $last\n";
    my $right = line_ref_abs( $self, $line_ref, $last );

    #print "right = $right\n";
    my $bottom = $line_ref->[ORD];
    my $top    = $bottom - $line_ref->[HEIGHT];

    $self->[GRAPHIC]->select( $left, $top, $right, $bottom, $mode, $line_ref->[REF] );
}

sub parent { # for call from external module with the same thread
    my ($self) = @_;

    return $self->[PARENT];
}

sub move_bottom {
    my ( $self, $how_much, $previous_line_ref ) = @_;

    return if ( $how_much == 0 );

    $self->[GRAPHIC]->move_tag( 'bottom', 0, $how_much );
    while ( $previous_line_ref->[NEXT] ) {
        $previous_line_ref = $previous_line_ref->[NEXT];
        $previous_line_ref->[ORD] += $how_much;
    }
    if ( $how_much > 0 ) {
        suppress_bottom_invisible_lines($self);
    }
    else {
        display_bottom_of_the_screen($self);
    }
}

sub screen_move {
    my ( $self, $x, $y ) = @_;

    return if ( $x == 0 and $y == 0 );
    $self->[GRAPHIC]->move_tag( 'all', $x, $y );
    my $line_ref = $self->[SCREEN][FIRST];
    while ($line_ref) {
        $line_ref->[ORD] += $y;
        $line_ref = $line_ref->[NEXT];
    }
    if ( $y > 0 ) {
        suppress_bottom_invisible_lines($self);
        display_top_of_the_screen($self);
    }
    else {
        suppress_top_invisible_lines($self);
        display_bottom_of_the_screen($self);
    }
}

sub display_bottom_of_the_screen
{    # Parallèle de la fonction "suppress_bottom_invisible_lines"
    my ($edit_ref) = @_;

    my $screen_ref = $edit_ref->[SCREEN];
    my $last_ref   = $screen_ref->[LAST];

  DISPLAY: while ( $last_ref->[ORD] < $screen_ref->[HEIGHT] ) {
        my $line_ref = read_next_line( $edit_ref, $last_ref );

        #print "Lu :$line_ref->[TEXT]\n";

        if ($line_ref) {
           #print "Dans display_bottom_of_the_screen : avant display_line_from_top...\n";
           $screen_ref->[LAST] = $line_ref;
            $last_ref =
              display_line_from_top( $edit_ref, $line_ref, $last_ref->[ORD] );
            $screen_ref->[LAST] = $last_ref;

           #print "Dans display_bottom_of_the_screen : avant add_tag_complete...", $last_ref->[REF], "\n";
           #Pbm sur la ref 10
            # Ajout du tag 'bottom'
            add_tag_complete( $edit_ref, $last_ref, 'bottom' );
        }
        else {
            #print "Aucune nouvelle ligne trouvée après ref = $last_ref->[REF]\n";
            return;
        }
    }
}

sub display_top_of_the_screen
{    # Parallèle de la fonction "suppress_bottom_invisible_lines"
    my ($edit_ref) = @_;

    my $screen_ref = $edit_ref->[SCREEN];
    my $first_ref  = $screen_ref->[FIRST];

  DISPLAY: while ( $first_ref->[ORD] - $first_ref->[HEIGHT] > 0 ) {
        my $line_ref = read_previous_line( $edit_ref, $first_ref );

        if ($line_ref) {
            # L'instruction suivante réaffecte $screen_ref->[FIRST] mais elle peut avoir
            # besoin d'une valeur actualisée si le curseur se trouve sur cette ligne...
            $screen_ref->[FIRST] = $line_ref;
            
            $first_ref =
              display_line_from_bottom( $edit_ref, $line_ref,
                $first_ref->[ORD] - $first_ref->[HEIGHT] );
            $screen_ref->[FIRST] = $first_ref;
        }
        else {
            return;
        }
    }
}

sub display_line_from_top {

    # ord est le bas de la ligne en-dessous de laquelle il faut écrire
    my ( $edit_ref, $line_ref, $ord, $no_cursor ) = @_;

    my $graphic = $edit_ref->[GRAPHIC];
    $line_ref->[HEIGHT] = 0;

    my ( $overwrite_ref, $still_to_display_ref ) =
      display_with_tag( $edit_ref, $line_ref, $ord, ['just_created'] );
    while ( defined $still_to_display_ref ) {
        $graphic->move_tag( 'just_created', 0, $overwrite_ref->[HEIGHT] );
        
        $graphic->delete_tag('just_created');
        $ord += $overwrite_ref->[HEIGHT];
        $overwrite_ref->[ORD] = $ord;

        ( $overwrite_ref, $still_to_display_ref ) =
          display_with_tag( $edit_ref, $still_to_display_ref, $ord,
            ['just_created'] );
    }
    #print "Avant move \$overwrite_ref->[HEIGHT] = $overwrite_ref->[HEIGHT]\n";
    $graphic->move_tag( 'just_created', 0, $overwrite_ref->[HEIGHT] );
    #print "Après move \$overwrite_ref->[HEIGHT] = $overwrite_ref->[HEIGHT]\n";
    $graphic->delete_tag('just_created');
    $overwrite_ref->[ORD] = $ord + $overwrite_ref->[HEIGHT];

    #        print "D|", $overwrite_ref->[ORD] - $overwrite_ref->[HEIGHT], "|",
    #            $overwrite_ref->[HEIGHT], "|", $overwrite_ref->[ORD], "|",
    #            $overwrite_ref->[TEXT], "\n";
    #print "Fin display_line_from_top \$line_ref : $line_ref\n\t\$line_ref->[ORD] = $line_ref->[ORD]\n";
    
    check_cursor( $edit_ref, $line_ref ) unless $no_cursor;
    
    #print "Fin display_line_from_top \$overwrite_ref : $overwrite_ref\n\t\$overwrite_ref->[ORD] = $overwrite_ref->[ORD]\n";
    return $overwrite_ref;
}

sub display_line_from_bottom {

    # ord est le haut de la ligne au-dessus de laquelle il faut écrire
    my ( $edit_ref, $line_ref, $ord ) = @_;

    $line_ref->[HEIGHT] = 0;

    my ( $overwrite_ref, $still_to_display_ref ) =
      display_with_tag( $edit_ref, $line_ref, $ord, ['just_created'] );
    while ( defined $still_to_display_ref ) {
        $overwrite_ref->[ORD] = $ord;

        ( $overwrite_ref, $still_to_display_ref ) =
          display_with_tag( $edit_ref, $still_to_display_ref, $ord );

        $edit_ref->[GRAPHIC]
          ->move_tag( 'just_created', 0, -$overwrite_ref->[HEIGHT] );
        my $previous_line_ref = $overwrite_ref;
        while ( $previous_line_ref->[PREVIOUS_SAME] ) {
            $previous_line_ref = $previous_line_ref->[PREVIOUS];
            $previous_line_ref->[ORD] -= $overwrite_ref->[HEIGHT];
        }
        if ($still_to_display_ref) {
            add_tag( $edit_ref, $overwrite_ref, 'just_created' );
        }
    }
    $edit_ref->[GRAPHIC]->delete_tag('just_created');
    $overwrite_ref->[ORD] = $ord;

    check_cursor( $edit_ref, $line_ref );
    return $line_ref;
}

sub add_tag {
    my ( $self, $line_ref, $tag, $debug ) = @_;

    my $text_ref = $line_ref->[FIRST];
    while ($text_ref) {
#        if ( $debug ) {
#            print "TAG |$tag|, \$text_ref->[ID]", $text_ref->[ID], "\n";
#        }
        $self->[GRAPHIC]->add_tag( $tag, $text_ref->[ID], $debug );
        $text_ref = $text_ref->[NEXT];
    }
}

sub add_tag_complete {
    my ( $self, $line_ref, $tag ) = @_;

    while ( $line_ref->[PREVIOUS_SAME] ) {
        $line_ref = $line_ref->[PREVIOUS];
    }
    add_tag( $self, $line_ref, $tag);
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
        add_tag( $self, $line_ref, $tag );
    }
}

sub display_with_tag {
    my ( $edit_ref, $line_ref, $ord, $tag_ref ) = @_;

    if ( !defined $tag_ref ) {
        $tag_ref = 'text';
    }
    else {
        push @{$tag_ref}, 'text';
    }
    my $text_ref = $line_ref->[FIRST];
    $line_ref->[HEIGHT] = 0;
    my $current_abs  = $edit_ref->[SCREEN][MARGIN];
    my $current_curs = 0;

  TEXT: while ($text_ref) {
        $text_ref->[ABS] = $current_abs;
        my ( $width, $height ) =
          display_text_from_memory( $edit_ref, $text_ref, $ord, $tag_ref );
        $current_abs += $width;
        $line_ref->[HEIGHT] = $height if ( $height > $line_ref->[HEIGHT] );
        $current_curs += length( $text_ref->[TEXT] );

        if (    $edit_ref->[SCREEN][WRAP]
            and $current_abs >
            ( $edit_ref->[SCREEN][WIDTH] - $edit_ref->[SCREEN][MARGIN] ) )
        {
            my $new_line_ref =
              trunc( $edit_ref, $line_ref, $text_ref, $current_curs, 'bottom' );
            return ( $line_ref, $new_line_ref );
        }
        $text_ref = $text_ref->[NEXT];
    }
    $line_ref->[ORD] = $ord;
    return $line_ref;
}

sub get_line_ords {
    my ($line_ref) = @_;

    my $previous_ref = $line_ref;
    while ( $previous_ref->[PREVIOUS_SAME] ) {
        $previous_ref = $previous_ref->[PREVIOUS];
    }
    while ( $line_ref->[NEXT_SAME] ) {
        $line_ref = $line_ref->[NEXT];
    }
    return ( $previous_ref->[ORD] - $previous_ref->[HEIGHT], $line_ref->[ORD] );
}

sub save_search {
    my ( $self, $exp, $line_start, $line_stop, $pos_start ) = @_;

    print "POS START = $pos_start\n";
    $self->[REGEXP] = {
        'line_start' => $line_start,
        'line_stop'  => $line_stop,
        'pos_start'  => $pos_start,
        'exp'        => $exp,
    };
}

sub load_search {
    my ($self) = @_;

    return $self->[REGEXP];
}

sub focus {
    my ( $self, $hash_ref ) = @_;

    at_top( $self, $hash_ref );

    #$self->deselect;
    $self->[GRAPHIC]->focus;
}

sub on_top_ref_editor {
    my ( $self, $zone ) = @_;
    
    if ( ref $zone ) {
        $zone = $zone->{'name'};
    }
    #print "Dans on_top_ref_editor : tid = ", threads->tid, "\n";
    my $edit_ref = Text::Editor::Easy::Graphic->get_editor_focused_in_zone($zone);
    if ( ! defined $edit_ref ) {
        print STDERR "No editor found on top of zone $zone\n";
        return;
    }
    return $edit_ref->[ID];
}

sub at_top {
    my ( $self ) = @_;
    my $zone = $self->[GRAPHIC]->get_zone;

    #print "Dans abstract at_top : zone = $zone, éditeur = ", $self->[PARENT]->name, "|self = $self\n";

    my ( $graphic, $old_editor ) = Text::Editor::Easy::Graphic->get_editor_focused_in_zone($zone);
    my $conf_ref;
    if ( defined $graphic and ref $graphic eq 'Text::Editor::Easy::Graphic' ) {
        #return if ( $graphic == $self->[GRAPHIC] );
        if ( defined $old_editor ) {
            #$call_id = on_focus_lost ( $old_editor );
            $conf_ref = on_focus_lost ( $old_editor );
            $old_editor = $old_editor->[PARENT];
        }
        if ( $graphic != $self->[GRAPHIC] ) {

        #print "Réel changement de at_top...$graphic|", $self->[GRAPHIC], "|\n";
            $graphic->forget;
        }
    }
    $self->[GRAPHIC]->at_top;

    #print "Appel de at_top pour l'éditeur ", $self->[PARENT]->name, " ZONE = $zone\n";
    return if ( ! defined $zone );
    
    my $event_ref = $zone_events{$zone};
    my $step = 'top_editor_change';
    if ( my $event = $event_ref->{$step} ) {
        my $editor = $self->[PARENT];
        my $hash_ref = $editor->load_info('conf');
        my @old_editor = ( 'old_editor', undef );
        if ( $old_editor ) {
            @old_editor = ( 'old_editor', $old_editor->id );
        }
        #print "Evènement top_editor_change défini pour zone = $zone\n";
        execute_events( $event, Text::Editor::Easy::Zone->whose_name($zone), {
                'editor'     => $self->[ID],
                'hash_ref'   => $hash_ref,
                @old_editor,
                'conf'       => $conf_ref,
            },
        );
    }
}

sub empty {    # Vidage de l'éditeur
    my ($self) = @_;

    # Horribles fuites mémoires !!
    # ------------------------------
    #sleep 2;

    clear_screen($self);

    $self->[PARENT]->empty_internal;

    #print "Taille self avant nettoyage :", total_size($self) , "\n";
    clean($self);

    #print "Taille self après nettoyage :", total_size($self), "\n";

    my $line_ref;
    $line_ref->[TEXT] = "";
    $line_ref->[REF]  = $self->[PARENT]->get_ref_for_empty_structure;
    create_text_in_line( $self, $line_ref );
    $self->display( $line_ref->[REF], { 'at' => 'top' } );

    # Positionnement du curseur
    cursor_set( $self, 0, $line_ref->[REF] );

    #sleep 2;

}

sub clean {
    my ($self) = @_;

    my $to_delete_ref = $self->[SCREEN][FIRST];
    $self->[SCREEN][FIRST] = 0;
    while ($to_delete_ref) {
        my $next_ref = $to_delete_ref->[NEXT];
        $to_delete_ref->[NEXT]     = 0;
        $to_delete_ref->[PREVIOUS] = 0;
        $to_delete_ref             = $next_ref;
    }
    $self->[SCREEN][LAST] = 0;
}

sub abstract_eval {
    my ( $self, $program ) = @_;

    print "\n\n$program\n", threads->tid, "$origin, $sub_origin\n";
    eval "$program";
    print $@ if ($@);
}

sub abstract_size {
    my $total;
    for my $self ( sort keys %abstract ) {
        my $size = total_size( $abstract{$self} );
        print "Taille $self : $size\n";
        $total += $size;
    }
    print "=> Taille totale : $total\n";
}

sub abstract_number {
    my @total = keys %abstract;
    return scalar @total;
}

sub increase_line_space {
    my ($self) = values %abstract;

    print "In increase_line_offset\n";
    $self->[GRAPHIC]->increase_line_offset;
    resize_all();
}

sub decrease_line_space {
    my ($self) = values %abstract;

    print "In increase_line_offset\n";
    $self->[GRAPHIC]->decrease_line_offset;
    resize_all();
}

sub paste {
        my ( $edit_ref ) = @_;
                 
        my $string = $edit_ref->[GRAPHIC]->clipboard_get;
        insert($edit_ref, $string, { 'bloc' => 1 } );
}        

sub resize_all {

#my @zones = Text::Editor::Easy::Zone->list;
#ZONE: for my $zone ( @zones ) {
#print "Zone $zone\n";
#my $graphic = Text::Editor::Easy::Graphic->get_graphic_focused_in_zone ( $zone );
    for my $abstract_ref ( values %abstract ) {

        #if ( $graphic == $abstract_ref->[GRAPHIC] ) {
        print "Text::Editor::Easy $abstract_ref->[ID]\n";
        $abstract_ref->deselect;
        resize(
            $abstract_ref,
            $abstract_ref->[SCREEN][WIDTH],
            $abstract_ref->[SCREEN][HEIGHT]
        );
    }
}

sub reference_zone_events {
    my ( $self, $name, $events ) = @_;

    $zone_events{$name} = {};

    print "Dans reference_zone_events : name = $name, event_ref = $events\n";
    my $hash_returned = Text::Editor::Easy::Events::reference_events( 'Text::Editor::Easy', $events );
    print "Valeur de retour de hash_returned : $hash_returned\n";
    return if ( ! ref $hash_returned );
    $zone_events{$name} = $hash_returned;
}

sub abstract_join {
    my ( $self, $tid ) = @_;

    print "Dans abstract_join tid = $tid\n";
    my $thread = threads->object($tid);
    $thread->join;
    return $tid;
}

sub exit {
    my ($rc) = @_;

    Text::Editor::Easy::Comm::untie_print();
    print "Dans exit |$rc|\n";
    exit 0 if ( !$rc or $rc =~ /\D/ );
    exit $rc;
}

sub on_focus_lost {
    my ( $edit_ref, $sync ) = @_;
    
    # Il faut : la première ligne à l'écran, sa position (ord et abs car décalage possible)
    # Il faut la position du curseur (ligne + position dans la ligne)
    # Il faut le mode wrap
    # La taille de la zone et la zone elle-même sont connues pas ailleurs
    my $screen_ref = $edit_ref->[SCREEN];
    my $first_line_ref = $screen_ref->[FIRST];
    my ( $cursor_line_ref, $cursor_pos ) = cursor_get ($edit_ref );
    
    my $caller = $edit_ref->[PARENT];

    return {
        'first_line_ref' => $first_line_ref->[REF],
        'first_line_ord' => $first_line_ref->[ORD],
        'offset' => $screen_ref->[VERTICAL_OFFSET],
        'cursor_line_ref' => $cursor_line_ref,
        'cursor_pos' => $cursor_pos,
        'wrap' => $screen_ref->[WRAP],
    };
}

sub debug_display_lines {
    my ( $edit_ref ) = @_;

    print "Dans debug_display_lines\n";
    my $line_ref = $edit_ref->[SCREEN][FIRST];
    while ( defined $line_ref ) {
        print $line_ref->[ORD], ":$line_ref:", $line_ref->[TEXT], "\n";
        $line_ref = $line_ref->[NEXT];
    }
}

sub graphic_kill {
    my ( $self ) = @_;
    
    print "Dans graphic_kill\n";
    $self->[GRAPHIC]->kill;    
    # Suppression des fontes, structures...
    
    # Evènement de Tab : on_editor_destroy
    my $zone = $self->[GRAPHIC]->get_zone;
    
    my $event_ref = $zone_events{$zone};
    my $step = 'editor_destroy';
    if ( my $event = $event_ref->{$step} ) {
        #print "Evènement editor_destroy défini pour zone = $zone\n";
        execute_events( $event, Text::Editor::Easy::Zone->whose_name($zone), { 
            'editor' => $self->[ID],
            'name' => $self->[PARENT]->name,
        } );
    }
}

sub on_editor_destroy { # zone event called on a Zone object
    my ( $self, $zone, $name ) = @_;
    return if ( ! defined $zone );
    
    my $event_ref = $zone_events{$zone};
    my $step = 'editor_destroy';
    if ( my $event = $event_ref->{$step} ) {
        execute_events( $event, $zone, { 
            'editor' => $self->[ID],
            'name' => $name,
        } );
    }
}

sub growing_check {
    my ( $self, $size_increment, $end ) = @_;
    
    #print "Dans growing_check $self, $size_increment, $end\n";
    if ( $self->[AT_END] ) {
        Text::Editor::Easy::Abstract::Key::end_file( $self, 0 );
        return;
    }
    my $screen_ref = $self->[SCREEN];
    my $last = $screen_ref->[LAST];
    if ( $last->[ORD] < $screen_ref->[HEIGHT] ) {
        print "Il faudrait remplir le bas de la zone : last (", $last->[REF], ") = ", $last->[TEXT], "\n";
        print "Texte de la dernière ligne |", $last->[TEXT], "|n";
        # Problème à résoudre d'un fichier qui grandit sans retour chariot ... (quand seule la dernière ligne grossit)
        display_bottom_of_the_screen ($self );
    }
}

sub set_at_end {
    my ( $self ) = @_;
    
    $self->[AT_END] = 1;
}


sub unset_at_end {
    my ( $self ) = @_;
    
    $self->[AT_END] = 0;
}

sub tell_order {
    my ( $self, $ref_a, $ref_b ) = @_;
    
    my ( $first, $last );
    my $line_ref = $self->[SCREEN][FIRST];
    while ( $line_ref ) {
        my $ref = $line_ref->[REF];
        if ( $ref == $ref_a ) {
            if ( $first ) {
                $last = $ref_a;
                return ( $first, $last );
            }
            $first = $ref_a;
        }
        if ( $ref == $ref_b ) {
            if ( $first ) {
                $last = $ref_b;
                return ( $first, $last );
            }
            $first = $ref_b;
        }
        
        while ( $line_ref->[NEXT_SAME] ) {
            $line_ref = $line_ref->[NEXT];
        }
        $line_ref = $line_ref->[NEXT];
    }
    return ( $first, $last );
}

sub area_select {
    my ( $self, $first_ref, $last_ref ) = @_;
    
    if ( $first_ref ne 'top' and ref $first_ref->[0] ) {
        print "First ref 0 = ", $first_ref->[0], "\n";
        $first_ref->[0] = $first_ref->[0]->id;
    }
    if ( $last_ref->[0] ne 'bottom' and ref $last_ref->[0] ) {
        $last_ref->[0] = $last_ref->[0]->id;
    }
    #print "Dans area_select je dois sélectionner de $first_ref->[0] position $first_ref->[1]\n";
    #print "   jusqu'à $last_ref->[0] position $last_ref->[1]\n";
    
    # Positionnement sur la première ligne avec déselection
    my $line_ref = $self->[SCREEN][FIRST];
    my $ref = $line_ref->[REF];
    #print "Référence de la première ligne : $ref\n";
    if ( $first_ref ne 'top' ) {
        while ( $ref != $first_ref->[0] ) {
            line_deselect ( $self, $ref );
            $line_ref = $line_ref->[NEXT];
            my $new_ref = $line_ref->[REF];
            if ( defined $new_ref ) {
                while ( $new_ref == $ref ) {
                    $line_ref = $line_ref->[NEXT];
                    $new_ref = $line_ref->[REF];
                }
                $ref = $new_ref;
            }
        }
    }
    # Sélection de la première ligne
    line_deselect ( $self, $ref );
    if ( $first_ref eq 'top' ) {
        if ( $last_ref->[0] != $ref ) {
            line_select ( $self, $ref );
        }
        else {
            line_select ( $self, $ref, 0, $last_ref->[1] );
            area_deselect_bottom ( $self, $ref, $line_ref );
            return;
        }
    }
    else {
        if ( $last_ref->[0] ne $ref ) {
            line_select ( $self, $ref, $first_ref->[1] );
        }
        else {
            #print "Sélection d'une seule ligne de $first_ref->[1] à $last_ref->[1]\n";
            line_select ( $self, $ref, $first_ref->[1], $last_ref->[1] );
            area_deselect_bottom ( $self, $ref, $line_ref );
            return;
        }
    }
    # Sélection des lignes suivantes (entièrement) jusqu'à la dernière
    $line_ref = $line_ref->[NEXT];
    return if ( ! defined $line_ref );
    my $new_ref = $line_ref->[REF];
    while ( $new_ref == $ref ) {
        $line_ref = $line_ref->[NEXT];
        $new_ref = $line_ref->[REF];
    }
    $ref = $new_ref;
    while ( $ref ne $last_ref->[0] ) {
        line_select( $self, $ref );
        $line_ref = $line_ref->[NEXT];
        return if ( ! defined $line_ref );
        my $new_ref = $line_ref->[REF];
        while ( $new_ref == $ref ) {
            $line_ref = $line_ref->[NEXT];
            return if ( ! defined $line_ref );
            $new_ref = $line_ref->[REF];
        }
        $ref = $new_ref;
    }
    return if ( $last_ref->[0] eq 'bottom' );
    line_deselect ( $self, $ref );
    line_select ( $self, $ref, 0, $last_ref->[1]);

    # Désélection des lignes du bas
    area_deselect_bottom ( $self, $ref, $line_ref );
}

sub area_deselect_bottom {
    my ( $self, $ref, $line_ref ) = @_;
    
    while ( 1 ) {
        $line_ref = $line_ref->[NEXT];
        return if ( ! defined $line_ref );
        my $new_ref = $line_ref->[REF];
        while ( $new_ref == $ref ) {
            $line_ref = $line_ref->[NEXT];
            return if ( ! defined $line_ref );
            $new_ref = $line_ref->[REF];
        }
        $ref = $new_ref;
        line_deselect ( $self, $ref );
    }
}

sub graphic_zone_update {
    my ( $self, $name, $hash_ref ) = @_;
    
    $self->[GRAPHIC]->zone_update($name, $hash_ref);
}

sub make_visible {
    my ( $self ) = @_;
    
    $self->[GRAPHIC]->put_at_top;
}

sub update_events {
    my ( $self, $ref, $id_ref, $options_ref ) = @_;
    
    # clé 'sequences'
    my $sequence_ref = $options_ref->{'sequences'};
    if ( defined $sequence_ref ) {
        #print STDERR "Il faut faire un update de sequence : ", dump( $sequence_ref ), "\n";
        for my $id ( @$id_ref ) {
            # Affectation inutile... (travail par référence)
            $abstract{$id}[SEQUENCES] = merge_sequence( $abstract{$id}[SEQUENCES], $sequence_ref );
        }
    }
    
    # clés 'event' et 'name'
    my $event_ref = $options_ref->{'event'};
    my $event_name = $options_ref->{'name'};
    if ( defined $event_name ) {
        for my $id ( @$id_ref ) {           
            $abstract{$id}[EVENTS]{$event_name} = $event_ref;
        }
    }
    
    # clés 'events'
    my $events = $options_ref->{'events'};
    if ( defined $events ) {
        for my $id ( @$id_ref ) {           
            $abstract{$id}[EVENTS] = $events;
        }
    }

}

sub merge_sequence {
    my ( $new_sequence_ref, $sequence_ref ) = @_;
    
    while ( my ( $name, $seq_ref ) = each %$sequence_ref ) {
        if ( defined $seq_ref ) {
            $new_sequence_ref->{$name} = $seq_ref;
        }
        else {
            # La clé existe, donc suppression
            delete $new_sequence_ref->{$name}
        }
    }
    return $new_sequence_ref;
}


sub background {
    my ( $self ) = @_;
    
    return $self->[GRAPHIC]->background;
}

sub set_background {
    my ( $self, $color ) = @_;
    
    $self->[GRAPHIC]->set_background( $color );
}

sub visual_slurp {    
    my ( $edit_ref, $sequence ) = @_;
    
    #print DBG "Dans méthode visual_slurp, séquence $sequence\n";
    
    my $slurp;
    my $line_ref = $edit_ref->[SCREEN][FIRST];
    my $indice = 1;
    
    while ( $line_ref ) {
        print DBG "\t$indice (", $line_ref->[REF], ") - ", $line_ref->[TEXT], "\n";
        $slurp .= $line_ref->[TEXT] . "\n";
        $line_ref = $line_ref->[NEXT];
    }
    chomp $slurp;
    return $slurp;
}

1;



=head1 FUNCTIONS

=head2 abstract_eval

=head2 abstract_join

=head2 abstract_size

=head2 add_tag

=head2 add_tag_complete

=head2 assist_on_inserted_text

=head2 bind_key

Affectation of code to a specific key for a specific instance (initial instance call "bind_key")

=head2 bind_key_global

Affectation of code to a specific key for all instances (initial class call "bind_key")

=head2 calc_line_position_from_display_position

=head2 change_reference

=head2 change_title

=head2 check_cursor

=head2 clean

=head2 clear_screen

=head2 clic

=head2 clipboard_get

Retrieve the content of the clipboard (for paste operation)

=head2 clipboard_set

Set the content of the clipboard (for copy operation)

=head2 concat

=head2 create_line_ref_from_ref

=head2 create_text_in_line

=head2 cursor_abs

=head2 cursor_display

=head2 cursor_get

=head2 cursor_set_shape

Test for future use of motion event according to position (borders of Text::Editor::Easy::Zone to resize them, for instance).

=head2 cursor_line

=head2 cursor_make_visible

=head2 cursor_position_in_display

=head2 cursor_position_in_text

=head2 cursor_set

=head2 cursor_virtual_abs

=head2 debug_display_lines

What is on the screen according to Abstract... ?

=head2 decrease_line_space

=head2 delete_return

=head2 delete_text_in_line

=head2 deselect

=head2 display

=head2 display_abs

=head2 display_bottom_of_the_screen

=head2 display_height

=head2 display_line_from_bottom

=head2 display_line_from_top

=head2 display_middle_ord

Return the middle ordinate of a displayed line.

=head2 display_next

=head2 display_next_is_same

=head2 display_number

=head2 display_ord

=head2 display_previous

=head2 display_previous_is_same

=head2 display_reference

=head2 display_reference_line

=head2 display_select

=head2 display_text

=head2 display_text_from_memory

=head2 display_top_of_the_screen

=head2 display_with_tag

=head2 divide_line

=head2 insert_mode

=head2 set_insert

=head2 set_replace

=head2 editor_visual_search

Selection of visible text that matches the search.

=head2 else

=head2 empty

=head2 enter

=head2 erase

=head2 examine_external_request

=head2 exit

=head2 focus

=head2 for

=head2 get_display_ref_from

=head2 get_display_ref_from_ord

=head2 get_displayed_editor

=head2 get_first_complete_line

=head2 get_line_number

=head2 get_line_number_from_ord

=head2 get_line_ords

=head2 get_line_ref_from_display_ref

=head2 get_line_ref_from_ord

=head2 get_line_ref_from_ref

=head2 get_position_from_line_and_abs

=head2 get_screen_size

=head2 graphic_kill

When an Text::Editor::Easy instance is created, data is created in several modules and for several threads.
Destruction is not properly done at the moment.

=head2 if

=head2 increase_font

=head2 increase_line_space

=head2 indent_on_return

=head2 init

=head2 inser

=head2 insert

=head2 key

=head2 line_deselect

Deselection of a single line.

=head2 line_displayed

=head2 line_ref_abs

=head2 line_select

=head2 line_set

Set the content of a line.

=head2 load_search

=head2 manage_event

=head2 motion

=head2 wheel

=head2 move_bottom

=head2 new

=head2 on_editor_destroy

A zone event called when an editor has been closed : useful to change the tab state.

=head2 on_focus_lost

Event used to update Text::Editor::Easy configuration.

=head2 at_top

=head2 on_top_ref_editor

Returns the reference of the Text::Editor::Easy instance that is above the other.

=head2 parent

=head2 paste

Copy the clipboard content to the cursor position.

=head2 position_cursor_in_display

=head2 position_cursor_in_line

=head2 read_next_line

=head2 read_previous_line

=head2 reference_zone_event

=head2 resize

=head2 resize_all

=head2 complete_line

=head2 revert

=head2 save_search

=head2 screen_check_borders

Prevent space to appear at the bottom (after the last line) or at the top (before the first line).

=head2 screen_first

=head2 screen_font_height

=head2 screen_height

=head2 screen_last

=head2 screen_line_height

=head2 screen_margin

=head2 screen_move

=head2 screen_number

=head2 screen_set_height

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;