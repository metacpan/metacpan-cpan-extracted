# $Id: ZoomCalculator.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::ZoomCalculator;
use Locale::TextDomain qw (video.dvdrip);

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $zoom_calc_ff;

sub fast_resize_align		{ shift->{fast_resize_align}		}
sub set_fast_resize_align	{ shift->{fast_resize_align}	= $_[1]	}

sub fast_resize_align_list {
    [
        [ 0, => __"No fast resizing" ],
	[ 8, =>  8 ],
	[ 16 => 16 ],
	[ 32 => 32 ],
    ]
}

sub result_frame_align		{ shift->{result_frame_align}		}
sub set_result_frame_align	{ shift->{result_frame_align}	= $_[1]	}

sub result_frame_align_presets {
    [ 16 ]
}

sub achieve_result_align	{ shift->{achieve_result_align}		}
sub set_achieve_result_align	{ shift->{achieve_result_align}	= $_[1]	}

sub achieve_result_align_list {
    [
        [ 'clip2' => __"Using clip2" ],
	[ 'zoom'  => __"Using zoom"  ],
    ]
}

sub auto_clip			{ shift->{auto_clip}			}
sub set_auto_clip		{ shift->{auto_clip}		= $_[1]	}

sub auto_clip_list {
    [
	[ "clip1" => __"Yes - use clip1" ],
	[ "clip2" => __"Yes - use clip2" ],
	[ "no"	  => __"No - take existent clip1" ],
    ]
}

sub selected_row		{ shift->{selected_row}			}
sub get_calc_lref		{ shift->{calc_lref}			}

sub set_selected_row		{ shift->{selected_row}		= $_[1]	}
sub set_calc_lref		{ shift->{calc_lref}		= $_[1]	}

sub open_window {
    my $self = shift;

    return if $zoom_calc_ff;

    $self->set_fast_resize_align(8);
    $self->set_result_frame_align(16);
    $self->set_achieve_result_align("clip2");
    $self->set_auto_clip("clip2");
    $self->set_selected_row( [0] );

    $self->build;

    $self->get_context->set_object( zoom_calc => $self );

    1;
}

sub build {
    my $self = shift;

    my $context = $self->get_context;

    $zoom_calc_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        parent_ff => $self->get_form_factory,
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __ "dvd::rip - Zoom Calculator",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set( default_height => 550, );
                    1;
                },
                closed_hook => sub {
                    $zoom_calc_ff->close if $zoom_calc_ff;
                    $zoom_calc_ff = undef;
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::Table->new(
                        expand => 1,
                        layout => "
                                +>---------------+>--------------+
                                | Parameters     | Bitrate Calc  |
                                +----------------+---------------+
                                ^ Zoom Calc Table                |
                                |                                |
                                +--------------------------------+
                                | Some Space                     |
                                +-------------------------------]+
                                |                        Buttons |
                                +--------------------------------+
			    ",
                        content => [
                            $self->build_zoom_calc_params,
                            $self->build_video_bitrate_calc,
                            $self->build_zoom_calc_table,
                            Gtk2::Ex::FormFactory::Label->new( label => "", ),
                            Gtk2::Ex::FormFactory::HBox->new(
                                content => [
                                    Gtk2::Ex::FormFactory::Button->new(
                                        label => __
                                            "Apply Clip & Zoom settings",
                                        stock        => "gtk-apply",
                                        clicked_hook => sub {
                                            $self->apply_values;
                                            1;
                                        },
                                    ),
                                    Gtk2::Ex::FormFactory::Button->new(
                                        stock        => "gtk-close",
                                        clicked_hook => sub {
                                            $zoom_calc_ff->close;
                                            $zoom_calc_ff = undef;
                                        },
                                    ),
                                ],
                                properties => { homogeneous => 1, },
                            ),
                        ],
                    ),
                ],
            ),

        ],
    );

    $zoom_calc_ff->build;
    $zoom_calc_ff->update;
    $zoom_calc_ff->show;

    1;
}

sub build_zoom_calc_params {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Form->new(
        title   => __ "Parameters",
        content => [
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "zoom_calc.fast_resize_align",
                label => __ "Fast resize align",
            ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr  => "zoom_calc.result_frame_align",
                label => __ "Result frame align",
            ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "zoom_calc.achieve_result_align",
                label => __ "Achieve result align",
            ),
            Gtk2::Ex::FormFactory::Popup->new(
                attr  => "zoom_calc.auto_clip",
                label => __ "Auto clipping",
            ),
        ],
    );
}

sub build_video_bitrate_calc {
    my $self = shift;

    my $video_bitrate_calc = $self->get_context->get_object("transcode")
        ->build_video_bitrate_factory;

    my $calc_plus_result = Gtk2::Ex::FormFactory::VBox->new(
        title   => $video_bitrate_calc->get_title,
        content => [
            $video_bitrate_calc,
            Gtk2::Ex::FormFactory::HBox->new(
                content => [
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "V-Rate" . ": ",
                        attr  => "title.tc_video_bitrate",
                        bold  => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => "   " . __ "BPP" . ": ",
                        attr  => "title.tc_video_bpp",
                        bold  => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => "   " . __ "Total size" . ": ",
                        attr  => "title.storage_total_size",
                        bold  => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new( label => __ "MB", ),
                ],
            ),
        ],
    );

    $video_bitrate_calc->set_title("");

    return $calc_plus_result;
}

sub build_zoom_calc_table {
    my $self = shift;

    Gtk2::SimpleList->add_column_type(
        'zoom_calc_text',
        type     => "Glib::Scalar",
        renderer => "Gtk2::CellRendererText",
        attr     => sub {
            my ( $treecol, $cell, $model, $iter, $col_num ) = @_;
            my $info       = $model->get( $iter, $col_num );
            my $ar_perfect = $model->get( $iter, 7 );
            my $ar_ok      = $model->get( $iter, 8 );
            $cell->set( text       => $info );
            $cell->set( foreground => $ar_perfect ? "#ff0000" : "#000000" );
            $cell->set( weight     => $ar_ok ? 700 : 500 );
            1;
        },
    );

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Zoom calculations",
        content => [
            Gtk2::Ex::FormFactory::List->new(
                name        => "zoom_calc_result_list",
                attr        => "zoom_calc.result_list",
                attr_select => "zoom_calc.selected_row",
                expand      => 1,
                scrollbars  => [ "never", "automatic" ],
                columns     => [
                    __ "Result size",
                    __ "BPP",
                    __ "Eff. AR",
                    __ "AR error",
                    __ "Clip1 (t/b/l/r)",
                    __ "Zoom size",
                    __ "Clip2 (t/b/l/r)",
                    "ar_perfect",
                    "ar_ok",
                ],
                types => [ ("zoom_calc_text") x 7, "int", "int" ],
                selection_mode => "browse",
                customize_hook => sub {
                    my ($gtk_simple_list) = @_;
                    ( $gtk_simple_list->get_columns )[7]->set( visible => 0 );
                    ( $gtk_simple_list->get_columns )[8]->set( visible => 0 );
                    1;
                },
            )
        ],
    );
}

sub result_list {
    my $self = shift;

    my $fast_resize_align  = $self->fast_resize_align;
    my $result_align       = $self->result_frame_align;
    my $result_align_clip2 = ( $self->achieve_result_align eq 'clip2' );
    my $auto_clip          = ( $self->auto_clip ne 'no' );
    my $use_clip1          = ( $self->auto_clip eq 'clip1' );
    my $video_bitrate      = $self->selected_title->tc_video_bitrate;

    my $calc_lref = $self->selected_title->calculator(
        fast_resize_align  => $fast_resize_align,
        result_align       => $result_align,
        result_align_clip2 => $result_align_clip2,
        auto_clip          => $auto_clip,
        use_clip1          => $use_clip1,
        video_bitrate      => $video_bitrate,
    );

    $self->set_calc_lref($calc_lref);

    my @result;
    foreach my $result ( @{$calc_lref} ) {
        push @result, [
            "$result->{clip2_width}x$result->{clip2_height}",
            sprintf( "%.3f",   $result->{bpp} ),
            sprintf( "%.4f",   $result->{eff_ar} ),
            sprintf( "%.4f%%", $result->{ar_err} ),
            "$result->{clip1_top} / $result->{clip1_bottom} / "
                . "$result->{clip1_left} / $result->{clip1_right}",
            "$result->{zoom_width}x$result->{zoom_height}",
            "$result->{clip2_top} / $result->{clip2_bottom} / "
                . "$result->{clip2_left} / $result->{clip2_right}",
            ( $result->{ar_err} < 0.000001 ),
            ( $result->{ar_err} < 0.3 ),

        ];
    }

    return \@result;
}

sub apply_values {
    my $self = shift;

    my $result_widget = $zoom_calc_ff->lookup_widget("zoom_calc_result_list");
    $result_widget->set_no_widget_update(1);

    my $calc_lref = $self->get_calc_lref;
    my $row       = $self->selected_row->[0];
    my $result    = $calc_lref->[$row];
    my $title     = $self->selected_title;
    my $context   = $self->get_context;
    my $proxy     = $context->get_proxy("title");

    $zoom_calc_ff->change_mouse_cursor("watch");

    $proxy->set_attrs(
        {   tc_zoom_width   => $result->{zoom_width},
            tc_zoom_height  => $result->{zoom_height},
            tc_clip1_left   => $result->{clip1_left},
            tc_clip1_right  => $result->{clip1_right},
            tc_clip1_top    => $result->{clip1_top},
            tc_clip1_bottom => $result->{clip1_bottom},
            tc_clip2_left   => $result->{clip2_left},
            tc_clip2_right  => $result->{clip2_right},
            tc_clip2_top    => $result->{clip2_top},
            tc_clip2_bottom => $result->{clip2_bottom},
            tc_fast_resize  => ( $self->fast_resize_align != 0 ),
        }
    );

    $context->get_object("clip_zoom")->make_previews;

    $zoom_calc_ff->change_mouse_cursor();

    $result_widget->set_no_widget_update(0);

    1;
}

1;
