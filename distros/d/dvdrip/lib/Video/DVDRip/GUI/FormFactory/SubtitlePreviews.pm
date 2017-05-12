package Video::DVDRip::GUI::FormFactory::SubtitlePreviews;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

use Video::DVDRip::SrtxFile;

use FileHandle;

sub get_type                    { "dvdrip_subtitle_preview"              }

sub has_additional_attrs        { [ "image_cnt", "start_time" ]          }

sub get_attr_image_cnt          { shift->{attr_image_cnt}                }
sub get_attr_start_time         { shift->{attr_start_time}               }
sub get_gtk_hbox                { shift->{gtk_hbox}                      }
sub get_last_valid_start_time   { shift->{last_valid_start_time}         }

sub set_attr_image_cnt          { shift->{attr_image_cnt}        = $_[1] }
sub set_attr_start_time         { shift->{attr_start_time}       = $_[1] }
sub set_gtk_hbox                { shift->{gtk_hbox}              = $_[1] }
sub set_last_valid_start_time   { shift->{last_valid_start_time} = $_[1] }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $attr_image_cnt, $attr_start_time )
        = @par{ 'attr_image_cnt', 'attr_start_time' };

    my $self = $class->SUPER::new(@_);

    $self->set_attr_image_cnt($attr_image_cnt);
    $self->set_attr_start_time($attr_start_time);

    return $self;
}

sub cleanup {
    my $self = shift;

    $self->SUPER::cleanup(@_);

    $self->set_gtk_hbox(undef);

    1;
}

sub build_widget {
    my $self = shift;

    $self->set_gtk_widget( Gtk2::VBox->new );

    1;
}

sub object_to_widget {
    my $self = shift;

    $self->empty_widget;

    my $sub_dir    = $self->get_object_value;
    my $image_cnt  = $self->get_proxy->get_attr( $self->get_attr_image_cnt );
    my $start_time = $self->get_proxy->get_attr( $self->get_attr_start_time );

    my $srtx = Video::DVDRip::SrtxFile->new;

    return if $image_cnt == 0;
    return if not $srtx->set_filename_from_dir($sub_dir);

    if ( $start_time =~ /:/ ) {
        if ( $start_time =~ /^(\d\d):(\d\d):(\d\d)/ ) {
            $start_time = $3 + $2 * 60 + $1 * 3600;
        }
        else {
            $start_time = $self->get_last_valid_start_time;
        }
    }
    else {
        $start_time = int(
            $start_time / $self->get_proxy->get_object->title->frame_rate );
    }

    $self->set_last_valid_start_time($start_time);

    $srtx->open;

    my $cnt = 0;
    while ( my $entry = $srtx->read_entry ) {
        next if $entry->get_time_sec < $start_time;
        next if not $entry->get_image_file;

        $self->add_image($entry);
        ++$cnt;

        last if $cnt == $image_cnt;
    }

    $srtx->close;

    1;
}

sub empty_widget {
    my $self = shift;

    my $gtk_vbox = $self->get_gtk_widget;
    my @children = $gtk_vbox->get_children;
    $gtk_vbox->remove($_) for @children;

    my $gtk_scrolled_window = Gtk2::ScrolledWindow->new;
    $gtk_scrolled_window->set(
        hscrollbar_policy => "automatic",
        vscrollbar_policy => "automatic",
    );

    my $gtk_event_box = Gtk2::EventBox->new;
    $gtk_event_box->modify_bg( "normal", Gtk2::Gdk::Color->parse("#ffffff") );

    my $gtk_hbox = Gtk2::HBox->new;

    $gtk_event_box->add($gtk_hbox);
    $gtk_scrolled_window->add_with_viewport($gtk_event_box);

    $self->get_gtk_widget->pack_start( $gtk_scrolled_window, 1, 1, 0 );
    $self->set_gtk_hbox($gtk_hbox);

    $gtk_scrolled_window->show_all;

    1;
}

sub add_image {
    my $self = shift;
    my ($entry) = @_;

    my $nr   = $entry->get_nr;
    my $time = $entry->get_time;

    $nr = "[$nr] - " if defined $nr;

    my $gtk_hbox  = $self->get_gtk_hbox;
    my $gtk_image = Gtk2::Image->new_from_file( $entry->get_image_file );
    my $gtk_vbox  = Gtk2::VBox->new;
    $gtk_vbox->set( border_width => 5 );
    $gtk_vbox->pack_start( $gtk_image, 0, 1, 0 );
    my $gtk_frame = Gtk2::Frame->new("$nr$time");
    $gtk_frame->set( border_width => 5 );
    $gtk_frame->set_label_align( 0.5, 0.5 );
    $gtk_frame->add($gtk_vbox);
    $gtk_frame->show_all;
    $gtk_hbox->pack_start( $gtk_frame, 0, 1, 0 );

    1;
}

1;
