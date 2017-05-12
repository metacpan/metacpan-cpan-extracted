# $Id: Depend.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Depend;
use Locale::TextDomain qw (video.dvdrip);

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $depend_ff;

sub open_window {
    my $self = shift;

    return if $depend_ff;

    $self->build;

    1;
}

sub build {
    my $self = shift;

    my $context = $self->get_context;

    $depend_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        parent_ff => $self->get_form_factory,
        sync      => 0,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __ "dvd::rip - Dependency check",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        default_width  => 640,
                        default_height => 480,
                    );
                    1;
                },
                closed_hook => sub {
                    $depend_ff->close if $depend_ff;
                    $depend_ff = undef;
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::Table->new(
                        title  => __ "Required tools",
                        expand => 1,
                        layout => "
                                +>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
                                ^ Dependency list                 |
                                |                                 |
                                +---------------------------------+
                                | Notes                           |
                                +-----------------------+--------]+
                                |                       | Buttons |
                                +-----------------------+---------+
			    ",
                        content => [
                            $self->build_depend_list,
                            $self->build_depend_notes,
                            Gtk2::Ex::FormFactory::HBox->new(
                                content => [
                                    Gtk2::Ex::FormFactory::Button->new(
                                        label        => __ " Text version ",
                                        stock        => "gtk-justify-left",
                                        clicked_hook => sub {
                                            $self->show_text_version;
                                        },
                                        tooltip => __
                                            "Text version, suitable for bug reports"
                                    ),
                                    Gtk2::Ex::FormFactory::Button->new(
                                        label        => __ " Ok ",
                                        stock        => "gtk-ok",
                                        clicked_hook => sub {
                                            $depend_ff->close;
                                            $depend_ff = undef;
                                        },
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),

        ],
    );

    $depend_ff->build;
    $depend_ff->update;
    $depend_ff->show;

    1;
}

sub build_depend_list {
    my $self = shift;

    Gtk2::SimpleList->add_column_type(
        'depend_tool_text',
        type     => "Glib::Scalar",
        renderer => "Gtk2::CellRendererText",
        attr     => sub {
            my ( $treecol, $cell, $model, $iter, $col_num ) = @_;
            my $info = $model->get( $iter, $col_num );
            my $ok   = $model->get( $iter, 8 );
            $cell->set( text       => $info );
            $cell->set( foreground => $ok ? "#000000" : "#ff0000" );
            $cell->set( weight     => $col_num == 0 ? 700 : 500 );
            1;
        },
    );

    return Gtk2::Ex::FormFactory::List->new(
        attr       => "depend.tools",
        expand     => 1,
        scrollbars => [ "never", "automatic" ],
        columns    => [
            __ "Name",
            __ "Comment",
            __ "Mandatory",
            __ "Suggested",
            __ "Minimum",
            __ "Maximum",
            __ "Installed",
            __ "Ok",
            "color_control"
        ],
        types => [ ("depend_tool_text") x 8, "int" ],
        selection_mode => "none",
        customize_hook => sub {
            my ($gtk_simple_list) = @_;
            ( $gtk_simple_list->get_columns )[8]->set( visible => 0 );
            1;
        },
    );
}

sub build_depend_notes {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Label->new(
        label => __(
            "- Mandatory tools must be present with the minimum version listed.\n"
                . "- Non mandatory tools may be missing or too old - features are disabled then.\n"
                . "- Suggested numbers are the versions the author works with, so they are well tested."
            )

    );
}

sub show_text_version {
    my $self = shift;

    my $message = $self->depend_object->installed_tools_as_text;

    $self->long_message_window(
        title   => __ "Installed tools",
        message => $message,
        fixed   => 1,
    );

    1;
}

1;

