# $Id: Preferences.pm 2343 2007-08-09 21:36:08Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Preferences;
use Locale::TextDomain qw (video.dvdrip);

use base qw(Video::DVDRip::GUI::Base);

use strict;
use Carp;

my $config_ff;

sub page2params			{ shift->{page2params}			}
sub set_page2params		{ shift->{page2params}		= $_[1]	}

sub gtk_notebook		{ shift->{gtk_notebook}			}
sub set_gtk_notebook		{ shift->{gtk_notebook}		= $_[1]	}

sub gtk_text_buffer		{ shift->{gtk_text_buffer}		}
sub set_gtk_text_buffer		{ shift->{gtk_text_buffer}	= $_[1]	}

sub open_window {
    my $self = shift;

    return if $config_ff;

    my $config = $self->config_object;
    my $clone  = $config->clone;

    $self->get_context->set_object( config => $clone );

    $self->build;

    1;
}

sub build {
    my $self = shift;

    my $context = $self->get_context;

    $config_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        parent_ff => $self->get_form_factory,
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __ "dvd::rip - Preferences",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        default_width  => 640,
                        default_height => 460,
                    );
                    1;
                },
                properties  => { modal => 1, },
                closed_hook => sub     {
                    $config_ff->close if $config_ff;
                    $config_ff = undef;
                    $self->get_context->set_object( config => undef );
                    1;
                },
                content => [
                    Gtk2::Ex::FormFactory::Table->new(
                        title  => __ "Global preferences",
                        expand => 1,
                        layout => "
                                +>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+
                                | Notebook                        |
                                |                                 |
                                +---------------------------------+
                                ^ Check results                   |
                                +--------------------------------]+
                                |                         Buttons |
                                +---------------------------------+
			    ",
                        content => [
                            $self->build_config_notebook,
                            $self->build_config_check_results,
                            $self->build_config_buttons,
                        ],
                    ),
                ],
            ),

        ],
    );

    $config_ff->open;
    $config_ff->update;

    $self->check_params;

    1;
}

sub build_config_notebook {
    my $self = shift;

    my @notebook_pages;

    my $config_object = $self->config_object;
    my $context       = $self->get_context;
    
    my ( $label, $order );
    my $page_no = 0;
    my %page2params;

    $self->set_page2params( \%page2params );

    my $changed_hook = sub { $self->check_params };

    for ( my $i = 0; $i < @{ $config_object->order }; ) {
        $label = $config_object->order->[$i];
        $order = $config_object->order->[ $i + 1 ];
        $i += 2;

        my @items;
        foreach my $item_name ( @{$order} ) {
            my $item_def = $config_object->config->{$item_name};
            my ( $ff_class, %ff_params );

            push @{ $page2params{$page_no} }, $item_name;

            $ff_params{label}              = $item_def->{label};
            $ff_params{label_group}        = "pref_labels";
            $ff_params{rules}              = $item_def->{rules};
            $ff_params{attr}               = "config.$item_name";
            $ff_params{changed_hook_after} = $changed_hook;
            $ff_params{tip}                = $item_def->{tooltip};

            if ( $item_def->{avail_method} ) {
                my $method = $item_def->{avail_method};
                if ( ! Video::DVDRip::Config->$method() ) {
                    $ff_params{active_cond} = sub { 0 };
                }
            }

            if ( $item_def->{type} eq 'string' ) {
                if ( $item_def->{presets} ) {
                    $ff_class = "Gtk2::Ex::FormFactory::Combo";
                    $ff_params{presets} = $item_def->{presets};
                }
                else {
                    $ff_class = "Gtk2::Ex::FormFactory::Entry";
                }
            }
            elsif ( $item_def->{type} eq 'number' ) {
                $ff_class = "Gtk2::Ex::FormFactory::Entry";
            }
            elsif ( $item_def->{type} eq 'file' ) {
                $ff_class = "Gtk2::Ex::FormFactory::Entry";
            }
            elsif ( $item_def->{type} eq 'dir' ) {
                my $attr = $ff_params{attr};
                push @items, Gtk2::Ex::FormFactory::HBox->new (
                    label   => delete $ff_params{label},
                    content => [
                        Gtk2::Ex::FormFactory::Entry->new(%ff_params, expand => 1),
                        Gtk2::Ex::FormFactory::Button->new (
                            stock          => "gtk-add",
                            label          => "",
                            tip            => __"Create directory",
                            active_cond    => sub { ! -d $context->get_object_attr($attr) },
                            active_depends => $attr,
                            clicked_hook   => sub {
                                my $dir = $context->get_object_attr($attr);
                                mkdir $dir, 0755 or croak "msg:".__x(
                                    "Can't create directory:\n\n{dir}",
                                    dir => $dir );
                                $context->update_object_widgets("config");
                                $self->check_params;
                                1;
                            },
                        ),
                    ],
                );
                $ff_class = "";
                
            }
            elsif ( $item_def->{type} eq 'switch' ) {
                $ff_class = "Gtk2::Ex::FormFactory::YesNo";
                $ff_params{true_label} = __"Yes";
                $ff_params{false_label} = __"No";
            }
            elsif ( $item_def->{type} eq 'popup' ) {
                $ff_class = "Gtk2::Ex::FormFactory::Popup";
                $ff_params{items} = $item_def->{presets};
            }
            else {
                warn
                    "Unknown config type '$item_def->{type}' for '$item_name'";
            }

            if ( $item_def->{dvd_button} && $self->has("hal") ) {
                my $popup = Gtk2::Ex::FormFactory::Popup->new (
                    attr     => "config.selected_dvd_device",
                    expand_h => 0,
                    changed_hook_after => sub {
                        $self->get_context->set_object_attr (
                            "config", "dvd_device",
                            $self->get_context->get_object_attr (
                                "config.selected_dvd_device",
                            ),
                        );
                        $self->check_params;
                    },
                    tip => __"This is a list of connected DVD drives "
                            ."found in your system"
                );

                $ff_params{expand} = 1;

                push @items, Gtk2::Ex::FormFactory::HBox->new (
                    label   => delete $ff_params{label},
                    content => [
                        $ff_class->new(%ff_params),
                        $popup,
                    ],
                );
            }
            else {
                push @items, $ff_class->new(%ff_params)
                    if $ff_class;
            }
        }

        push @notebook_pages, Gtk2::Ex::FormFactory::Form->new(
            title   => $label,
            content => \@items,
        );

        ++$page_no;
    }

    return Gtk2::Ex::FormFactory::Notebook->new(
        content        => \@notebook_pages,
        expand         => 1,
        customize_hook => sub {
            $self->set_gtk_notebook( $_[0] );
            1;
        },
        changed_hook => sub {
            $self->check_params;
        },
    );
}

sub build_config_buttons {
    my $self = shift;

    return Gtk2::Ex::FormFactory::HBox->new(
        properties => { homogeneous => 1, },
        content    => [
            Gtk2::Ex::FormFactory::Button->new(
                label        => __ "Check all settings",
                stock        => "gtk-spell-check",
                clicked_hook => sub {
                    $self->check_params( all_pages => 1 );
                },
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label        => __ "Cancel",
                stock        => "gtk-cancel",
                clicked_hook => sub {
                    $config_ff->close;
                    $config_ff = undef;
                    $self->get_context->set_object( config => undef );
                    1;
                },
            ),
            Gtk2::Ex::FormFactory::Button->new(
                label        => __ "Ok",
                stock        => "gtk-ok",
                clicked_hook => sub {
                    my $config_object = $self->config_object;
                    $config_object->copy_values_from(
                        $self->get_context_object("config") );
                    $config_object->save;
                    $config_ff->close;
                    $config_ff = undef;
                    $self->get_context->set_object( config => undef );
                    my $project = $self->get_context->get_object("project");
                    return if not $project;
                    $project->set_dvd_device(
                        $config_object->get_value('dvd_device') );
                    1;
                },
            ),
        ],
    );
}

sub build_config_check_results {
    my $self = shift;

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Check results",
        content => [
            Gtk2::Ex::FormFactory::TextView->new(
                expand     => 1,
                scrollbars => [ "never", "always" ],
                properties => {
                    editable       => 0,
                    cursor_visible => 0,
                    wrap_mode      => "word",
                },
                customize_hook => sub {
                    my ($gtk_text_view) = @_;
                    my $tag_table = Gtk2::TextTagTable->new;
                    $tag_table->add(
                        $self->create_text_tag(
                            "good_value",
                            foreground => "#3f7c3d",
                            weight     => 600,
                        )
                    );
                    $tag_table->add(
                        $self->create_text_tag(
                            "bad_value",
                            foreground => "#ff0000",
                            weight     => 600,
                        )
                    );
                    my $buffer = Gtk2::TextBuffer->new($tag_table);
                    $gtk_text_view->set_buffer($buffer);
                    $self->set_gtk_text_buffer($buffer);
                    1;
                },
            ),
        ],
    );
}

sub check_params {
    my $self = shift;
    my %par  = @_;
    my ( $page, $all_pages ) = @par{ 'page', 'all_pages' };

    my @pages;
    if ( not $all_pages ) {
        $page = $self->gtk_notebook->get_current_page
            if not defined $page;
        push @pages, $page;
    }
    else {
        @pages = sort { $a <=> $b } keys %{ $self->page2params };
    }

    my $buffer        = $self->gtk_text_buffer;
    my $config_object = $self->get_context_object("config");

    $buffer->set_text("");

    my $iter = $buffer->get_start_iter;

    my ( $options, $method );
    foreach $page (@pages) {
        $options = $self->page2params->{$page};
        foreach my $option ( @{$options} ) {
            $buffer->insert( $iter,
                $config_object->config->{$option}->{label} . ": " );
            my ($result_text, $result_value);
            $method = "test_$option";
            if ( $config_object->can($method) ) {
                ($result_text, $result_value) = $config_object->$method($option);
            }
            else {
                $result_text = __ "not tested : Ok";
                $result_value = 1;
            }
            $buffer->insert_with_tags_by_name(
                $iter,
                $result_text . "\n",
                $result_value ? "good_value" : "bad_value"
            );
        }
        $buffer->insert( $iter, ( "-" x 120 ) . "\n" )
            unless $page == $pages[-1];
    }

    1;
}

1;
