# $Id: Title.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Title;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Base;

use strict;
use Carp;

sub master			{ shift->{master}			}
sub title			{ shift->{title}			}
sub cluster_ff			{ shift->{cluster_ff}		        }
sub title_ff			{ shift->{title_ff} 		        }
sub just_added                  { shift->{just_added}                   }

sub set_master			{ shift->{master}		= $_[1]	}
sub set_title			{ shift->{title}		= $_[1]	}
sub set_cluster_ff		{ shift->{cluster_ff}		= $_[1]	}
sub set_title_ff		{ shift->{title_ff}		= $_[1]	}
sub set_just_added              { shift->{just_added}           = $_[1] }

# GUI Stuff ----------------------------------------------------------

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $master, $title, $cluster_ff, $just_added )
        = @par{ 'master', 'title', 'cluster_ff', 'just_added' };

    my $self = $class->SUPER::new(@_);

    $self->set_master($master);
    $self->set_title($title);
    $self->set_cluster_ff($cluster_ff);
    $self->set_just_added($just_added);

    $cluster_ff->get_form_factory->get_context->set_object(
        cluster_title_edited => $title, );

    $cluster_ff->get_form_factory->get_context->set_object(
        cluster_title_gui => $self, );

    return $self;
}

sub open_window {
    my $self = shift;

    my $title_ff = Gtk2::Ex::FormFactory->new(
        parent_ff => $self->cluster_ff,
        context   => $self->cluster_ff->get_context,
        sync      => 0,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title => __ "dvd::rip - Edit cluster project",
                closed_hook => sub {
                    $self->close_window;
                    1;
                },
                properties => { modal => 1, },
                content => [ $self->build_title_form, $self->build_buttons ],
            ),
        ],
    );

    $title_ff->build;
    $title_ff->update;
    $title_ff->show;

    $self->set_title_ff($title_ff);

    1;
}

sub close_window {
    my $self = shift;

    my $cluster_gui
        = $self->cluster_ff->get_form_factory->get_context->get_object(
        "cluster_gui");

    my $title_ff = $self->title_ff;
    $title_ff->close if $title_ff;
    $self->set_title_ff(undef);
    $self->set_title(undef);

    $self->cluster_ff->get_form_factory->get_context->set_object(
        cluster_title_gui => undef, );
    $self->cluster_ff->get_form_factory->get_context->set_object(
        cluster_title_edited => undef, );

    1;
}

sub build_title_form {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Form->new(
        title   => __ "Edit cluster project properties",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::Label->new(
                attr  => "cluster_title_edited.info",
                label => __ "Project",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_title_edited.frames_per_chunk",
                label => __ "Number of frames per chunk",
                tip   => __
                    "The smaller the chunks the higher the parallelism, "
                    . "but overall bitrate distribution may suffer if set "
                    . "too low",
                rules => "positive-integer",
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr  => "cluster_title_edited.with_cleanup",
                label => __ "Cleanup temporary files after merging?",
                true_label => __"Yes",
                false_label  => __"No",
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr  => "cluster_title_edited.with_vob_remove",
                label => __ "Cleanup original VOB files when finished?",
                true_label => __"Yes",
                false_label  => __"No",
            ),
        ],
    );
}

sub build_buttons {
    my $self = shift;

    return Gtk2::Ex::FormFactory::DialogButtons->new(
        clicked_hook_after => sub {
            my ($button) = @_;
            if ( $button eq 'ok' ) {
                $self->title->project->save;
            }
            else {
                $self->master->remove_project(
                    project => $self->title->project )
                    if $self->just_added;
            }
            $self->close_window;
            1;
        },
    );
}

1;
