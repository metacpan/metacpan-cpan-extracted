# $Id: Base.pm 2341 2007-08-09 21:35:05Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Base;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use strict;
use Carp;
use Data::Dumper;
use Cwd;

sub get_context			{ shift->{context}			}
sub set_context			{ shift->{context}		= $_[1]	}

sub get_form_factory		{ shift->{form_factory}			}
sub set_form_factory		{ shift->{form_factory}		= $_[1]	}

sub get_context_object		{ $_[0]->{context}->get_object($_[1]) 	}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $form_factory, $context ) = @par{ 'form_factory', 'context' };

    $context ||= $form_factory->get_context if $form_factory;

    my $self = bless {
        form_factory => $form_factory,
        context      => $context,
    }, $class;

    return $self;
}

sub create_text_tag {
    my $self = shift;
    my $name = shift;
    my %par  = @_;

    my $cb = delete $par{cb};

    my $tag = Gtk2::TextTag->new($name);
    $tag->set(%par);

    $tag->signal_connect( "event", $cb ) if $cb;

    return $tag;
}

sub project {
    my $self = shift;
    return $self->get_context->get_object("project");
}

sub selected_title {
    my $self = shift;
    return $self->get_context->get_object("title");
}

sub progress {
    my $self = shift;
    return $self->get_context->get_object("progress");
}

sub progress_is_active {
    return $_[0]->progress->is_active;
}

sub show_file_dialog {
    my $self = shift;
    my %par  = @_;
    my ( $type, $dir, $filename, $cb, $title, $confirm )
        = @par{ 'type', 'dir', 'filename', 'cb', 'title', 'confirm' };

    $type ||= "open";

    my $cwd = cwd;
    chdir($dir);

    my $form_factory = $self->get_form_factory;
    my $gtk_window   =
          $form_factory
        ? $form_factory->get_form_factory_gtk_window
        : undef;

    # Create a new file selection widget
    my $dialog = Gtk2::FileChooserDialog->new(
        $title,
        $gtk_window,
        "save",
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok'
    );

    $dialog->set_current_name($filename);

    my $response = $dialog->run;

    my $filename = $dialog->get_filename;

    $dialog->destroy;
    chdir($cwd);

    if ( $response eq 'ok' ) {
        if ( -f $filename and $confirm ) {
            $self->confirm_window(
                message => __x(
                    "Overwrite existing file '{filename}'?",
                    filename => $filename
                ),
                yes_callback => sub { &$cb($filename) },
            );
        }
        else {
            &$cb($filename);
        }
    }

    1;
}

sub message_window {
    my $self = shift;
    my %par = @_;
    my  ($message, $ff, $modal, $type) =
    @par{'message','ff','modal','type'};

    $type ||= "info";

    my $dialog = Gtk2::MessageDialog->new_with_markup( undef,
        ["destroy-with-parent"], $type, "none", $message );

    $dialog->set_position("center-on-parent");
    $dialog->set_modal($modal);
    $dialog->add_buttons( "gtk-ok", "ok" );

    $dialog->signal_connect(
        "response",
        sub {
            my ( $widget, $answer ) = @_;
            $widget->destroy;
            1;
        }
    );

    $dialog->show;

    1;

}

sub error_window {
    my $self      = shift;
    my %par       = @_;
    my ($message) = @par{'message'};

    if ( $message =~ s/^msg:// ) {
        $message =~ s/\s+at\s+.*?line\s+\d+//;
    }

    if ( length($message) > 500 ) {
        return $self->long_message_window(
            message => $message,
            title   => __ "Error message"
        );
    }

    my $dialog = Gtk2::MessageDialog->new( undef,
        [ "modal", "destroy-with-parent" ],
        "error", "none", $message );

    $dialog->set_position("center-on-parent");
    $dialog->add_buttons( "gtk-ok", "ok" );

    $dialog->signal_connect(
        "response",
        sub {
            my ( $widget, $answer ) = @_;
            $widget->destroy;
            1;
        }
    );

    $dialog->show;

    1;

}

sub long_message_window {
    my $self = shift;
    my %par  = @_;
    my ( $message, $title, $fixed ) = @par{ 'message', 'title', 'fixed' };

    my $frame_title = $title;

    $title = "dvd::rip - " . $title if $title;
    $title ||= __ "dvd::rip - Message";

    my $ff;
    $ff = Gtk2::Ex::FormFactory->new(
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => $title,
                closed_hook    => sub { $ff->close },
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        default_width  => 600,
                        default_height => 440,
                    );
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::VBox->new(
                        expand  => 1,
                        content => [
                            Gtk2::Ex::FormFactory::VBox->new(
                                title   => $frame_title,
                                expand  => 1,
                                content => [
                                    Gtk2::Ex::FormFactory::TextView->new(
                                        scrollbars => [ "never", "always" ],
                                        expand     => 1,
                                        properties => {
                                            editable       => 0,
                                            cursor_visible => 0,
                                            wrap_mode      => "word",
                                        },
                                        customize_hook => sub {
                                            my ($gtk_text_view) = @_;
                                            if ($fixed) {
                                                my $font
                                                    = Gtk2::Pango::FontDescription
                                                    ->from_string("mono");
                                                $gtk_text_view->modify_font(
                                                    $font);
                                            }
                                            $gtk_text_view->get_buffer
                                                ->set_text($message);
                                            1;
                                        },
                                    ),
                                ],
                            ),
                            Gtk2::Ex::FormFactory::DialogButtons->new,
                        ],
                    ),
                ],
            ),
        ],
    );

    $ff->build;
    $ff->update;
    $ff->show;

    1;
}

sub confirm_window {
    my $self = shift;
    my %par  = @_;
    my ( $message, $yes_callback, $no_callback, $position, $with_cancel )
        = @par{
        'message', 'yes_callback', 'no_callback', 'position',
        'with_cancel'
        };

    $self->get_form_factory->open_confirm_window(
        message      => $message,
        yes_callback => $yes_callback,
        no_callback  => $no_callback,
        position     => $position,
        with_cancel  => $with_cancel,
    );

    1;
}

sub new_job_executor {
    my $self = shift;

    return Video::DVDRip::GUI::ExecuteJobs->new(
        form_factory => $self->get_form_factory,
        @_,
    );
}

sub get_optimum_screen_size_options {
    my $self = shift;
    my ($type) = @_;

    return () if not $self->config("small_screen");

    if ( $type eq 'page' ) {
        return (
            scrollbars     => [ "automatic", "automatic" ],
            properties     => { border_width => 8 },
        );
    }
    elsif ( $type eq 'notebook' ) {
        return (
            properties     => { tab_pos => "left" },
        );
    }
}

1;
