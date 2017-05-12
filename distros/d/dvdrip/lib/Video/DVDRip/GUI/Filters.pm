# $Id: Filters.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Filters;
use Locale::TextDomain qw (video.dvdrip);

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $filters_ff;

sub selected_avail_filter_name           { shift->{selected_avail_filter_name}       }
sub selected_used_filter_instance_id     { shift->{selected_used_filter_instance_id} }

sub set_selected_avail_filter_name       { shift->{selected_avail_filter_name}       = $_[1] }
sub set_selected_used_filter_instance_id { shift->{selected_used_filter_instance_id} = $_[1] }

sub current_filter              { shift->{current_filter}               }
sub current_filter_settings     { shift->{current_filter_settings}      }

sub set_current_filter          { shift->{current_filter}       = $_[1] }
sub set_current_filter_settings { shift->{current_filter_settings} = $_[1] }

sub in_update                   { shift->{in_update}                    }
sub last_filter_built           { shift->{last_filter_built}            }

sub set_in_update               { shift->{in_update}            = $_[1] }
sub set_last_filter_built       { shift->{last_filter_built}    = $_[1] }

sub selected_avail_filter {
    my $self = shift;
    my $name_row = $self->selected_avail_filter_name;
    return undef if !$name_row || !$name_row->[0];
    return Video::DVDRip::FilterList->get_filter(
        filter_name => $name_row->[0],
    );
}

sub selected_used_filter_instance {
    my $self = shift;
    my ($no_filter_lookup) = @_;
    my $id_row = $self->selected_used_filter_instance_id;
    return undef if !$id_row || !$id_row->[0] ||
                    $id_row->[0] eq 'pre' || $id_row->[0] eq 'post';
    my $filter_settings =
        $self->get_context->get_object("filter_settings");
    return $filter_settings->get_filter_instance(id => $id_row->[0]);
}

sub open_window {
    my $self = shift;

    return if $filters_ff;

    $self->build;

    1;
}

sub build {
    my $self = shift;

    my $context = $self->get_context;

    $filters_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __ "dvd::rip - Filters & Preview",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        default_width  => 680,
                        default_height => 500,
                    );
                    1;
                },
                closed_hook => sub {
                    $filters_ff->close if $filters_ff;
                    $filters_ff = undef;
                    $context->set_object(filter_window => undef);
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::Table->new(
                        expand => 1,
                        layout => q{
                            +>----------------------------------------+
                            | Available filters    Selected filters   |
                            |                                         |
                            +-----------------------------------------+
                            ^ Filter info          Filter Settings    |
                            |                                         |
                            +->------------------+--------------------+
                            | Prev. settings     | Preview control    |
                            +--------------------+--------------------+
			},
                        content => [
                            Gtk2::Ex::FormFactory::HBox->new (
                                height  => 220,
                                content => [
                                    $self->build_available_filters_box,
                                    $self->build_selected_filters_box,
                                ],
                                properties => {
                                    homogeneous => 1,
                                },
                            ),
                            Gtk2::Ex::FormFactory::HBox->new (
                                expand  => 1,
                                content => [
                                    $self->build_filter_info_box,
                                    $self->build_filter_settings_box,
                                ],
                                properties => {
                                    homogeneous => 1,
                                },
                            ),
                            $self->build_preview_settings_box,
                            $self->build_preview_control_box,
                        ],
                    ),
                ],
            ),

        ],
    );

    $filters_ff->build;
    $filters_ff->update;
    $filters_ff->show;

    $context->set_object(filter_window => $self);

    1;
}

sub build_available_filters_box {
    my $self = shift;

    Gtk2::SimpleList->add_column_type(
	    'avail_filter_row',
	    type     => "Glib::Scalar",
	    renderer => "Gtk2::CellRendererText",
	    attr     => sub {
	        my ($treecol, $cell, $model, $iter, $col_num) = @_;
		my $locked = $model->get($iter, 2);
                $cell->set ( text       => $model->get($iter, $col_num) );
		$cell->set ( foreground => $locked ? "grey" : "black");
		1;
	    },
    );

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Available filters",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::List->new (
                name        => "avail_filters",
                attr        => "avail_filter_list.filters",
                attr_select => "filter_window.selected_avail_filter_name",
                attr_select_column => 0,
                columns    => [ __"Name", __"Description", "locked" ],
                visible    => [ 1,        1,               0 ],
                types      => [ "avail_filter_row", "avail_filter_row", "int" ],
                scrollbars => [ "automatic", "automatic" ],
                expand     => 1,
                tip        => __"Double click a row to activate a filter. "
                              . "Greyed out filters are not available anymore, "
                              . "because they are activated already.",
                signal_connect => {
                    row_activated => sub {
                        my ($sl, $path, $column) = @_;
                        my $row_ref = $sl->get_row_data_from_path($path);
                        return if $row_ref->[2]; # locked, can't be added again
                        $self->activate_selected_avail_filter;
                        1;
                    },
                },
                changed_hook => sub { $self->unselect_used_filters },
                changed_hook_after => sub {
                    $self->get_context->set_object (
                        "current_filter_settings",
                        undef,
                    );
                    $self->build_filter_settings_form;
                    $self->get_context->set_object (
                        "current_filter_settings",
                        $self->current_filter_settings,
                    );
                },
           ),
        ],
    );
}

sub build_selected_filters_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Used filters",
        expand => 1,
        content => [
            Gtk2::Ex::FormFactory::List->new (
                name       => "used_filters",
                attr       => "filter_settings.filters",
                attr_select => "filter_window.selected_used_filter_instance_id",
                attr_select_column => 0,
                columns    => [ "id", __"Name", __"Description" ],
                visible    => [ 0,    1,        1,              ],
                scrollbars => [ "always", "always" ],
                expand     => 1,
                tip        => __"Double click a row to remove a filter, "
                                . "reorder by drag and drop",
                signal_connect => {
                    row_activated => sub {
                        $self->deactivate_selected_avail_filter;
                        1;
                    },
                },
                customize_hook => sub {
                    my ($gtk_simple_list, $list) = @_;
                    $gtk_simple_list->set_reorderable(1);
                    $gtk_simple_list->get_model->signal_connect ("row-changed", sub {
                        my ($model, $path, $iter) = @_;
                        return 1 if $list->get_in_update;
                        if ( $self->preview_is_open ) {
		            $self->message_window (
                                ff      => $filters_ff,
                                message => __"You can't change the filter "
                                           . "order\nwhile the preview window is open."
		            );
                            return 1;
                        }
                        my $id = $gtk_simple_list->get_row_data_from_path($path)->[0];
                        $path->next;
                        my $before_row = $gtk_simple_list->get_row_data_from_path($path); 
                        my $before_id  = $before_row ? $before_row->[0] : undef;
                        $self->reorder_filter($id, $before_id);
                        1;
                    });
                },
                changed_hook => sub { $self->unselect_avail_filters },
                changed_hook_after => sub {
                    $self->get_context->set_object (
                        "current_filter_settings",
                        undef,
                    );
                    $self->build_filter_settings_form;
                    $self->get_context->set_object (
                        "current_filter_settings",
                        $self->current_filter_settings,
                    );
                },
            ),
        ],
    );
}

sub build_filter_info_box {
    my $self = shift;
    
    return Gtk2::Ex::FormFactory::VBox->new (
        title    => __"Filter information",
        object   => "current_filter",
        expand   => 1,
        content  => [        
            Gtk2::Ex::FormFactory::Form->new (
                expand   => 1,
                label_top_align => 1,
                scrollbars => [ "always", "always" ],
                content  => [
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("Filter name")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.filter_name",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("Description")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.desc",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("Version")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.version",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("Author(s)")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.author",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("A/V type")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.av_type",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("Colorspace")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.colorspace_type",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("PRE/POST")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.pre_post_type",
                    ),
                    Gtk2::Ex::FormFactory::Label->new (
                        label        => "<i>".__("Multiple")."</i>   ",
                        label_markup => 1,
                        attr         => "current_filter.multiple_type",
                    ),
                ],
                properties => {
                    row_spacing  => 5,
                    border_width => 5,
                },
            )
        ]
    );
}

sub build_filter_settings_box {
    my $self = shift;
    
    return Gtk2::Ex::FormFactory::VBox->new (
        name     => "filter_settings_vbox",
        title    => __"Filter settings",
        object   => "current_filter_settings",
        expand   => 1,
    );
}


sub build_preview_settings_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Preview settings",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::Combo->new (
                attr => "title.tc_preview_buffer_frames",
                tip  => __("Frames buffered in the preview window ".
                           "and thus are available for scrubbing"),
                presets => [ 20, 50, 100, 150, 200],
                width => 80,
                expand => 0,
            ),
            Gtk2::Ex::FormFactory::Entry->new (
                attr  => "title.tc_preview_start_frame",
                tip   => __"Preview should start at this frame",
                width => 40,
                expand => 1,
            ),
            Gtk2::Ex::FormFactory::Label->new (
                label => " - ",
            ),
            Gtk2::Ex::FormFactory::Entry->new (
                attr => "title.tc_preview_end_frame",
                tip  => __"Preview should start stop this frame",
                width => 40,
                expand => 1,
            ),
        ],
    );
}

sub build_preview_control_box {
    my $self = shift;

    my $active_when_preview_open = sub {
        $self->get_context_object("preview_window") ? 1 : 0;
    };
    my $active_when_preview_closed = sub {
        $self->get_context_object("preview_window") ? 0 : 1;
    };
    my $active_when_preview_paused = sub {
        my $preview = $self->get_context_object("preview_window");
        return $preview && $preview->paused;
    };
    my $inactive_when_preview_paused = sub {
        my $preview = $self->get_context_object("preview_window");
        return $preview && !$preview->paused;
    };

    return Gtk2::Ex::FormFactory::HBox->new (
        title   => __"Preview control",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-play",
                label => "",
                tip   => __"Open preview window and play",
                active_cond    => $active_when_preview_closed,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_play },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-apply",
                label => "",
                tip   => __"Apply filter chain",
                active_cond    => $inactive_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_apply },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-remove",
                label => "",
                tip   => __"Decrease preview speed",
                active_cond    => $inactive_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_command("slower") },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-add",
                label => "",
                tip   => __"Increase preview speed",
                active_cond    => $inactive_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_command("faster") },
            ),
            Gtk2::Ex::FormFactory::ToggleButton->new (
                attr  => "preview_window.paused",
                stock => "gtk-media-pause",
                true_label  => "",
                false_label => "",
                tip   => __"Pause/Resume",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
                changed_hook   => sub { $self->preview_pause },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-rewind",
                with_repeat => 1,
                label => "",
                tip   => __"Step backward one frame",
                active_cond    => $active_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_command("slowbw") },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-forward",
                with_repeat => 1,
                label => "",
                tip   => __"Step forward one frame",
                active_cond    => $active_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_command("slowfw") },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-goto-first",
                with_repeat => 1,
                label => "",
                tip   => __"Step backward several frames",
                active_cond    => $active_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_command("fastbw") },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-goto-last",
                with_repeat => 1,
                label => "",
                tip   => __"Step forward several frames",
                active_cond    => $active_when_preview_paused,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_command("fastfw") },
            ),
            Gtk2::Ex::FormFactory::Button->new (
                stock => "gtk-media-stop",
                label => "",
                tip   => __"Stop playing and close preview window",
                active_cond    => $active_when_preview_open,
                active_depends => [ "preview_window" ],
                clicked_hook   => sub { $self->preview_stop },
            ),
       ],
    );
}

sub get_transcode_remote {
    my $self = shift;
    
    return $self->get_context_object("preview_window")
                ->transcode_remote
}

sub preview_is_open {
    my $self = shift;
    return $self->get_context_object("preview_window") ? 1 : 0;
}

sub preview_command {
    my $self = shift;
    my ($command) = @_;
    $self->get_transcode_remote->preview( command => $command );
    1;
}

sub preview_play {
    my $self = shift;

    require Video::DVDRip::GUI::Preview;

    my $preview = Video::DVDRip::GUI::Preview->new (
        context   => $self->get_context,
	closed_cb => sub {
	    $self->preview_stop
	},
	selection_cb => sub { $self->preview_selection ( @_ ) },
	eof_cb => sub {
            my ($ok) = @_;
	    $self->preview_stop;
	    $ok == 1 && Glib::Timeout->add (1000, sub {
		$self->preview_play;
		return 0;
	    });
	},
    );

    $self->get_context->set_object ( "preview_window" => $preview );

    $preview->open;

    1;
}

sub preview_stop {
    my $self = shift;
    
    my $preview = $self->get_context_object("preview_window");
    $self->get_context->set_object ( "preview_window" => 0 );
    
    $preview->stop;
    
    1;
}

sub preview_pause {
    my $self = shift;

    my $context = $self->get_context;
    
    $context->get_object("preview_window")->pause;
    $context->update_object_widgets("preview_window");

    1;
}

sub preview_apply {
    my $self = shift;

    my $context = $self->get_context;
    
    $context->get_object("preview_window")->apply_filter_settings;

    1;
}

sub preview_selection {
    my $self = shift;
    my %par = @_;
    my  ($x1, $y1, $x2, $y2) =
    @par{'x1','y1','x2','y2'};

    my $context        = $self->get_context;
    my $title          = $context->get_object("title");
    my $filter_setting = $context->get_object("current_filter_settings");
    
    return unless $filter_setting;
    
    my $filter         = $filter_setting->get_filter;

    my $selection_cb   = $filter->get_selection_cb;
    return 1 if not $selection_cb;

    ($x1, $x2) = ($x2, $x1) if $x1 > $x2;
    ($y1, $y2) = ($y2, $y1) if $y1 > $y2;

    if ( $filter_setting->queue eq 'pre' ) {
	# transform back values => undo resizing & clipping

	# undo 2nd clip
	$x1 += $title->tc_clip2_left;
	$y1 += $title->tc_clip2_top;
	$x2 += $title->tc_clip2_left;
	$y2 += $title->tc_clip2_top;

	# undo resize
	my $width_factor = $title->tc_zoom_width /
			   ( $title->width - $title->tc_clip1_left
				   	   - $title->tc_clip1_right );
	my $height_factor = $title->tc_zoom_height/
			   ( $title->height - $title->tc_clip1_top
				   	    - $title->tc_clip1_bottom );
	$x1 = int ($x1 / $width_factor );
	$x2 = int ($x2 / $width_factor );
	$y1 = int ($y1 / $height_factor );
	$y2 = int ($y2 / $height_factor );

	# undo 1st clip
	$x1 += $title->tc_clip1_left;
	$y1 += $title->tc_clip1_top;
	$x2 += $title->tc_clip1_left;
	$y2 += $title->tc_clip1_top;
    }

    if ( $title->tc_use_yuv_internal ) {
	foreach my $x ( $x1, $x2, $y1, $y2 ) {
	    $x = int($x/2)*2;
	}
    }

    &$selection_cb (
	filter_setting  => $filter_setting,
	x1              => $x1,
	y1              => $y1,
	x2              => $x2,
	y2              => $y2,
    );

    $context->update_object_widgets("current_filter_settings");

    $self->preview_apply;

    1;
}

sub activate_selected_avail_filter {
    my $self = shift;

    my $filter_list = 
        $self->get_context->get_object("avail_filter_list");

    my $filter_settings =
        $self->get_context->get_object("filter_settings");

    my $filter_name =
        $self->selected_avail_filter_name->[0];

    my $instance = $filter_settings->add_filter (
        filter_name => $filter_name,
    );

    my $preview = $self->get_context_object("preview_window");

    $preview && $preview->transcode_remote->config_filter (
        filter  => $instance->filter_name,
        options => $instance->get_config_string,
    );

    $self->get_context->update_object_attr_widgets(
        "filter_settings", "filters"
    );

    $self->get_context->update_object_attr_widgets(
        "avail_filter_list", "filters"
    );

    my $list = $filters_ff->get_widget("used_filters");
    $list->select_row_by_attr($instance->id);

    1;
}

sub deactivate_selected_avail_filter {
    my $self = shift;

    my $filter_settings =
        $self->get_context->get_object("filter_settings");

    my $id = $self->selected_used_filter_instance_id->[0];

    return 1 if $id =~ /^(?:pre|post)$/;

    my $instance = $filter_settings->del_filter ( id => $id );
    my $preview  = $self->get_context_object("preview_window");

    $preview && $preview->transcode_remote->disable_filter (
        filter => $instance->filter_name
    );

    $self->get_context->update_object_attr_widgets(
        "filter_settings", "filters"
    );

    $self->get_context->update_object_attr_widgets(
        "avail_filter_list", "filters"
    );

    my $list = $filters_ff->get_widget("avail_filters");
    $list->select_row_by_attr($instance->filter_name);

    1;
}

sub reorder_filter {
    my $self = shift;
    my ($id, $before_id) = @_;
    
    return if $id == $before_id;
    
    my $filter_settings =
        $self->get_context->get_object("filter_settings");

    my $success = $filter_settings->move_instance (
        id        => $id,
        before_id => $before_id,
    );
    
    if ( !$success ) {
        $self->get_context->update_object_attr_widgets(
            "filter_settings", "filters"
        );
    }
    
    1;
}

sub unselect_used_filters {
    my $self = shift;

    return if $self->in_update;

    $self->set_in_update(1);
    my $list = $filters_ff->get_widget("used_filters");
    $list->get_gtk_widget->get_selection->unselect_all;
    $self->set_in_update(0);

    1;
}

sub unselect_avail_filters {
    my $self = shift;

    return if $self->in_update;

    $self->set_in_update(1);
    my $list = $filters_ff->get_widget("avail_filters");
    $list->get_gtk_widget->get_selection->unselect_all;
    $self->set_in_update(0);

    1;
}

sub build_filter_settings_form {
    my $self = shift;

    my $instance = $self->current_filter_settings;
    my $filter   = $instance ? $instance->get_filter : undef;

    return if $self->last_filter_built eq $filter;

    $self->set_last_filter_built($filter);

    my $vbox       = $filters_ff->get_widget("filter_settings_vbox");
    my $old_widget = $vbox->get_content->[0];

    $old_widget && $vbox->remove_child_widget($old_widget);

    return if !$instance;

    my @content = (
        Gtk2::Ex::FormFactory::YesNo->new (
            attr        => "current_filter_settings.enabled",
            label       => __"Filter",
            true_label  => __"Enable",
            false_label => __"Disable",            
            tip	        => __"Enable or disable filter temporarily",
        ),
    );

    my %used_options;
    foreach my $option ( @{$filter->options} ) {
        next if $option->option_name eq 'pre';
        next if $used_options{$option->option_name};
        $used_options{$option->option_name} = 1;
        
        my @option_widgets;
        for ( my $idx=0; $idx < @{$option->fields}; ++$idx ) {
            my $widget = $self->build_option_field($option, $idx);
            if ( $widget->get_width && @{$option->fields} == 1 ) {
                $widget->set_width($widget->get_width+50);
            }
            push @option_widgets, $widget;
        }
        push @content, Gtk2::Ex::FormFactory::HBox->new (
            label   => $option->get_wrapped_desc,
            content => \@option_widgets,
        );
    }

    my $form = Gtk2::Ex::FormFactory::Form->new (
        content         => \@content,
        expand          => 1,
        scrollbars      => [ "always", "always" ],
        properties      => {
            row_spacing  => 5,
            border_width => 5,
        },
        active_cond     => sub { $self->selected_used_filter_instance },
        active_depends  => "current_filter_settings",
    );

    $vbox->add_child_widget($form);

    1;
}

sub build_option_field {
    my $self = shift;
    my ($option, $idx) = @_;
    
    my $field       = $option->fields->[$idx];
    my $option_name = $option->option_name;
    my $attr        = "current_filter_settings.filter_option_".$option_name."_$idx";

    if ( $field->checkbox || $field->switch ) {
        return Gtk2::Ex::FormFactory::CheckButton->new (
            attr            => $attr,
            detach_label    => 1,
            tip             => $field->get_range_text,
        );
    }

    if ( $field->combo ) {
        my @presets = ( $field->range_from .. $field->range_to );
        return Gtk2::Ex::FormFactory::Combo->new (
            attr    => $attr,
            width   => 60,
            presets => \@presets,
            tip     => $field->get_range_text,
        );
    }

    return Gtk2::Ex::FormFactory::Entry->new (
        attr    => $attr,
        width   => 50,
        tip     => $field->get_range_text,
    );
}

1;

