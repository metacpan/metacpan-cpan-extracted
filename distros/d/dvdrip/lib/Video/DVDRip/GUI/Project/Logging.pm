# $Id: Logging.pm 2344 2007-08-09 21:37:41Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Project::Logging;

use base qw( Video::DVDRip::GUI::Base );

use Locale::TextDomain qw (video.dvdrip);

use Carp;
use strict;

sub build_factory {
    my $self = shift;

    my $context = $self->get_context;

    return Gtk2::Ex::FormFactory::VBox->new(
        title       => '[gtk-justify-left]'.__ "Logging",
        object      => "project",
        active_cond => sub {
            $self->project
                && $self->project->created;
        },
        active_depends => "project.created",
        no_frame       => 1,
        $self->get_optimum_screen_size_options("page"),
        content        => [
            Gtk2::Ex::FormFactory::Table->new(
                title  => __ "Log messages",
                expand => 1,
                layout => "
                        +>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
                        ^ Text                       |
                        |                            |
                        +[>>>>>>>+-------+----------]+
                        | Button | Label | Filename  |
                        +----------------+-----------+
		    ",
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
                            my $font
                                = Gtk2::Pango::FontDescription->from_string(
                                "mono 7.2");
                            $gtk_text_view->modify_font($font);
                            $self->logger->set_gtk_text_view($gtk_text_view);
                            my $tag_table = Gtk2::TextTagTable->new;
                            $tag_table->add(
                                $self->create_text_tag(
                                    "date", foreground => "#666666",
                                )
                            );
                            my $buffer = Gtk2::TextBuffer->new($tag_table);
                            $gtk_text_view->set_buffer($buffer);
                            1;
                        },
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Nuke log file",
                        stock        => "gtk-delete",
                        clicked_hook => sub {
                            $self->logger->nuke;
                        },
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => "    " . "<b>"
                            . __("Log filename")
                            . ":</b> ",
                        with_markup => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr       => "project.logfile",
                        properties => { selectable => 1, },
                    ),
                ],
            ),
        ],
    );
}

1;
