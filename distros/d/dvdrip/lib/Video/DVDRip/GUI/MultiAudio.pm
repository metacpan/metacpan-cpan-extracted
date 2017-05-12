# $Id: MultiAudio.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::MultiAudio;
use Locale::TextDomain qw (video.dvdrip);

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $multi_audio_ff;

sub open_window {
    my $self = shift;

    return if $multi_audio_ff;

    $self->build;

    1;
}

sub build {
    my $self = shift;

    my $context = $self->get_context;

    $context->set_object( multi_audio => $self );

    $multi_audio_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        parent_ff => $self->get_form_factory,
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title       => __ "dvd::rip - Manage multiple audio tracks",
                closed_hook => sub {
                    $multi_audio_ff->close if $multi_audio_ff;
                    $multi_audio_ff = undef;
                    $context->set_object( multi_audio => undef );
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::VBox->new(
                        expand  => 1,
                        content => [
                            $self->build_multi_audio_table,
                            Gtk2::Ex::FormFactory::DialogButtons->new(
                                clicked_hook_after => sub {
                                    $multi_audio_ff->close if $multi_audio_ff;
                                    $multi_audio_ff = undef;
                                    $context->set_object(
                                        multi_audio => undef );
                                },
                            ),
                        ],
                    ),
                ],
            ),

        ],
    );

    $multi_audio_ff->build;
    $multi_audio_ff->update;
    $multi_audio_ff->show;

    1;
}

sub build_multi_audio_table {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Table->new(
        title  => __ "Manage multiple audio tracks",
        expand => 1,
        layout => "
                +[--------------+-----%-----+
                | Label         |     Label |
                +---------------+-----------+
                | Matrix                    |
                +---------------------------+
	    ",
        content => [
            Gtk2::Ex::FormFactory::Label->new(
                label       => "<b>" . __("Source tracks") . "</b>",
                with_markup => 1,
            ),
            Gtk2::Ex::FormFactory::Label->new(
                label       => "<b>" . __("Target tracks") . "</b>",
                with_markup => 1,
            ),
            Gtk2::Ex::FormFactory::CheckButtonGroup->new(
                attr               => "multi_audio.matrix",
                attr_max_columns   => "multi_audio.max_columns",
                attr_row_labels    => "multi_audio.row_labels",
                attr_column_labels => "multi_audio.column_labels",
                homogeneous        => 0,
                changed_hook       => sub { $self->matrix_changed( $_[1] ) },
            )
        ],
    );
}

sub max_columns {
    my $self = shift;
    return 1 + @{ $self->selected_title->audio_tracks };
}

sub row_labels {
    my $self = shift;
    my @labels;
    my $i = 1;
    push @labels, "[" . $i++ . "] " . $_->info . "       "
        for @{ $self->selected_title->audio_tracks };
    return \@labels;
}

sub column_labels {
    my $self = shift;
    my @labels;
    push @labels, "[$_]            "
        for 1 .. @{ $self->selected_title->audio_tracks };
    push @labels, "[" . __("Discard") . "]";
    return \@labels;
}

sub matrix {
    my $self = shift;

    my %matrix;
    my $audio_tracks = $self->selected_title->audio_tracks;

    my $i = 0;
    foreach my $track ( @{$audio_tracks} ) {
        $matrix{ "$i:" . $track->tc_target_track } = 1;
        ++$i;
    }

    return \%matrix;
}

sub set_matrix {undef}

sub matrix_list {
    my $self = shift;

    my $track_cnt = @{ $self->selected_title->audio_tracks };

    my @matrix;
    for ( my $target = 0; $target < $track_cnt; ++$target ) {
        for ( my $source = 0; $source < $track_cnt; ++$source ) {
            push @matrix, [ "$source:$target", "" ],;
        }
    }

    for ( my $source = 0; $source < $track_cnt; ++$source ) {
        push @matrix, [ "$source:-1", "" ],;
    }

    return \@matrix;
}

sub matrix_changed {
    my $self = shift;
    my ($check_button_group) = @_;

    my $title        = $self->selected_title;
    my $audio_tracks = $title->audio_tracks;
    my $value        = $check_button_group->get_last_toggled_value;

    my ( $source, $target ) = split( ":", $value );

    if ( !$check_button_group->get_gtk_check_buttons->{$value}->get_active
        || $target == -1 ) {

        #-- checked button clicked again or track disabled
        $audio_tracks->[$source]->set_tc_target_track(-1);
        $check_button_group->update_selection;

    }
    else {

        #-- check if any track is assigned to this target track already
        foreach my $track ( @{$audio_tracks} ) {
            if ( $track->tc_target_track == $target ) {
                $track->set_tc_target_track(-1);
                last;
            }
        }

        #-- now assign this target track
        $audio_tracks->[$source]->set_tc_target_track($target);
    }

    #-- update selection
    $check_button_group->update_selection;

    #-- recalculate video bitrate
    $title->calc_video_bitrate;

    1;
}

1;
