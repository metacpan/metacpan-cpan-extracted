# $Id: ClipImage.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::FormFactory::ClipImage;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

use Locale::TextDomain qw (video.dvdrip);

(
    top    => __"Top",
    bottom => __"Bottom",
    left   => __"Left",
    right  => __"Right",
);

__"Conformance check:";

sub get_type { "dvdrip_clip_image" }

sub has_additional_attrs { shift->{get_no_clip} ? [] : [qw( left right top bottom )] }

sub get_image_type              { shift->{image_type}                   }
sub get_attr_left		{ shift->{attr_left}			}
sub get_attr_right		{ shift->{attr_right}			}
sub get_attr_top		{ shift->{attr_top}			}
sub get_attr_bottom		{ shift->{attr_bottom}			}
sub get_no_clip			{ shift->{no_clip}			}
sub get_file_error		{ shift->{file_error}			}

sub set_image_type              { shift->{image_type}           = $_[1] }
sub set_attr_left		{ shift->{attr_left}		= $_[1]	}
sub set_attr_right		{ shift->{attr_right}		= $_[1]	}
sub set_attr_top		{ shift->{attr_top}		= $_[1]	}
sub set_attr_bottom		{ shift->{attr_bottom}		= $_[1]	}
sub set_no_clip			{ shift->{no_clip}		= $_[1]	}
sub set_file_error		{ shift->{file_error}		= $_[1]	}

sub get_gtk_pixbuf		{ shift->{gtk_pixbuf}			}
sub get_gtk_v_cursor		{ shift->{gtk_v_cursor}			}
sub get_gtk_h_cursor		{ shift->{gtk_h_cursor}			}
sub get_gtk_n_cursor		{ shift->{gtk_n_cursor}			}
sub get_clip_lines		{ shift->{clip_lines}			}
sub get_line_under_cursor	{ shift->{line_under_cursor}		}
sub get_dragged_line		{ shift->{dragged_line}			}
sub get_clipping_changed        { shift->{clipping_changed}             }

sub set_gtk_pixbuf		{ shift->{gtk_pixbuf}		= $_[1]	}
sub set_gtk_v_cursor		{ shift->{gtk_v_cursor}		= $_[1]	}
sub set_gtk_h_cursor		{ shift->{gtk_h_cursor}		= $_[1]	}
sub set_gtk_n_cursor		{ shift->{gtk_n_cursor}		= $_[1]	}
sub set_clip_lines		{ shift->{clip_lines}		= $_[1]	}
sub set_line_under_cursor	{ shift->{line_under_cursor}	= $_[1]	}
sub set_dragged_line		{ shift->{dragged_line}		= $_[1]	}
sub set_clipping_changed        { shift->{clipping_changed}     = $_[1] }

sub get_gtk_entries             { shift->{gtk_entries}                  }
sub get_gtk_status_label        { shift->{gtk_status_label}             }

sub get_in_entry_update         { shift->{in_entry_update}              }
sub set_gtk_status_label        { shift->{gtk_status_label}     = $_[1] }

sub set_gtk_entries             { shift->{gtk_entries}          = $_[1] }
sub set_in_entry_update         { shift->{in_entry_update}      = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my  ($image_type, $attr_left, $attr_right, $attr_top) =
    @par{'image_type','attr_left','attr_right','attr_top'};
    my  ($attr_bottom, $no_clip) =
    @par{'attr_bottom','no_clip'};

    my $self = $class->SUPER::new(%par);

    $self->set_image_type($image_type);
    $self->set_attr_left($attr_left);
    $self->set_attr_right($attr_right);
    $self->set_attr_top($attr_top);
    $self->set_attr_bottom($attr_bottom);
    $self->set_no_clip($no_clip);

    return $self;
}

sub build_widget {
    my $self = shift;

    my $gtk_drawing_area = Gtk2::DrawingArea->new;
    my $gtk_event_box    = Gtk2::EventBox->new;

    $gtk_event_box->add($gtk_drawing_area);
    $gtk_event_box->modify_bg( "normal", Gtk2::Gdk::Color->parse("#ffffff") );

    $gtk_drawing_area->signal_connect(
        expose_event => sub { $self->draw( $_[1] ) }, );

    $self->set_gtk_n_cursor( Gtk2::Gdk::Cursor->new('GDK_CROSSHAIR') );
    $self->set_gtk_v_cursor(
        Gtk2::Gdk::Cursor->new('GDK_SB_V_DOUBLE_ARROW') );
    $self->set_gtk_h_cursor(
        Gtk2::Gdk::Cursor->new('GDK_SB_H_DOUBLE_ARROW') );

    if ( $self->get_no_clip ) {
        $self->set_gtk_widget($gtk_drawing_area);
        $self->set_gtk_parent_widget($gtk_event_box);
        return;
    }

    $gtk_event_box->set_events(
        [ 'button_press_mask', 'pointer-motion-mask' ] );

    $gtk_event_box->signal_connect(
        button_press_event => sub { $self->button_press( $_[1] ) }, );
    $gtk_event_box->signal_connect(
        button_release_event => sub { $self->button_release() }, );
    $gtk_event_box->signal_connect(
        motion_notify_event => sub { $self->motion_notify( $_[1] ) }, );

    my $gtk_vbox = Gtk2::VBox->new;
    $gtk_vbox->pack_start($gtk_event_box, 0, 1, 0);

    my $gtk_hbox = Gtk2::HBox->new;
    $gtk_vbox->pack_start($gtk_hbox, 0, 1, 0);

    my %fields = (
        top    => __"Top",
        bottom => __"Bottom",
        left   => __"Left",
        right  => __"Right",
    );

    my %gtk_entries;

    foreach my $field ( qw(top bottom left right ) ) {
        my $gtk_label = Gtk2::Label->new($fields{$field});
        $gtk_hbox->pack_start($gtk_label, 0, 1, 0);
        my $gtk_entry = Gtk2::Entry->new();
        $gtk_entry->set_width_chars(5);
        $gtk_hbox->pack_start($gtk_entry, 0, 1, 0);
        $gtk_entries{$field} = $gtk_entry;
        $gtk_entry->signal_connect (
            changed => sub {
                return if $self->get_in_entry_update;
                my $attr_method = "get_attr_".$field;
                $self->set_object_value( $self->$attr_method, $gtk_entry->get_text );
                $self->set_clipping_changed(1);
                1;
            },
        );
    }

    my $gtk_label = Gtk2::Label->new(__"Conformance check:");
    $gtk_hbox->pack_start($gtk_label, 0, 1, 0);

    my $gtk_status_label = Gtk2::Label->new("");
    $gtk_hbox->pack_start($gtk_status_label, 0, 1, 0);

    $self->set_gtk_entries(\%gtk_entries);
    $gtk_vbox->show_all;
    
    $self->set_gtk_status_label($gtk_status_label);
    $self->set_gtk_widget($gtk_drawing_area);
    $self->set_gtk_parent_widget($gtk_vbox);

    1;
}

sub cleanup_xxx {
    my $self = shift;
    
    $self->set_gtk_status_label(undef);
    $self->set_gtk_entries(undef);
    $self->set_gtk_pixbuf(undef);
    $self->set_gtk_v_cursor(undef);
    $self->set_gtk_h_cursor(undef);
    $self->set_gtk_n_cursor(undef);
    
    1;
}

sub object_to_widget {
    my $self = shift;

    my $filename = $self->get_object_value;

    if ( !-f $filename ) {
        $self->set_file_error(1);
        $self->empty_widget;
        return 1;
    }

    $self->set_file_error(0);

    my $gtk_pixbuf = Gtk2::Gdk::Pixbuf->new_from_file($filename);
    $self->set_gtk_pixbuf($gtk_pixbuf);

    my $image_width  = $gtk_pixbuf->get_width;
    my $image_height = $gtk_pixbuf->get_height;

    $self->get_gtk_widget->set_size_request( $image_width + 1,
        $image_height + 1 );

    $self->calc_clip_lines;

    if ( $self->get_dragged_line ) {
        $self->draw_clip_lines;
    }
    else {
        $self->draw;
    }

    1;
}

sub empty_widget {
    my $self = shift;

    my $gtk_drawing_area = $self->get_gtk_widget;
    my $gtk_pixbuf = Gtk2::Gdk::Pixbuf->new( 'rgb', 0, 8, 2048, 2048 );
    $self->set_gtk_pixbuf($gtk_pixbuf);
    $self->draw;

    1;
}

sub draw {
    my $self = shift;
    my ($event) = @_;

    my $gtk_drawing_area = $self->get_gtk_widget;
    my $gtk_pixbuf       = $self->get_gtk_pixbuf;

    my $drawable = $gtk_drawing_area->window;
    my $black_gc = $gtk_drawing_area->style->black_gc;
    my $white_gc = $gtk_drawing_area->style->white_gc;

    my ( $x, $y, $width, $height );

    if ($event) {
        $x      = $event->area->x;
        $y      = $event->area->y;
        $width  = $event->area->width;
        $height = $event->area->height;
    }
    else {
        $x = $y = 0;
        $width  = $gtk_pixbuf->get_width;
        $height = $gtk_pixbuf->get_height;
    }

    if ( $x + $width > $gtk_pixbuf->get_width ) {
        $width = $gtk_pixbuf->get_width - $x;
    }

    if ( $y + $height > $gtk_pixbuf->get_height ) {
        $height = $gtk_pixbuf->get_height - $y;
    }

    $gtk_pixbuf->render_to_drawable( $drawable, $black_gc, $x, $y, $x, $y,
        $width, $height, "none", 0, 0 );

    return if $self->get_file_error;

    $self->draw_clip_lines unless $self->get_no_clip;

    1;
}

sub draw_clip_lines {
    my $self = shift;

    my $gtk_drawing_area = $self->get_gtk_widget;
    my $gtk_pixbuf       = $self->get_gtk_pixbuf;

    my $drawable = $gtk_drawing_area->window;
    my $white_gc = $gtk_drawing_area->style->white_gc;

    my $clip_lines  = $self->get_clip_lines;
    my $gtk_entries = $self->get_gtk_entries;

    my $proxy = $self->get_proxy;

    my $line;
    foreach my $type ( keys %{$clip_lines} ) {
        $line = $clip_lines->{$type};
        $drawable->draw_line( $white_gc, @{$line} );
        my $value = $self->calc_clip_value($type);
        $self->set_in_entry_update(1);
        $gtk_entries->{$type}->set_text($value);
        my $attr_method = "get_attr_".$type;
        $proxy->set_attr($self->$attr_method(), $value, 1);
        $self->set_in_entry_update(0);
    }

    my $title = $proxy->get_object;

    my $text = $title->preview_label(
        type    => $self->get_image_type,
        details => 1,
    );

    $self->get_gtk_status_label->set_markup($text);

    1;
}

sub clear_clip_line {
    my $self = shift;
    my ($type) = @_;

    my $gtk_drawing_area = $self->get_gtk_widget;
    my $gtk_pixbuf       = $self->get_gtk_pixbuf;

    my $drawable = $gtk_drawing_area->window;
    my $black_gc = $gtk_drawing_area->style->black_gc;

    my $clip_lines = $self->get_clip_lines;

    my $line = $clip_lines->{$type};

    my ( $src_x, $src_y, $dst_x, $dst_y, $width, $height );

    if ( $type eq 'top' or $type eq 'bottom' ) {
        $src_x = $dst_x = 0;
        $src_y = $dst_y = $line->[1];
        $width  = $gtk_pixbuf->get_width;
        $height = 1;
        return if $src_y >= $gtk_pixbuf->get_height;
    }
    else {
        $src_x = $dst_x = $line->[0];
        $src_y = $dst_y = 0;
        $width = 1;
        $height = $gtk_pixbuf->get_height;
        return if $src_x >= $gtk_pixbuf->get_width;
    }

    $gtk_pixbuf->render_to_drawable(
        $drawable, $black_gc, $src_x, $src_y, $src_x, $src_y,
        $width,    $height,   "none", 0,      0
    );

    1;
}

sub calc_clip_lines {
    my $self = shift;

    my $top    = $self->get_object_value( $self->get_attr_top );
    my $bottom = $self->get_object_value( $self->get_attr_bottom );
    my $left   = $self->get_object_value( $self->get_attr_left );
    my $right  = $self->get_object_value( $self->get_attr_right );

    my $gtk_pixbuf = $self->get_gtk_pixbuf;
    my $width      = $gtk_pixbuf->get_width;
    my $height     = $gtk_pixbuf->get_height;

    $self->set_clip_lines(
        {   top    => [ 0, $top,              $width - 1, $top ],
            bottom => [ 0, $height - $bottom, $width - 1, $height - $bottom ],
            left  => [ $left,           0, $left,           $height - 1 ],
            right => [ $width - $right, 0, $width - $right, $height - 1 ],
        }
    );

    1;
}

sub motion_notify {
    my $self = shift;
    my ($event) = @_;

    return if $self->get_file_error;

    if ( $self->get_dragged_line ) {
        $self->move_dragged_line($event);
        return 1;
    }

    my $threshold = 5;

    my $x = $event->x;
    my $y = $event->y;

    my $clip_lines = $self->get_clip_lines;

    my $line_under_cursor = "";

    foreach my $type ( "top", "bottom" ) {
        my $line = $clip_lines->{$type};
        if (   $y >= $line->[1] - $threshold
            && $y <= $line->[1] + $threshold ) {
            $self->get_gtk_widget->window->set_cursor(
                $self->get_gtk_v_cursor, );
            $line_under_cursor = $type;
            last;
        }
    }

    foreach my $type ( "left", "right" ) {
        my $line = $clip_lines->{$type};
        if (   $x >= $line->[0] - $threshold
            && $x <= $line->[0] + $threshold ) {
            $self->get_gtk_widget->window->set_cursor(
                $self->get_gtk_h_cursor, );
            $line_under_cursor = $type;
            last;
        }
    }

    if ( not $line_under_cursor
        and $line_under_cursor ne $self->get_line_under_cursor ) {
        $self->get_gtk_widget->window->set_cursor( $self->get_gtk_n_cursor, );
    }

    $self->set_line_under_cursor($line_under_cursor);

    1;
}

sub button_press {
    my $self = shift;
    my ($event) = @_;

    my $line_under_cursor = $self->get_line_under_cursor;
    return if not $line_under_cursor;

    $self->set_dragged_line($line_under_cursor);

    1;
}

sub move_dragged_line {
    my $self = shift;
    my ($event) = @_;

    my $type = $self->get_dragged_line;
    my $x    = $event->x;
    my $y    = $event->y;

    my $gtk_pixbuf = $self->get_gtk_pixbuf;
    my $width      = $gtk_pixbuf->get_width;
    my $height     = $gtk_pixbuf->get_height;

    $x = $width  if $x > $width;
    $y = $height if $y > $height;

    $x = 0 if $x < 0;
    $y = 0 if $y < 0;

    my $clip_lines = $self->get_clip_lines;

    $self->clear_clip_line($type);

    $x = int( $x / 2 ) * 2;
    $y = int( $y / 2 ) * 2;

    if ( $type eq 'top' or $type eq 'bottom' ) {
        $clip_lines->{$type}->[1] = $y;
        $clip_lines->{$type}->[3] = $y;

    }
    elsif ( $type eq 'left' or $type eq 'right' ) {
        $clip_lines->{$type}->[0] = $x;
        $clip_lines->{$type}->[2] = $x;
    }

    $self->draw_clip_lines;

    $self->set_clipping_changed(1);

    1;
}

sub button_release {
    my $self = shift;
    my ($type) = @_;

    $type ||= $self->get_dragged_line;

    my $value = $self->calc_clip_value($type);

    if ( $type eq 'top' ) {
        $self->set_object_value( $self->get_attr_top, $value );
    }
    elsif ( $type eq 'bottom' ) {
        $self->set_object_value( $self->get_attr_bottom, $value );
    }
    elsif ( $type eq 'left' ) {
        $self->set_object_value( $self->get_attr_left, $value );
    }
    elsif ( $type eq 'right' ) {
        $self->set_object_value( $self->get_attr_right, $value );
    }

    $self->set_dragged_line(undef);

    1;
}

sub calc_clip_value {
    my $self = shift;
    my ($type) = @_;

    $type ||= $self->get_dragged_line;

    my $clip_lines = $self->get_clip_lines;

    my $value;
    if ( $type eq 'top' ) {
        $value = $clip_lines->{$type}->[1];
    }
    elsif ( $type eq 'bottom' ) {
        $value = $self->get_gtk_pixbuf->get_height - $clip_lines->{$type}->[1];
    }
    elsif ( $type eq 'left' ) {
        $value = $clip_lines->{$type}->[0];
    }
    elsif ( $type eq 'right' ) {
        $value = $self->get_gtk_pixbuf->get_width - $clip_lines->{$type}->[0];
    }
    
    return $value;
}


1;
