package Text::Editor::Easy::Graphic;

use warnings;
use strict;

=head1 NAME

Text::Editor::Easy::Graphic::Gtk_glue - Link between "Text::Editor::Easy::Abstract" and "Gtk". Does not actually work.

=head1 VERSION

Version 0.49

=cut

our $VERSION = '0.49';

use Gtk2 -init;

#use Gnome2::Canvas;
use Gtk2::Gdk::Keysyms;
use Glib;    # Timeout for cursor

use constant {
    TOP_LEVEL => 0,
    CANVA     => 1,
    SCROLLBAR => 2,
    CURSOR    => 3,
    MARKED    => 4,
    SHIFTX    => 5,
    SHIFTY    => 6,

    # Elément d'un curseur
    ABS     => 0,
    ORD     => 1,
    TEXT_ID => 2,
    COLOR   => 3,
    IMAGE   => 4,

    # Element d'un TEXT_ID
    #ABS => 0,
    #ORD => 1,
    FONT => 2,

    #COLOR => 3,
    TEXT   => 4,
    LAYOUT => 5,
    WIDTH  => 6,
    HEIGHT => 7,

    # Tableau de texte marqué
};

#my %graphic_object; # Retrouve une correspondance entre un objet graphique GTK (clé) et l'objet "Graphic" auquel il appartient
# Inutile si on sait envoyer des paramètres supplémentaires aux callbacks

my $canvas;
my $resize_ref;

sub new {
    my ( $class, $hash_ref ) = @_;

    my $self = [];
    bless $self, $class;
    $self->initialize($hash_ref);
    return $self;
}

sub initialize {
    my ( $self, $hash_ref ) = @_;

    my $mw = Gtk2::Window->new;

    #my $scroller = Gtk2::ScrolledWindow->new;
    $canvas = Gtk2::DrawingArea->new;
    print "Canva = $canvas\n";

    #$mw->add ($scroller);
    $mw->add($canvas);
    $mw->set_default_size( $hash_ref->{width}, $hash_ref->{height} );

    #$canvas->set_scroll_region (0, 0, $hash_ref->{width}, $hash_ref->{height});
    $self->[TOP_LEVEL] = $mw;

    #$self->[SCROLLBAR] = $scroller;
    $self->[CANVA] = $canvas;

    $mw->signal_connect( 'delete_event' => sub { Gtk2->main_quit; } );

    $resize_ref = $hash_ref->{resize};
    $canvas->signal_connect( 'configure_event', \&resize );

    #  $self->[RESIZE_REF] = $resize_ref;

    $mw->signal_connect( 'key_press_event', \&key_event,
        $hash_ref->{key_press} );
    $mw->signal_connect( 'key_release_event', \&key_event,
        $hash_ref->{key_release} );
    $canvas->signal_connect( 'expose_event', \&expose_event );

    #$self->[CURSOR][COLOR] = 'black';
    Glib::Timeout->add( 300, \&redraw_cursor, $self );

#  $canva->CanvasBind( '<Button-1>',  [ $hash_ref->{clic}, Ev('x'), Ev('y') ] );
#  $canva->CanvasBind('<4>', [$hash_ref->{mouse_wheel_event}, Ev('D')]);
#  $canva->CanvasBind('<5>', [$hash_ref->{mouse_wheel_event}, Ev('D')]);
}

sub expose_event {
    my ( $widget, $event ) = @_;

    $resize_ref->( $canvas->allocation->height, $canvas->allocation->width );
}

sub key_event {
    my ( $object, $event, $sub_ref ) = @_;

    print "Data = $sub_ref\n";
    my $key_code  = $event->hardware_keycode;
    my $key_val   = $event->keyval;
    my $key_group = $event->group;
    print "key_code $key_code, keyval $key_val, group $key_group\n";
    my $code;
    for ( keys %Gtk2::Gdk::Keysyms ) {
        if ( $key_val == $Gtk2::Gdk::Keysyms{$_} ) {
            print "Code = $_\n";
            $code = $_;
            last;
        }
    }
    my $ascii = $code;
    if ( $code eq 'space' ) {
        $ascii = ' ';
    }
    $sub_ref->( $code, $ascii );
}

sub create_main_window {
    my ( $width, $height, $x, $y, $title ) = @_;
}

sub create_scrollbar {
    my ( $mw, $call_back_ref, $position ) = @_;
}

sub create_canva {
    my ( $mw, $color ) = @_;
}

sub create_font {
    my ( $graphic, $hash_ref ) = @_;

    my $text_font =
      $hash_ref->{family} . " " . $hash_ref->{weight} . " " . $hash_ref->{size};
    my $font = Gtk2::Pango::FontDescription->new;
    $font->set_family( $hash_ref->{family} );
    $font->set_size( $hash_ref->{size} * 1024 );
    $font->set_weight( $hash_ref->{weight} );

    #($text_font);
    print "Fonte = $font\n";

    #return 'Sans 14';
    return $font;
}

sub manage_event {
    my ($self) = @_;

    # La méthode "show_all" va générer le resize générateur initial
    $self->[TOP_LEVEL]->show_all;
    Gtk2->main;
}

# After initialisation

sub length_text {
    my ( $self, $text, $font ) = @_;

    my $layout = $self->[CANVA]->create_pango_layout($text);
    $layout->set_font_description($font);
    my ( $width, $height ) = $layout->get_pixel_size;
    return $width;
}

sub set_scrollbar {
    my ( $self, $top, $bottom ) = @_;

    #  $self->[SCROLLBAR]->set ( $top, $bottom);
}

sub get_scrollbar {
    my ($self) = @_;

    #  return $self->[SCROLLBAR]->get;
}

sub create_text_and_mark_it {
    my ( $self, $hash_ref ) = @_;

    my $text_ref;
    $text_ref->[ABS]   = $hash_ref->{abs};
    $text_ref->[ORD]   = $hash_ref->{ord};
    $text_ref->[COLOR] = $hash_ref->{color};
    $text_ref->[FONT]  = $hash_ref->{font};
    $text_ref->[TEXT]  = $hash_ref->{text};

    display_text( $self->[CANVA], $text_ref );

    push @{ $self->[MARKED] }, $text_ref;
    return $text_ref;
}

sub display_text {
    my ( $canvas, $text_ref ) = @_;

    my $layout = $canvas->create_pango_layout( $text_ref->[TEXT] );
    $layout->set_font_description( $text_ref->[FONT] );

    my $gc = $canvas->get_style->text_gc( $canvas->state );

    my $colormap    = $canvas->get_colormap;
    my $color       = Gtk2::Gdk::Color->parse( $text_ref->[COLOR] );
    my $alloc_color = $colormap->alloc_color( $color, 1, 1 );

    $gc->set_foreground($color);
    $canvas->window->draw_layout( $gc, $text_ref->[ABS], $text_ref->[ORD],
        $layout );
    my ( $width, $height ) = $layout->get_pixel_size;
    $text_ref->[WIDTH]  = $width;
    $text_ref->[HEIGHT] = $height;
    $text_ref->[LAYOUT] = $layout;
}

sub delete_text_item {
    my ( $self, $text_ref, $speed ) = @_;

    return if ($speed);    # Pas concerné
    my $layout = $text_ref->[LAYOUT];

    #  if ( ! $layout ) {
    #    print ":ORD :", $text_ref-[ORD], "\n";
    #  }
    return
      if ( !$layout )
      ;    # Il y a un bug de suppression d'élément déjà supprimé ...

    my $width  = $text_ref->[WIDTH];
    my $height = $text_ref->[HEIGHT];
    my $abs    = $text_ref->[ABS] + $self->[SHIFTX];
    my $ord    = $text_ref->[ORD] + $self->[SHIFTY];

    #print "shift Y = $self->[SHIFTY]\n";
    #  $self->[CANVA]->window->draw_rectangle
    #			($canvas->get_style->base_gc ($canvas->state),
    #			 1, $abs, $ord + 3, $width + 1,
    #			 $height - 5);
    #print "Text = $text_ref->[TEXT]\n";
    $self->[CANVA]
      ->window->clear_area( $abs, $ord + 3, $width + 1, $height - 5 );
}

sub delete_mark_from_text {
    my ($self) = @_;

    @{ $self->[MARKED] } = ();
}

sub move_marked_text_one_line_up {
    my ($self) = @_;

    for my $text_ref ( @{ $self->[MARKED] } ) {
        delete_text_item( $self, $text_ref );
        $text_ref->[ORD] -= 17;
        display_text( $self->[CANVA], $text_ref );
    }
}

sub change_text_item_property {
    my ( $self, $text_ref, $text ) = @_;

    delete_text_item( $self, $text_ref );

    # Revoir le marquage ...
    #my $text2_ref = create_text_and_mark_it (
    # $self, {
    #"text" => $text,
    #	"abs" => $text_ref->[ABS],
    #	"ord" => $text_ref->[ABS],
    #	"font" => $text_ref->[FONT],
    #	"color" => $text_ref->[COLOR],
    #	} );
    $text_ref->[TEXT] = $text;
    display_text( $self->[CANVA], $text_ref );

   #$text_ref->[LAYOUT] = $text2_ref->[LAYOUT];
   # $text2_ref n'a plus de raison d'être puisqu'il s'agit d'une modification...
}

sub position_cursor_in_text_item {
    my ( $self, $text_ref, $position, $abs, $ord ) = @_;
    $self->[SHIFTX] = 0;
    $self->[SHIFTY] = 0;

    remove_cursor($self);
    $self->[CURSOR][ABS]     = $abs;
    $self->[CURSOR][ORD]     = $ord;
    $self->[CURSOR][TEXT_ID] = $text_ref;

    #$self->[CURSOR][COLOR] = 'black';
    display_cursor($self);
    print "apres position du curseur :", $self->[CURSOR][COLOR], "\n";
    print $self->[CURSOR], "\n";
}

sub remove_cursor {
    my ($self) = @_;

    #print "1 Remove du curseur\n";
    return if ( !$self->[CURSOR][TEXT_ID] );

    #print "2 Remove du curseur\n";

    #delete_text_item ( $self, $self->[CURSOR][TEXT_ID] );
    #display_text ( $self->[CANVA], $self->[CURSOR][TEXT_ID] );
    my $cursor_ref = $self->[CURSOR];

    my $gc = $canvas->get_style->base_gc( $canvas->state );

    #  my $colormap = $canvas->get_colormap;
    #  my $color = Gtk2::Gdk::Color->parse('white');
    #  my $alloc_color = $colormap->alloc_color($color, 1, 1);
    #  $gc->set_foreground( $color );

#  $self->[CANVA]->window->draw_line
#			($gc,
#			$cursor_ref->[ABS], $cursor_ref->[ORD] + 3, $cursor_ref->[ABS], $cursor_ref->[ORD] + 20);
    $self->[CURSOR][COLOR] = 'white';
    return if ( !$cursor_ref->[IMAGE] );

    #print "Image $cursor_ref->[IMAGE]\n";
    $self->[CANVA]
      ->window->draw_image( $gc, $cursor_ref->[IMAGE], 0, 0, $cursor_ref->[ABS],
        $cursor_ref->[ORD] + 3,
        -1, -1 );
}

sub display_cursor {
    my ($self) = @_;

    my $cursor_ref = $self->[CURSOR];

    # Avant d'afficher le curseur, on récupère l'image qu'il va masquer
    $cursor_ref->[IMAGE] =
      $self->[CANVA]
      ->window->get_image( $cursor_ref->[ABS], $cursor_ref->[ORD] + 3, 1, 18 );

    #print "1 Display du curseur\n";
    my $gc          = $canvas->get_style->text_gc( $canvas->state );
    my $colormap    = $canvas->get_colormap;
    my $color       = Gtk2::Gdk::Color->parse('black');
    my $alloc_color = $colormap->alloc_color( $color, 1, 1 );
    $gc->set_foreground($color);

    $self->[CANVA]
      ->window->draw_line( $gc, $cursor_ref->[ABS], $cursor_ref->[ORD] + 3,
        $cursor_ref->[ABS], $cursor_ref->[ORD] + 20 );

    #print "2 Display du curseur\n";
    $self->[CURSOR][COLOR] = 'black';
}

sub resize {
    my ( $mw, $event ) = @_;

    # $self->[SHIFTX] = 0;
    # $self->[SHIFTY] = 0;
    print "resize\n";

    $canvas->window->draw_rectangle(
        $canvas->get_style->base_gc( $canvas->state ),
        1, 0, 0,
        $canvas->allocation->width,
        $canvas->allocation->height
    );

    $resize_ref->( $event->height, $event->width );
}

sub move {
    my ( $self, $x, $y ) = @_;

    #$self->[CURSOR][TEXT_ID][ABS] -= $x;
    #$self->[CURSOR][TEXT_ID][ORD] += abs($y);
    remove_cursor($self);
    $self->[CANVA]->window->scroll( $x, $y );

# Impossible de déplacer proprement, par contre la suppression/recréation est propre
#  my $resize_ref = $self->[RESIZE_REF];
#  my $canvas = $self->[CANVA];
#  $canvas->window->draw_rectangle
#			($canvas->get_style->base_gc ($canvas->state),
#			 1, 0, 0, $canvas->allocation->width,
#			 $canvas->allocation->height);
# $resize_ref->($canvas->allocation->height, $canvas->allocation->width);
    return 1;
}

sub redraw_cursor {
    my ($self) = @_;

    # Utiliser get_image et draw_image de Drawable pour repeindre le curseur :
    # Evite l'effacement : vérifier avec des ____

    print "curseur col :", $self->[CURSOR][COLOR], "\n";
    return 1 if !( $self->[CURSOR][COLOR] );

    if ( $self->[CURSOR][COLOR] eq 'white' ) {

        #$self->[CURSOR][COLOR] = 'black';
        display_cursor($self);
    }
    else {

        #$self->[CURSOR][COLOR] = 'white';
        remove_cursor($self);
    }
    return 1;
}

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2009 Sebastien Grommier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
