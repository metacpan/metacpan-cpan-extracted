# $Id: Preview.pm 2305 2007-04-13 11:25:03Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Preview;
use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

@Video::DVDRip::GUI::Preview::ISA = qw ( Video::DVDRip::GUI::Base );

use Video::DVDRip::TranscodeRC;
use Gtk2::Helper;

sub transcode_remote		{ shift->{transcode_remote}		}
sub transcode_pipe		{ shift->{transcode_pipe}		}

sub set_transcode_remote	{ shift->{transcode_remote}	= $_[1]	}
sub set_transcode_pipe		{ shift->{transcode_pipe}	= $_[1]	}

sub stop_in_progress		{ shift->{stop_in_progress}		}
sub set_stop_in_progress	{ shift->{stop_in_progress}	= $_[1]	}

sub eof_cb			{ shift->{eof_cb}			}
sub closed_cb			{ shift->{closed_cb}			}
sub selection_cb		{ shift->{selection_cb}			}

sub set_eof_cb			{ shift->{eof_cb}		= $_[1]	}
sub set_closed_cb		{ shift->{closed_cb}		= $_[1]	}
sub set_selection_cb		{ shift->{selection_cb}		= $_[1]	}

sub gdk_input			{ shift->{gdk_input}			}
sub set_gdk_input		{ shift->{gdk_input}		= $_[1]	}

sub settings_applied            { shift->{settings_applied}             }
sub set_settings_applied        { shift->{settings_applied}     = $_[1] }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $closed_cb, $selection_cb, $eof_cb )
        = @par{ 'closed_cb', 'selection_cb', 'eof_cb' };

    my $self = $class->SUPER::new(@_);

    $self->set_closed_cb($closed_cb);
    $self->set_selection_cb($selection_cb);
    $self->set_eof_cb($eof_cb);

    return $self;
}

sub closed { not defined shift->transcode_pipe }

sub open {
    my $self = shift;

    return if $self->transcode_pipe;

    my $socket_file
        = "/tmp/tc.$$." . time . ( int( rand(100000) ) ) . ".sock";

    # start transcode

    my $title = $self->selected_title;

    my ( $orig_start, $orig_end )
        = ( $title->tc_start_frame, $title->tc_end_frame, );

    $title->set_tc_start_frame( $title->tc_preview_start_frame );
    $title->set_tc_end_frame( $title->tc_preview_end_frame );

    my $command = $title->get_transcode_command( pass => 1 );

    $title->set_tc_start_frame($orig_start);
    $title->set_tc_end_frame($orig_end);

    $command =~ s/&& echo EXECFLOW_OK//;
    $command =~ s/-y\s+[^\s]+//;           # remove target codecs
    $command =~ s/-o\s+[^\s]+//;           # remove output file

    $command =~ s/(-J\s+extsub[^\s]+)//g;
    my $subtitle = $1;

    $command =~ s/-J\s+[^\s]+//g;          # remove all filters
    $command =~ s/--psu_mode//g;           # disable PSU core
    $command =~ s/--no_split//g;           # disable PSU core

    $command .= " -J pv=cache=" . $title->tc_preview_buffer_frames;
    $command .= " --socket $socket_file -u 1";

    $command .= " $subtitle" if $subtitle;

    require Video::DVDRip::GUI::Pipe;

    my $transcode_pipe;
    $transcode_pipe = Video::DVDRip::GUI::Pipe->new(
        command     => $command,
        need_output => 0,
        cb_finished => sub {
            my $eof_cb = $self->eof_cb;
            &$eof_cb($transcode_pipe->output =~ /EXECFLOW_OK/) if $eof_cb;
            $self->stop if not $self->stop_in_progress;
            $transcode_pipe = undef;
            1;
        },
    );

    $transcode_pipe->open;

    $self->set_transcode_pipe($transcode_pipe);

    my $start_time = time();

    my $timer;
    $timer = Glib::Timeout->add(
        200,
        sub {
            if ( not -e $socket_file ) {
                if ( time - $start_time >= 2 ) {
                    $self->stop;
                    Glib::Source->remove($timer) if $timer;
                    croak "msg:Couldn't start transcode.";
                }
                return 1;
            }

            Glib::Source->remove($timer);

            # start remote control
            my $transcode_remote = Video::DVDRip::TranscodeRC->new(
                socket_file => $socket_file,
                error_cb    => sub {
                    my ($line) = @_;
                    $self->long_message_window( message => __
                            "Error executing a transcode socket command:\n\n"
                            . $line );
                    1;
                },
                selection_cb => $self->selection_cb,
            );

            $transcode_remote->connect;

            my $socket_fileno = $transcode_remote->socket->fileno;

            my $gdk_input = Gtk2::Helper->add_watch(
                $socket_fileno,
                'in',
                sub {
                    my $rc = $transcode_remote->receive;
                    if ( defined $rc ) {
                        $self->process_transcode_remote_output( line => $rc, )
                            if $rc ne '';
                    }
                    1;
                }
            );

            $self->set_gdk_input($gdk_input);

            $self->set_transcode_remote($transcode_remote);

            $self->apply_filter_settings;

            return 0;
        }
    );

    1;
}

sub apply_filter_settings {
    my $self = shift;

    my $title = $self->selected_title;

    my $config_strings
        = $title->tc_filter_settings->get_filter_config_strings(
        with_suffixes => 1 );

    my $max_frames_needed = $title->tc_filter_settings->get_max_frames_needed,

    my $transcode_remote = $self->transcode_remote;

    foreach my $config ( @{$config_strings} ) {
        $transcode_remote->config_filter(
            filter  => $config->{filter},
            options => $config->{options},
        );
        if ( $config->{enabled} ) {
            $transcode_remote->enable_filter( filter => $config->{filter} );
        }
        else {
            $transcode_remote->disable_filter( filter => $config->{filter} );
        }
    }

    $transcode_remote->preview(
        command => "draw",
        options => $max_frames_needed,
    ) if $transcode_remote->paused;

    $self->set_settings_applied(1);

    1;
}

sub stop {
    my $self = shift;

    $self->set_stop_in_progress(1);

    if ( $self->transcode_remote and $self->transcode_remote->paused ) {
        $self->pause;
        $self->transcode_remote->quit;
        Glib::Timeout->add(
            500,
            sub {
                $self->transcode_remote->disconnect;
                $self->transcode_pipe->cancel;
                Gtk2::Helper->remove_watch( $self->gdk_input );
                $self->close;
                return 0;

            }
            )
            if $self->transcode_pipe;
    }
    else {
        $self->transcode_remote->disconnect
            if $self->transcode_remote;
        $self->transcode_pipe->cancel
            if $self->transcode_pipe;
        Gtk2::Helper->remove_watch( $self->gdk_input )
            if $self->gdk_input;
        $self->close;
    }

    1;
}

sub close {
    my $self = shift;

    $self->set_transcode_pipe(undef);
    $self->set_transcode_remote(undef);

    $self->set_stop_in_progress(0);

    1;
}

sub pause {
    my $self = shift;

    $self->set_settings_applied(0);

    $self->transcode_remote->preview( command => "pause", );

    return $self->transcode_remote->paused;
}

sub paused {
    my $self = shift;
    return 0 if ! $self->transcode_remote;
    return $self->transcode_remote->paused;
}

sub process_transcode_remote_output {
    my $self   = shift;
    my %par    = @_;
    my ($line) = @par{'line'};

    if ( $line =~ /preview window close/ ) {
        my $closed_cb = $self->closed_cb;
        &$closed_cb() if $closed_cb;
        if ( $self->transcode_pipe ) {
            $self->transcode_pipe->cancel;
            Gtk2::Helper->remove_watch( $self->gdk_input );
            $self->close;
        }
    }

    1;
}

1;

