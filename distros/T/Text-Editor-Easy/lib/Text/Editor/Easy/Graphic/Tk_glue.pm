package Text::Editor::Easy::Graphic::Tk_glue::Canva;

use base qw/Tk::Canvas/;
Construct Tk::Widget 'EditorCanva';

sub ClassInit {
    my ($class, $mw) = @_;
    
    # Don't look for default bindings
    #$class->SUPER::ClassInit($mw);
    
    # Adding "CanvasRaise" method, which enables to modify
    # stack order of Canvas objects between them
    *CanvasRaise = \&Tk::raise;
    *CanvasLower = \&Tk::lower;
}

package Text::Editor::Easy::Graphic;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Graphic::Tk_glue - Link between "Text::Editor::Easy::Abstract" and "Tk".

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Tk;
use Tk::Scrollbar;    # perl2exe
use Tk::Canvas;       # perl2exe

use Scalar::Util qw(refaddr);

# A un canevas, on fait correspondre un éditeur, l'éditeur qui a le focus
my %editor;

my %graphic;    # Liste des objets graphiques créés
my $repeat_id;

my %zone;
my %global_zone;

use constant {
    TOP_LEVEL => 0,
    CANVA     => 1,
    SCROLLBAR => 2,
    FIND      => 3,
    ZONE      => 4,

    # FIND
    #TOP_LEVEL => 0,
    ENTRY  => 1,
    REGEXP => 2,
};

sub new {
    my ( $class, $hash_ref ) = @_;

    my $self = [];
    bless $self, $class;
    $self->initialize($hash_ref);

    # Référencement
    $graphic{ refaddr $self} = $self;
    return $self;
}

sub initialize {
    my ( $self, $hash_ref ) = @_;
    my $mw;
    if ( $hash_ref->{main_window} ) {

        #print "La fenêtre principale a déjà été créée\n";
        $mw = $hash_ref->{main_window};
    }
    elsif (%graphic) {    # La mainwindow est déjà créée, on reprend la même
        for ( keys %graphic ) {
            if ( $_ != refaddr $self ) {
                $mw = $graphic{$_}->get_mw;

                # Cancel de la boucle provisoire
                $repeat_id->cancel;
                last;
            }
        }
    }
    else {
        $mw = create_main_window(
            $hash_ref->{'width'},    $hash_ref->{'height'},
            $hash_ref->{'x_offset'}, $hash_ref->{'y_offset'},
            $hash_ref->{'title'},
            $hash_ref->{'destroy'},
        );
    }
    $self->[TOP_LEVEL] = $mw;

    #$self->[SCROLLBAR] = create_scrollbar (
    #  $mw,
    #  $hash_ref->{vertical_scrollbar_sub},
    #    $hash_ref->{vertical_scrollbar_position},
    # );
    my $canva;
    my $zone_ref = $hash_ref->{'zone'};
    if ( $hash_ref->{canvas} ) {

        #print "Le canevas existe déjà\n";
        $canva = $hash_ref->{canvas};
    }
    else {
        ( $canva, $zone_ref ) = create_canva(
            $mw,
            $hash_ref->{background},
            $hash_ref->{'zone'},
            -xscrollincrement => 0,
            -yscrollincrement => 0,
        );
    }
    my $zone_name = $zone_ref->{'name'};
    #print "Affectation du nom de zone $zone_name à l'objet graphique $self\n";
    $self->[ZONE] = $zone_name;
    $global_zone{$zone_name} = $zone_ref;
    if ( $hash_ref->{editor_ref} ) {
        $editor{ refaddr $canva} = $hash_ref->{editor_ref};
    }
    $self->[CANVA] = $canva;

    #print "CANVA est un objet de type ", ref $canva, "\n";

    #$canva->bindtags(undef);
    #$canva->bind('text', <KeyPress>, sub {}) ;
    #$mw->bind('Tk::text', <KeyPress>, sub {}) ;


# CLIC SUBSET
    $canva->CanvasBind( '<Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => '',
    } ] );
    
    $canva->CanvasBind( '<Alt-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => 'alt_',
    } ] );
    
    $canva->CanvasBind( '<Control-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'ctrl_',
    } ] );

    $canva->CanvasBind( '<Shift-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'shift_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Control-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'alt_ctrl_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Shift-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'alt_shift_',
    } ] );
    
    $canva->CanvasBind( '<Control-Shift-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'ctrl_shift_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Control-Shift-Button-1>', [
         \&redirect_x_y, $hash_ref->{'clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'alt_ctrl_shift_',
    } ] );

# DOUBLE CLIC SUBSET
    $canva->CanvasBind( '<Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => '',
    } ] );

    $canva->CanvasBind( '<Alt-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => 'alt_',
    } ] );
    
    $canva->CanvasBind( '<Control-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'ctrl_',
    } ] );

    $canva->CanvasBind( '<Shift-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'shift_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Control-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'alt_ctrl_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Shift-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'alt_shift_',
    } ] );
    
    $canva->CanvasBind( '<Control-Shift-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'ctrl_shift_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Control-Shift-Double-Button-1>', [
         \&redirect_x_y, $hash_ref->{'double_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'alt_ctrl_shift_',
    } ] );
    
# RIGHT CLIC SUBSET
    $canva->CanvasBind( '<Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => '',
    } ] );

    $canva->CanvasBind( '<Alt-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => 'alt_',
    } ] );
    
    $canva->CanvasBind( '<Control-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'ctrl_',
    } ] );

    $canva->CanvasBind( '<Shift-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'shift_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Control-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'alt_ctrl_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Shift-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'alt_shift_',
    } ] );
    
    $canva->CanvasBind( '<Control-Shift-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'ctrl_shift_',
    } ] );
    
    $canva->CanvasBind( '<Alt-Control-Shift-Button-3>', [
         \&redirect_x_y, $hash_ref->{'right_clic'}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'alt_ctrl_shift_',
    } ] );


# MOUSE WHEEL SUBSET
    $canva->CanvasBind( '<MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'}, 
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => '',
    ] );

    $canva->CanvasBind( '<Alt-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => 'alt_',
    ] );
    
    $canva->CanvasBind( '<Control-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'ctrl_',
    ] );

    $canva->CanvasBind( '<Shift-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'shift_',
    ] );
    
    $canva->CanvasBind( '<Alt-Control-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'alt_ctrl_',
    ] );
    
    $canva->CanvasBind( '<Alt-Shift-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'alt_shift_',
    ] );
    
    $canva->CanvasBind( '<Control-Shift-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'ctrl_shift_',
    ] );
    
    $canva->CanvasBind( '<Alt-Control-Shift-MouseWheel>', [
        \&redirect, $hash_ref->{'mouse_wheel_event'},
            'unit' => Ev('D'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'alt_ctrl_shift_',
    ] );

# MOTION SUBSET
    $canva->CanvasBind( '<Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => '',
    } ] );
        
    $canva->CanvasBind( '<Alt-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => 'alt_',
    } ] );

    $canva->CanvasBind( '<Control-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'ctrl_',
    } ] );

    $canva->CanvasBind( '<Shift-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'shift_',
    } ] );

    $canva->CanvasBind( '<Alt-Control-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'alt_ctrl_',
    } ] );

    $canva->CanvasBind( '<Alt-Shift-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'alt_shift_',
    } ] );

    $canva->CanvasBind( '<Control-Shift-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'ctrl_shift_',
    } ] );

    $canva->CanvasBind( '<Alt-Control-Shift-Motion>', [
         \&redirect_x_y, $hash_ref->{motion}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'alt_ctrl_shift_',
    } ] );

# DRAG SUBSET
    $canva->CanvasBind( '<B1-Motion>', [
         \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => '',
    } ] );

    $canva->CanvasBind( '<Alt-B1-Motion>', [
        \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0, },
            'meta' => 'alt_',
    } ] );

    $canva->CanvasBind( '<Control-B1-Motion>', [
         \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'ctrl_',
    } ] );

    $canva->CanvasBind( '<Shift-B1-Motion>', [
        \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'shift_',
    } ] );

    $canva->CanvasBind( '<Alt-Control-B1-Motion>', [
        \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0, },
            'meta' => 'alt_ctrl_',
    } ] );

    $canva->CanvasBind( '<Alt-Shift-B1-Motion>', [
        \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1, },
            'meta' => 'alt_shift_',
    } ] );

    $canva->CanvasBind( '<Control-Shift-B1-Motion>', [
        \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'ctrl_shift_',
    } ] );

    $canva->CanvasBind( '<Alt-Control-Shift-B1-Motion>', [
        \&redirect_x_y, $hash_ref->{drag}, Ev('x'), Ev('y'), {
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1, },
            'meta' => 'alt_ctrl_shift_',
    } ] );


    $canva->CanvasBind( '<Configure>',
        [ \&resize, $hash_ref->{resize}, Ev('w'), Ev('h') ] );

# KEY_PRESS SUBSET
    $canva->CanvasBind( '<KeyPress>' =>
        [ \&redirect,$hash_ref->{key_press}, 
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'ctrl'  => 0, 'alt'   => 0, 'shift' => 0},
            'meta'      => '',
        ]
    );
    $canva->CanvasBind( '<Alt-KeyPress>' => 
        [ \&redirect,$hash_ref->{key_press}, 
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 0},
            'meta'      => 'alt_',
        ]
    );
    $canva->CanvasBind( '<Control-KeyPress>' => 
        [ \&redirect,$hash_ref->{key_press}, 
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 0},
            'meta'      => 'ctrl_',
        ]
    );
    $canva->CanvasBind( '<Shift-KeyPress>' => 
        [ \&redirect, $hash_ref->{key_press},
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 0, 'shift' => 1},
            'meta'      => 'shift_',
        ]
    );
    $canva->CanvasBind( '<Control-Shift-KeyPress>' => 
        [ \&redirect, $hash_ref->{key_press},
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 0, 'ctrl'  => 1, 'shift' => 1 },
            'meta'      => 'ctrl_shift_',
        ]
    );
    $canva->CanvasBind( '<Control-Alt-KeyPress>' => 
        [ \&redirect, $hash_ref->{key_press},
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 0},
            'meta'      => 'alt_ctrl_',
        ]
    );

    $canva->CanvasBind( '<Shift-Alt-KeyPress>' => 
        [ \&redirect, $hash_ref->{key_press},
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 0, 'shift' => 1},
            'meta'      => 'alt_shift_',
        ]
    );

    $canva->CanvasBind( '<Shift-Alt-Control-KeyPress>' => 
        [ \&redirect, $hash_ref->{key_press},
            'key'       => Ev('K'),
            'text'      => Ev('A'),
            'uni'       => Ev('N'),
            'ascii'     => Ev('k'),
            'meta_hash' => { 'alt'   => 1, 'ctrl'  => 1, 'shift' => 1},
            'meta'      => 'alt_ctrl_shift_',
        ]
    );
    
    $canva->xviewMoveto(0);
    $canva->yviewMoveto(0);

    #$mw->repeat(10, [ $hash_ref->{repeat}, $editor{refaddr $canva} ] );
}

sub launch_loop {
    my ( $self, $sub, $seconds ) = @_;

   #print "Lancement d'une boucle seconds = $seconds\n";
    
   return $self->[TOP_LEVEL]->repeat( $seconds * 1000, $sub );
}

sub set_repeat_id {
    my ( $self, $id ) = @_;
    $repeat_id = $id;
}

sub redirect {
    my ( $canva, $sub_ref, @data ) = @_;

    my $editor_ref = $editor{ refaddr $canva};
    my %info = @data;
    #my $return = $sub_ref->( $editor_ref, @data );
    my $return = $sub_ref->( $editor_ref, \%info );
    $return = 'event not yet traced' if ( ! defined $return );
    Text::Editor::Easy->trace_end_of_user_event( $return );
}

sub redirect_x_y {
    my ( $canva, $sub_ref, $x, $y, $info_ref ) = @_;

    my $editor_ref = $editor{ refaddr $canva};
    $info_ref->{'x'} = $x;
    $info_ref->{'y'} = $y;
    
    my $return = $sub_ref->( $editor_ref, $info_ref );
    $return = 'event not yet traced' if ( ! defined $return );
    Text::Editor::Easy->trace_end_of_user_event( $return );
}

sub key_press {
    my ( $canva, $self, $sub_ref, $key, $ascii ) = @_;
    my $editor_ref = $editor{ refaddr $canva};

    if ( $key eq "Control_L" or $key eq "Control_R" ) {
        return;
    }
    if ( $key eq "Alt_L" ) {
        return;
    }
    if ( $key eq "Shift_L" or $key eq "Shift_R" ) {
        return;
    }

    my $return = $sub_ref->(
        $editor_ref,
        $key, $ascii,
        {
            'ctrl'  => 0,
            'alt'   => 0,
            'shift' => 0,
        }
    );

    # Tk->break ne marche pas car le déplacement du canevas s'effectue avant :
    # touches up, down, right et left
    $canva->xviewMoveto(0);
    $canva->yviewMoveto(0);
    $return = 'event not yet traced' if ( ! defined $return );
    Text::Editor::Easy->trace_end_of_user_event ( $return );
}

sub create_main_window {
    my ( $width, $height, $x, $y, $title, $sub_ref_destroy ) = @_;
    my $mw = MainWindow->new( -title => $title );
    
    if ( ref $sub_ref_destroy ) {
        #print "subref_destroy : $sub_ref_destroy, ", ref $sub_ref_destroy, "\n";
        #$mw->bind( '<Destroy>', [ \&destroy, $mw ] );
        $mw->bind( 'MainWindow', '<Destroy>', [ \&destroy, $sub_ref_destroy ] );
    #$canva->CanvasBind( '<Configure>', [ \&resize, $hash_ref->{resize}, Ev('w'), Ev('h') ] );

    }
    
    if ( defined $width and $height ) {
        if ( defined $x and $y ) {
            $mw->geometry("${width}x$height+$x+$y");
        }
        else {
            $mw->geometry("${width}x$height");
        }
    }
    #$mw->geometry("${width}x$height+$x+$y");
    return $mw;
}

sub destroy {
    my ( $mw, $sub_ref ) = @_;

    print "MW = $mw ", ref $mw, ", sub_ref = $sub_ref\n";
    my $geometry = $mw->geometry;
    my ( $width, $height, $x, $y ) = $geometry =~ /((?:-|)\d+)x((?:-|)\d+)\+((?:-|)\d+)\+((?:-|)\d+)/;
    print "Geométrie : ", $mw->geometry, "\n";
    print "Dans destroy\n";
    $sub_ref->( $width, $height, $x, $y );
}

sub get_geometry {
    my ($self) = @_;

    my $geometry = $self->[TOP_LEVEL]->geometry;
    my ( $width, $height, $x, $y ) = $geometry =~ /((?:-|)\d+)x((?:-|)\d+)\+((?:-|)\d+)\+((?:-|)\d+)/;
    return ( $width, $height, $x, $y, $geometry );
}

sub set_geometry {
    my ( $self, $width, $height, $x, $y ) = @_;

    $self->[TOP_LEVEL]->geometry("${width}x$height+$x+$y");
}

sub change_title {
    my ( $self, $title ) = @_;

    $self->[TOP_LEVEL]->configure( -title => $title );
}

sub create_scrollbar {
    my ( $mw, $call_back_ref, $position ) = @_;

    my $scrollbar =
      $mw->Scrollbar( -command => $call_back_ref, )
      ->pack( -side => $position, -fill => 'y' );
    return $scrollbar;    # inutile mais plus prudent en cas d'ajout...
}

sub create_canva {
    my ( $mw, $color, $zone_ref ) = @_;
    my %zone_local;
    if ( !defined $zone_ref ) {
        %zone_local = (
            'size' => {
                -x         => 0,
                -y         => 0,
                -relwidth  => 1,
                -relheight => 1,
            },
            'name'     => 'none'
        );
        Text::Editor::Easy->reference_zone( \%zone_local );
        $zone_ref = \%zone_local;
    }
    else {
        %zone_local = %$zone_ref;
    }

    #print "DAns create canva : ", $zone_ref->{'name'}, "\n";
    my $size_ref = $zone_local{'size'};
    
    my $canva = $mw->EditorCanva(
        -background => $color,
        #)->pack( -expand => 1, -fill => 'both' );
    )->place( -in => $mw, %{ $size_ref } );
    
    #print "\n\nDump des évènement gérés :\n";
    #Tk::Widget::bindDump( $mw );
    #print "Fin du dump :\n\n";
    
    $canva->CanvasLower;
    return ( $canva, $zone_ref );
}

sub create_font {
    my ( $graphic, $hash_ref ) = @_;
    my @underline;
    if ( $hash_ref->{underline} ) {
        @underline = ( "-underline", 1 );
    }
    my @slant = ( "-slant", "roman" );
    if ( $hash_ref->{slant} ) {
        @slant = ( "-slant", $hash_ref->{slant} );
    }
    return $graphic->[TOP_LEVEL]->fontCreate(
        -family => $hash_ref->{family},
        -size   => $hash_ref->{size},
        -weight => $hash_ref->{weight},
        @underline,
        @slant,
    );
}

sub clipboard_get {
    my ( $self ) = @_;
        
    my $string = $self->[TOP_LEVEL]->SelectionGet( 
        -selection => "CLIPBOARD" ,
        -type => "STRING"
    );
    
    # Null character not managed by Tk (?)
    # My former regular exp didn't work ===> s/x00.*$//
    my @lines = split( /\n/, $string, -1 );
    my $buffer = q{};
    my $line = shift( @lines );
    for my $indice ( 0..length($line)-1 ) {
        my $char = substr( $line, $indice, 1 );
        if ( ord($char) == 0 ) {
            return $buffer;
        }
        $buffer .= $char;
    }

    CONCAT: for my $line ( @lines ) {
        $buffer .= "\n";
        for my $indice ( 0..length($line)-1 ) {
            my $char = substr( $line, $indice, 1 );
            if ( ord($char) == 0 ) {
                return $buffer;
            }
            $buffer .= $char;
        }
    }
    return $buffer;
}

sub clipboard_set {
    my ( $self, $string ) = @_;
        
    #print "Dans clipboard_set de Tk_glue |$self|$string|\n";
    # usefull ?
    $self->[TOP_LEVEL]->clipboardClear;

    $self->[TOP_LEVEL]->clipboardAppend('--', $string);
    return 1;
}

sub manage_event {

    #my ( $self ) = @_;
    #print "On rentre dans la mainloop\n";
    MainLoop;
}

# After initialisation

sub length_text {
    my ( $self, $text, $font ) = @_;
    
    if ( $text =~ /^(-+)/ ) {
        # Le texte "-d" est malheureusement vu comme une option "display_of" de la méthode fontMeasure dans Tk
        # L'appel Tk font->measure ne marchant pas mieux (pas du tout !), il faut décomposer toutes les chaînes qui commencent par un "-"
        my $length = 0;
        $length += $self->[CANVA]->fontMeasure( $font, "$1" );
        $text = substr ( $text, length($1) );
        $length += $self->[CANVA]->fontMeasure( $font, $text );
        return $length;
    }
        
    return $self->[CANVA]->fontMeasure( $font, $text );
}

sub set_scrollbar {
    my ( $self, $top, $bottom ) = @_;

    #$self->[SCROLLBAR]->set ( $top, $bottom);
    return ( $top, $bottom );
}

sub get_scrollbar {
    my ($self) = @_;

    #return $self->[SCROLLBAR]->get;
}

my $line_offset = 3;

sub create_text_and_mark_it {
    my ( $self, $hash_ref ) = @_;

    my $id = $self->[CANVA]->createText(
        $hash_ref->{abs},
        $hash_ref->{ord},

        #-tag    => ['text', 'just_created'] ,
        -tag    => $hash_ref->{tag},
        -text   => $hash_ref->{text},
        -anchor => $hash_ref->{anchor},
        -font   => $hash_ref->{font},
        -fill   => $hash_ref->{color},
    );
    my ( $x1, $y1, $x2, $y2 ) = $self->[CANVA]->bbox($id);

#    $self->[CANVA]->bind('text', <KeyPress>, sub {}) ;
#    $self->[TOP_LEVEL]->bind('Tk::text', <KeyPress>, sub {}) ;

    #return ( $id, $x2 - $x1 - 2, $y2 - $y1 - 2);
    return ( $id, $x2 - $x1 - 2, $y2 - $y1 + $line_offset );

}

sub size_id {
    my ( $self, $id ) = @_;

    my ( $x1, $y1, $x2, $y2 ) = $self->[CANVA]->bbox($id);

    #return ( $x2 - $x1 - 2, $y2 - $y1 - 2);
    return ( $x2 - $x1 - 2, $y2 - $y1 + $line_offset );
}

sub increase_line_offset {
    $line_offset += 1;
}

sub decrease_line_offset {
    $line_offset -= 1;
}

sub create_text {
    my ( $self, $hash_ref ) = @_;

    my $id = $self->[CANVA]->createText(
        $hash_ref->{abs},
        $hash_ref->{ord},
        -tag    => 'text',
        -text   => $hash_ref->{text},
        -anchor => $hash_ref->{anchor},
        -font   => $hash_ref->{font},
        -fill   => $hash_ref->{color},
    );
    my ( $x1, $y1, $x2, $y2 ) = $self->[CANVA]->bbox($id);

    #$self->[CANVA]->bind('text', <KeyPress>, sub {}) ;
    #$self->[TOP_LEVEL]->bind('Tk::text', <KeyPress>, sub {}) ;

    return ( $id, $x2 - $x1 - 2, $y2 - $y1 - 2 );

}

sub delete_mark_from_text {
    my ($self) = @_;

    $self->[CANVA]->dtag( 'just_created', 'just_created' );
}

sub delete_tag {
    my ( $self, $tag ) = @_;

    $self->[CANVA]->dtag( $tag, $tag );
}

sub change_text_item_property {
    my ( $self, $text_id, $text ) = @_;

    $self->[CANVA]->itemconfigure( $text_id, -text, $text );
}

sub delete_text_item {
    my ( $self, $text_id ) = @_;

    $self->[CANVA]->delete($text_id);
}

sub position_cursor_in_text_item {
    my ( $self, $text_id, $position ) = @_;

    #$self->[CANVA]->CanvasFocus;
    $self->[CANVA]->focus($text_id);
    $self->[CANVA]->icursor( $text_id, $position );
}

sub canva_focus {
    my ($self) = @_;

    $self->[CANVA]->CanvasFocus;
}

sub at_top {
    my ($self) = @_;

    $self->[CANVA]->CanvasRaise;
    #my %local_zone = %{ $self->[ZONE] };
    my $zone_name = $self->[ZONE];

    #print "Appel de at_top pour l'objet graphique $self, nom de zone : $zone_name\n";

    return if ( ! defined $zone_name );

    $zone{ $zone_name } = $self;

    my %local_zone = %{ $global_zone{$zone_name} };
    
    $self->[CANVA]->place( -in => $self->[TOP_LEVEL], %{ $local_zone{'size'} } );

    #$self->[CANVA]->CanvasFocus;
}

sub focus {
    my ($self) = @_;

    at_top($self);
    $self->[CANVA]->CanvasFocus;
}

sub get_zone {
    my ($self) = @_;

    return $self->[ZONE];
}

sub get_graphic_focused_in_zone {
    my ( $self, $zone ) = @_;

    if ( !defined $zone ) {
        print STDERR
"Zone must be defined when calling Text::Editor::Graphic::Tk_gue::get_graphic_focused_in_zone\nCan't return Text::Editor::Easy who has focus in an undefined zone\n";
        return;
    }
    return $zone{$zone};
}

sub get_editor_focused_in_zone {
    my ( $self, $zone ) = @_;

    if ( !defined $zone ) {
        print STDERR
"Zone must be defined when calling Text::Editor::Graphic::Tk_gue::get_graphic_focused_in_zone\nCan't return Text::Editor::Easy who has focus in an undefined zone\n";
        return;
    }
    my $graphic = $zone{$zone};
    #print "Dans get_editor_focused_in_zone : zone $zone, graphic = $graphic|", $graphic->[CANVA], "\n";
    if ( ! defined $graphic or ! defined ( refaddr $graphic->[CANVA] ) ) {
        #print STDERR "Can't find focused canva in zone $zone\n";
        return;
    }
    my $editor = $editor{ refaddr ($graphic->[CANVA]) };
    if ( wantarray ) {
        return ( $graphic, $editor );
    }
    else {
        return $editor;
    }
}

sub forget {
    my ($self) = @_;

    return if ( ! $self->[CANVA] );
    $self->[CANVA]->placeForget;
}

sub resize {
    my ( $canva, $sub_ref, $height, $width ) = @_;

    #$canva->configure( -scrollregion => [ 2, 2, $width - 2, $height - 2] );
    $canva->configure( -scrollregion => [ 1, 1, $width - 1, $height - 1 ] );

    my $editor_ref = $editor{ refaddr $canva};

    #print "Avant appel resize : $editor_ref\n";
    #print "\t$editor_ref->[8]\n";
    #print "\t$editor_ref\n";
    $sub_ref->( $editor_ref, $height, $width );
}

sub move_tag {
    my ( $self, $tag, $x, $y ) = @_;

    $self->[CANVA]->move( $tag, $x, $y );
}

sub destroy_find {
    my ( $find, $self ) = @_;

    undef $self->[FIND][TOP_LEVEL];
}

sub change_reference {

    # Avant d'appeler cette fonction, faire le ménage sur le canevas
    my ( $self, $edit_ref, $file_name ) = @_;

    $editor{ refaddr $self->[CANVA] } = $edit_ref;
    $self->[TOP_LEVEL]->configure( -title => $file_name );
}

sub edit_ref {
    my ( $self ) = @_;
    
    return $editor{ refaddr $self->[CANVA] };
}

sub get_displayed_editor {
    my ($editor) = @_;

    my $canva = $editor->[CANVA];
    return $editor{ refaddr $canva };
}

sub set_font_size {
    my ( $self, $font, $size ) = @_;

    $font->delete;
    $font->configure( -size => $size );
}

sub line_height {
    return 30;
}

sub margin {
    return 10;
}

sub clear_screen {
    my ($self) = @_;

    $self->[CANVA]->delete('text');
}

sub key_release {
    my ( undef, $self, $key ) = @_;

    if ( $key eq "Control_L" or $key eq "Control_R" ) {
        return;
    }
    if ( $key eq "Alt_L" ) {
        return;
    }
    if ( $key eq "Shift_L" or $key eq "Shift_R" ) {
        return;
    }
}

sub move_bottom {
    my ( $self, $how_much ) = @_;

    #print "TK glue : move bottom de $how_much\n";
    $self->[CANVA]->move( 'bottom', 0, $how_much * 17 );
}

sub add_tag {
    my ( $self, $tag, $id, $debug ) = @_;
    
#    if ( $debug ) {
#        print "\$self $self, \$canva ", $self->[CANVA], " \$tag $tag, \$id $id\n";
#    }        
    $self->[CANVA]->addtag( $tag, 'withtag', $id );
#    if ( $debug ) {
#        print "Fin de add_tag\n";
#    }        
}

sub select {
    my ( $self, $x1, $y1, $x2, $y2, $color, $tag ) = @_;

    if ( !defined $color ) {
        $color = 'yellow';
    }

    #print "$x1|$y1|$x2|$y2|\n";
    my @tag = ( '-tag'  => 'select' );
    if ( defined $tag ) {
        #print "Tag défini : $tag\n";
        @tag = ( '-tag'  => [ 'select', $tag ] );
    }

    $self->[CANVA]->createRectangle(
        $x1, $y1, $x2, $y2,
        -fill => $color,
        @tag
    );
    $self->[CANVA]->lower( 'select', 'text' );
}

sub delete_select {
    my ($self) = @_;

    #print "Suppression des zones sélectionnées...\n";

    $self->[CANVA]->delete('select');
}

sub delete_whose_tag {
    my ($self, $tag) = @_;

    return if ( ! defined $tag );

    $self->[CANVA]->delete($tag);
}

sub get_mw {
    my ($self) = @_;

    return $self->[TOP_LEVEL];
}

sub cursor_set_shape {
        my ( $self, $type ) = @_;
        
        #$self->[CANVA]->configure(-cursor => 'sb_h_double_arrow');
        $self->[CANVA]->configure(-cursor => $type);
        #$self->[CANVA]->configure(-cursor => 'top_left_arrow');
}

sub cursor_get_shape {
    my ( $self ) = @_;
        
        #$self->[CANVA]->configure(-cursor => 'sb_h_double_arrow');
    return $self->[CANVA]->cget('-cursor');
}

sub kill {
    my ( $self ) = @_;
    
    $self->[CANVA]->destroy;

    delete $editor{ refaddr($self->[CANVA]) };
    undef $self->[CANVA];
    delete $graphic{ refaddr $self};
}

sub zone_update {
    my ( $self, $name, $hash_ref ) = @_;
    
    print "Dans Tk_glue zone_update : name = $name\n";
    $self = get_graphic_focused_in_zone ( $self, $name );
    $global_zone{$name} = $hash_ref;
    
    if ( ! defined $self ) {
        print STDERR "No 'Text::Editor::Easy::Graphic' instance found on top of zone named $name\n";
        return;
    }
    $self->forget;
    $self->at_top;
}

sub put_at_top {
    my ( $self ) = @_;
    
    $self->[CANVA]->CanvasRaise;
}

sub set_background {
    my ( $self, $color ) = @_;
    
    eval {
        $self->[CANVA]->configure( -background => $color );
    }
}

sub background {
    my ( $self ) = @_;
    
    return $self->[CANVA]->cget('-background');
}
    

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

















