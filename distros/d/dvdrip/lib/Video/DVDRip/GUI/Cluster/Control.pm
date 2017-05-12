# $Id: Control.pm 2303 2007-04-13 11:23:39Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Control;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Base;
use Gtk2::Helper;

use Event::RPC 0.89;
use Event::RPC::Client;

use Video::DVDRip::GUI::Cluster::Node;
use Video::DVDRip::GUI::Cluster::Title;

use strict;
use Carp;

sub rpc_client                 { shift->{rpc_client}                   }
sub master                     { shift->{master}                       }
sub log_socket                 { shift->{log_socket}                   }
sub gtk_log_view               { shift->{gtk_log_view}                 }
sub gtk_log_buffer             { shift->{gtk_log_buffer}               }
sub exit_on_close              { shift->{exit_on_close}                }
sub selected_project_id        { shift->{selected_project_id}          }
sub selected_job_id            { shift->{selected_job_id}              }
sub selected_node_name         { shift->{selected_node_name}           }
sub master_event_queue         { shift->{master_event_queue}           }
sub log_watcher                { shift->{log_watcher}                  }
sub event_timeout              { shift->{event_timeout}                }
sub node_gui                   { shift->{node_gui}                     }
sub cluster_ff                 { shift->{cluster_ff}                   }
sub pane1_pos                  { shift->{pane1_pos}                    }
sub pane2_pos                  { shift->{pane2_pos}                    }
sub pane3_pos                  { shift->{pane3_pos}                    }
sub window_height              { shift->{window_height}                }
sub window_width               { shift->{window_width}                 }

sub set_rpc_client              { shift->{rpc_client}           = $_[1] }
sub set_master                  { shift->{master}               = $_[1] }
sub set_log_socket              { shift->{log_socket}           = $_[1] }
sub set_gtk_log_view            { shift->{gtk_log_view}         = $_[1] }
sub set_gtk_log_buffer          { shift->{gtk_log_buffer}       = $_[1] }
sub set_exit_on_close           { shift->{exit_on_close}        = $_[1] }
sub set_selected_project_id     { shift->{selected_project_id}  = $_[1] }
sub set_selected_job_id         { shift->{selected_job_id}      = $_[1] }
sub set_selected_node_name      { shift->{selected_node_name}   = $_[1] }
sub set_master_event_queue      { shift->{master_event_queue}   = $_[1] }
sub set_log_watcher             { shift->{log_watcher}          = $_[1] }
sub set_event_timeout           { shift->{event_timeout}        = $_[1] }
sub set_node_gui                { shift->{node_gui}             = $_[1] }
sub set_cluster_ff              { shift->{cluster_ff}           = $_[1] }
sub set_pane1_pos               { shift->{pane1_pos}            = $_[1] }
sub set_pane2_pos               { shift->{pane2_pos}            = $_[1] }
sub set_pane3_pos               { shift->{pane3_pos}            = $_[1] }
sub set_window_height           { shift->{window_height}        = $_[1] }
sub set_window_width            { shift->{window_width}         = $_[1] }

sub selected_node {
    my $self = shift;
    my $name = $self->selected_node_name;
    return unless defined $name;
    $name = $name->[0];
    return unless $self->master;
    return $self->master->get_node_by_name($name);
}

sub selected_project {
    my $self = shift;
    my $id   = $self->selected_project_id;
    return unless defined $id;
    $id = $id->[0];
    return unless defined $id;
    return unless $self->master;
    return $self->master->get_project_by_id($id);
}

sub selected_job {
    my $self = shift;
    my $id   = $self->selected_job_id;
    return unless defined $id;
    $id = $id->[0];
    return unless defined $id;
    return $self->selected_project->get_job_by_id($id);
}

# GUI Stuff ----------------------------------------------------------

sub get_gui_state_file {
    return $ENV{HOME}."/.dvdrip/cluster-gui.state";
}

sub save_gui_state {
    my $self = shift;

    my $file = $self->get_gui_state_file;
    open (my $fh, "> $file") or die "can't write $file";
    print $fh $self->pane1_pos."\t".
              $self->pane2_pos."\t".
              $self->pane3_pos."\t".
              $self->window_width."\t".
              $self->window_height."\n";
    close $fh;
    
    1;
}

sub load_gui_state {
    my $self = shift;

    my $file = $self->get_gui_state_file;
    if ( ! -f $file ) {
        $self->set_pane1_pos(170);
        $self->set_pane2_pos(180);
        $self->set_pane2_pos(220);
        $self->set_window_height(700);
        $self->set_window_width(700);
        $self->save_gui_state;
        return 1;
    }

    open (my $fh, $file) or die "can't read $file";
    my $line = <$fh>;
    close $fh;

    chomp $line;
    my @pos = split("\t", $line);

    $self->set_pane1_pos($pos[0]||170);
    $self->set_pane2_pos($pos[1]||180);
    $self->set_pane3_pos($pos[2]||220);
    $self->set_window_width($pos[3]||700);
    $self->set_window_height($pos[4]||700);
    1;
}

sub open_window {
    my $self = shift;

    $self->load_gui_state;

    my $context = $self->get_context;
    $context->set_object( cluster_gui => $self );

    my $cluster_ff = Gtk2::Ex::FormFactory->new(
        context   => $context,
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                name           => "cluster_window",
                title          => __ "dvd::rip - Cluster Control",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        default_width  => $self->window_width,
                        default_height => $self->window_height,
                    );
                    1;
                },
                closed_hook => sub {
                    $self->close_window;
                },
                content => [
                    $self->build_menu,
                    Gtk2::Ex::FormFactory::VBox->new (
                        object  => "cluster",
                        expand  => 1,
                        spacing => 0,
                        content => [
                            Gtk2::Ex::FormFactory::VPaned->new (
                                name    => "cluster_vpane1",
                                attr    => "cluster_gui.pane1_pos",
                                expand  => 1,
                                content => [
                                    $self->build_nodes_box,
                                    Gtk2::Ex::FormFactory::VPaned->new (
                                        name    => "cluster_vpane2",
                                        attr    => "cluster_gui.pane2_pos",
                                        content => [
                                            $self->build_projects_box,
                                            Gtk2::Ex::FormFactory::VPaned->new (
                                                name    => "cluster_vpane3",
                                                attr    => "cluster_gui.pane3_pos",
                                                content => [
                                                    $self->build_jobs_box,
                                                    $self->build_log_box,
                                                ],
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    );

    $self->set_cluster_ff($cluster_ff);
    $self->set_form_factory($cluster_ff);

    $cluster_ff->build;
    $cluster_ff->update;
    $cluster_ff->show;

    1;
}

sub close_window {
    my $self = shift;

    $self->disconnect_master;

    my $cluster_ff = $self->cluster_ff;

    $cluster_ff->get_widget("cluster_vpane1")->widget_to_object;
    $cluster_ff->get_widget("cluster_vpane2")->widget_to_object;
    $cluster_ff->get_widget("cluster_vpane3")->widget_to_object;

    my ($win_width, $win_height) =
        $cluster_ff->get_widget("cluster_window")->get_gtk_parent_widget->get_size;
    $self->set_window_height($win_height);
    $self->set_window_width($win_width);

    $self->save_gui_state;

    $self->get_context->set_object( cluster_gui => undef );

    $cluster_ff->close;
    $self->set_cluster_ff(undef);

    Gtk2->main_quit if $self->exit_on_close;

    1;
}

sub build_menu {
	my $self = shift;
	
	return Gtk2::Ex::FormFactory::Menu->new (
	    menu_tree => [
                __"_File" => {
                    item_type => '<Branch>',
                    children => [
                        __"_Close window" => {
			    item_type   => '<StockItem>',
			    extra_data  => 'gtk-close',
			    callback    => sub { $self->close_window },
			    accelerator => '<ctrl>w',
                        },
                    ],
                },
		__"_Master" => {
		    item_type => '<Branch>',
		    children  => [
		      __"_Connect Master Daemon" => {
		        callback    => sub { $self->connect_master },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-connect',
			accelerator => '<ctrl>M',
			object      => "!cluster",
		      },
		      __"_Disconnect from Master Daemon" => {
		        callback    => sub { $self->disconnect_master },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-disconnect',
			accelerator => '<ctrl>D',
			object      => "cluster",
		      },
		      "sep"	=> {
		        item_type => "<Separator>",
		      },
		      __"Shutdown Master Daemon" => {
		        callback    => sub { $self->shutdown_master },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-media-stop',
			object      => "cluster",
		      },
		    ],
		},
		__"_Node" => {
		    item_type => '<Branch>',
		    children  => [
		      __"_Add node" => {
		        callback    => sub { $self->add_node },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-add',
                        object      => "cluster",
		      },
		      __"_Edit node" => {
		        callback    => sub { $self->edit_node },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-edit',
			accelerator => '<ctrl>N',
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            my $state = $node->state;
                            $node->state ne 'running';
                        },
                        active_depends => "cluster_node",
		      },
		      __"_Start node" => {
		        callback    => sub { $self->start_node },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-execute',
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            $node->state eq 'stopped';
                        },
                        active_depends => "cluster_node",
		      },
		      __"Sto_p node" => {
		        callback    => sub { $self->stop_node },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-cancel',
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            $node->state ne 'stopped';
                        },
                        active_depends => "cluster_node",
		      },
		      __"_Remove node" => {
		        callback    => sub { $self->remove_node },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-delete',
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            my $state = $node->state;
                            $node->state ne 'running';
                        },
                        active_depends => "cluster_node",
		      },
		    ],
		},
		__"_Project" => {
		    item_type => '<Branch>',
		    children  => [
		      __"_Edit project" => {
		        callback    => sub { $self->edit_project },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-edit',
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'not scheduled';
                        },
                        active_depends => "cluster_project",
		      },
		      __"_Start project" => {
		        callback    => sub { $self->start_project },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-execute',
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'not scheduled';
                        },
                        active_depends => "cluster_project",
		      },
		      __"_Cancel project" => {
		        callback    => sub { $self->cancel_project },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-cancel',
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'running';
                        },
                        active_depends => "cluster_project",
		      },
		      __"Res_tart project" => {
		        callback    => sub { $self->restart_project },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-redo',
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'cancelled';
                        },
                        active_depends => "cluster_project",
		      },
		      __"_Remove project" => {
		        callback    => sub { $self->remove_project },
			item_type   => '<StockItem>',
			extra_data  => 'gtk-delete',
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state ne 'running';
                        },
                        active_depends => "cluster_project",
		      },
                    ],
                },
	    ],
	);
}

sub build_projects_box {
    my $self = shift;

    Gtk2::SimpleList->add_column_type(
        'cluster_project_text',
        type     => "Glib::Scalar",
        renderer => "Gtk2::CellRendererText",
        attr     => sub {
            my ( $treecol, $cell, $model, $iter, $col_num ) = @_;
            my $text  = $model->get( $iter, $col_num );
            my $state = $model->get( $iter, 3 );
            my $run = $state eq 'running';
            $cell->set( text => $text );
            $cell->set( weight => $run ? 700 : 500 );
            1;
        },
    );

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Project queue",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::List->new(
                attr               => "cluster.projects_list",
                attr_select        => "cluster_gui.selected_project_id",
                attr_select_column => 0,
                scrollbars         => [ "automatic", "automatic" ],
                expand             => 1,
                columns            => [
                    "id",
                    __ "Number",
                    __ "Project",
                    __ "State",
                    __ "Progress",
                ],
                types => [ "int", ("cluster_project_text") x 4 ],
                selection_mode => "single",
                customize_hook => sub {
                    my ($gtk_simple_list) = @_;
                    ( $gtk_simple_list->get_columns )[0]->set( visible => 0 );
                    1;
                },
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                content => [
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Edit project",
                        stock        => "gtk-edit",
                        clicked_hook => sub { $self->edit_project },
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'not scheduled';
                        },
                        active_depends => "cluster_project",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Start project",
                        stock        => "gtk-execute",
                        clicked_hook => sub { $self->start_project },
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'not scheduled';
                        },
                        active_depends => "cluster_project",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __"Cancel project",
                        stock        => "gtk-cancel",
                        clicked_hook => sub { $self->cancel_project },
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'running';
                        },
                        active_depends => "cluster_project",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __"Restart project",
                        stock        => "gtk-redo",
                        clicked_hook => sub { $self->restart_project },
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state eq 'cancelled' ||
                            $project->state eq 'error';
                        },
                        active_depends => "cluster_project",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        label        => __ "Remove project",
                        stock        => "gtk-delete",
                        clicked_hook => sub { $self->remove_project },
                        active_cond  => sub {
                            my $project = $self->selected_project or return;
                            $project->state ne 'running';
                        },
                        active_depends => "cluster_project",
                    ),
                ],
            ),
        ],
    );
}

sub build_jobs_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __"Job running status",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::ExecFlow->new(
                name        => "cluster_exec_flow",
                attr        => "cluster.exec_flow_job",
                scrollbars  => [ 'automatic', 'automatic' ],
                expand      => 1,
                customize_hook => sub {
                    my ($tree_view) = @_;
                    $tree_view->signal_connect (
                        row_activated => sub {
                            my ($gtk_tree_view, $path) = @_;
                            my $model = $gtk_tree_view->get_model;
                            my $iter = $model->get_iter($path);
                            my $job_id = $model->get($iter, 2);
                            my $job = $self->master->get_job_from_id($job_id);
                            return 1 unless $job->get_error_message;
                            $self->long_message_window (
                                message => $job->get_error_message,
                            );
                            1;
                        }
                    );
                },
            ),
        ],
    );
}

sub jobs_list {
    my $self = shift;
    my $project = $self->selected_project or return;
    return $project->jobs_list;
}

sub build_nodes_box {
    my $self = shift;

    Gtk2::SimpleList->add_column_type(
        'cluster_node_text',
        type     => "Glib::Scalar",
        renderer => "Gtk2::CellRendererText",
        attr     => sub {
            my ( $treecol, $cell, $model, $iter, $col_num ) = @_;
            my $text  = $model->get( $iter, $col_num );
            my $state = $model->get( $iter, 4 );
            my $run = $state !~ /stopped|idle|offline/;
            $cell->set( text => $text );
            $cell->set( weight => $run ? 700 : 500 );
            1;
        },
    );

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Registered Nodes",
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::List->new(
                attr               => "cluster.nodes_list",
                attr_select        => "cluster_gui.selected_node_name",
                attr_select_column => 0,
                expand             => 1,
                height             => 100,
                scrollbars         => [ "automatic", "automatic" ],
                columns            => [
                    "name",
                    __ "Number",
                    __ "Name",
                    __ "Job",
                    __ "Progress"
                ],

                #		    types	   => [
                #	    		 "int", ("cluster_node_text") x 4
                #		    ],
                selection_mode => "single",
                customize_hook => sub {
                    my ($gtk_simple_list) = @_;
                    ( $gtk_simple_list->get_columns )[0]->set( visible => 0 );
                    1;
                },
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                content => [
                    Gtk2::Ex::FormFactory::Button->new(
                        object       => "cluster",
                        label        => __ "Add node",
                        stock        => "gtk-add",
                        clicked_hook => sub { $self->add_node },
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object       => "cluster_node",
                        label        => __ "Edit node",
                        stock        => "gtk-edit",
                        clicked_hook => sub { $self->edit_node },
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            my $state = $node->state;
                            $node->state ne 'running';
                        },
                        active_depends => "cluster_node",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object       => "cluster_node",
                        label        => __ "Start node",
                        stock        => "gtk-execute",
                        clicked_hook => sub { $self->start_node },
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            $node->state eq 'stopped';
                        },
                        active_depends => "cluster_node",
                    ),
                    Gtk2::Ex::FormFactory::Button->new(
                        object       => "cluster_node",
                        label        => __ "Stop node",
                        stock        => "gtk-cancel",
                        clicked_hook => sub { $self->stop_node },
                        active_cond  => sub {
                            my $node = $self->selected_node or return;
                            $node->state ne 'stopped';
                        },
                        active_depends => "cluster_node",
                    ),
                ],
            ),
        ],
    );
}

sub build_log_box {
    my $self = shift;

    return Gtk2::Ex::FormFactory::VBox->new(
        title   => __ "Cluster control daemon log output",
        height  => 80,
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
                    my $font = Gtk2::Pango::FontDescription->from_string(
                        "mono 7.2");
                    $gtk_text_view->modify_font($font);
                    my $tag_table = Gtk2::TextTagTable->new;
                    $tag_table->add(
                        $self->create_text_tag(
                            "date", foreground => "#666666",
                        )
                    );
                    my $buffer = Gtk2::TextBuffer->new($tag_table);
                    $gtk_text_view->set_buffer($buffer);
                    $self->set_gtk_log_buffer($buffer);
                    $self->set_gtk_log_view($gtk_text_view);
                    1;
                },
            ),
        ],
    );
}

sub connect_master {
    my $self = shift;

    return if $self->master;

    if ( !$self->config('cluster_master_local') &&
         !($self->config('cluster_master_server') &&
	   $self->config('cluster_master_port') ) ) {
        $self->message_window (
	    message => __("You must first configure a ".
                          "cluster control daemon\n".
                          "in the Preferences dialog."),
        );
        return;
    }

    my $server = $self->config('cluster_master_local')
        ? 'localhost'
        : $self->config('cluster_master_server');

    my $port = $self->config('cluster_master_port');

    my $rpc_client = Event::RPC::Client->new(
        host        => $server,
        port        => $port,
        error_cb    => sub { $self->client_server_error },
        class_map   => {
            'Event::ExecFlow::Job'          => 'dvd_rip::Event::ExecFlow::Job',
            'Event::ExecFlow::Job::Group'   => 'dvd_rip::Event::ExecFlow::Job::Group',
            'Event::ExecFlow::Job::Command' => 'dvd_rip::Event::ExecFlow::Job::Command',
            'Event::ExecFlow::Job::Code'    => 'dvd_rip::Event::ExecFlow::Job::Code',
        },
    );

    eval { $rpc_client->connect };

    if ( not $rpc_client->get_connected ) {
        if ( not $self->config('cluster_master_local') ) {
            $self->error_window(
                message => __x(
                    "Can't connect to master daemon on {server}:{port}.",
                    server => $server,
                    port   => $port
                )
            );
            return;
        }

        # Ok, we try to start a local master daemon
        system("dvdrip-master 3 >/dev/null 2>&1 &");

        sleep 1;

        eval { $rpc_client->connect };

        # give up, if we still have no connection
        if ( not $rpc_client->get_connected ) {
            $self->error_window(
                message => __x(
                    "Can't start local master daemon on port {port}.\n".
                    "Execute the dvdrip-master program by hand to\n".
                    "see why it doesn't run.",
                    port => $port
                )
            );
            return;
        }
    }

    my $master = Video::DVDRip::Cluster::Master->get_master();
    $master->hello;

    $self->set_rpc_client($rpc_client);
    $self->set_master($master);
    $self->get_context->set_object( cluster => $master );
    $self->get_context->set_object( "!cluster" => undef );
    $self->get_context->update_object_widgets("cluster_node");
    $self->get_context->update_object_widgets("cluster_project");

    my $sock = Event::RPC::Client->log_connect(
        server => $server,
        port   => $port + 1,
    );

    $self->set_log_socket($sock);

    $self->set_master_event_queue( [] );
    
    my $log_buffer = "";
    my $log_watcher = Gtk2::Helper->add_watch(
        $sock->fileno,
        'in',
        sub {
            return 1 unless $self->master;
            if ( !sysread( $sock, $log_buffer, 4096, length($log_buffer) ) ) {
                $self->client_server_error;
                return 1;
            }
            my $buffer_offset;
            while ( $log_buffer =~ /(.*\n)/mg ) {
                my $line = $1;
                chomp($line);
                $buffer_offset = pos($log_buffer);
                if ( $line =~ /EVENT\t(.*)/ ) {
                    $self->enqueue_master_event( split( "\t", $1 ) );
                }
                else {
                    my $buffer = $self->gtk_log_buffer;
                    $buffer->insert( $buffer->get_end_iter, $line . "\n" );
                }
            }
            $log_buffer = substr($log_buffer, $buffer_offset);
            1;
        }
    );

    my $event_timeout = Glib::Timeout->add(
        200,
        sub {
            return unless $self->master;
            $self->process_master_event_queue;
            1;
        }
    );

    $self->set_log_watcher($log_watcher);
    $self->set_event_timeout($event_timeout);

    1;
}

sub disconnect_master {
    my $self = shift;

    #-- remove all timeouts, sockets and watchers
    Glib::Source->remove( $self->event_timeout )
        if $self->event_timeout;

    close($self->log_socket)
        if $self->log_socket;

    Gtk2::Helper->remove_watch( $self->log_watcher )
        if $self->log_watcher;

    #-- disconnect client    
    my $rpc_client = $self->rpc_client;
    $rpc_client->disconnect if $rpc_client;

    #-- destroy all objects which are connected to the master
    $self->set_master(undef);
    $self->set_log_watcher(undef);
    $self->set_event_timeout(undef);
    $self->set_log_socket(undef);
    $self->set_rpc_client(undef);
    $self->set_selected_project_id(undef);
    $self->set_selected_node_name(undef);

    #-- now (and not earlier!) destroy the objects in the context.
    #-- if that would happen bevor undef'ing the attributes above
    #-- FormFactory will trigger actions on the line again, which
    #-- is broken already!
    $self->get_context->set_object( cluster_project => undef );
    $self->get_context->set_object( cluster_node => undef );
    $self->get_context->set_object( cluster => undef );
    $self->get_context->set_object( "!cluster" => 1 );

    #-- close windows which are probably open
    my $cluster_node_gui =
        $self->get_context->get_object("cluster_node_gui");

    my $cluster_title_gui =
        $self->get_context->get_object("cluster_title_gui");

    $cluster_node_gui->close_window()  if $cluster_node_gui;
    $cluster_title_gui->close_window() if $cluster_title_gui;

    1;
}

sub enqueue_master_event {
    my $self = shift;
    my ( $event, @args ) = @_;

    my $queue = $self->master_event_queue;
    push @{$queue}, [ $event, \@args ];

    return;
}

{
    my %event2action = (
        PROJECT_UPDATE       => "update_projects_list",
        PROJECT_LIST_UPDATE  => "update_projects_list",
        PROJECT_DELETED      => "update_projects_list",
        JOB_PLAN_UPDATE      => "update_jobs_list[ARG0]",
        JOB_UPDATE           => "update_job[ARG0]",
        JOB_ADDED            => "update_job_add[ARG0]",
        JOB_REMOVED          => "update_job_removed[ARG0]",
        NODE_UPDATE          => "update_nodes_list",
        NODE_DELETED         => "update_nodes_list",
        JOB_PROGRESS_UPDATE  => "update_job_progress[ARG0,ARG1,ARG2,ARG3]",
        NODE_PROGRESS_UPDATE => "update_node_progress[ARG0,ARG1,ARG2]",
        NODE_TEST_FINISHED   => "node_test_finished",
        NO_MASTER_NODE_FOUND => "no_master_node_found",
    );

    sub process_master_event_queue {
        my $self  = shift;
        my $queue = $self->master_event_queue;
        return unless $self->master;
        return if @{$queue} == 0;

        my $cluster_ff = $self->cluster_ff;

        my %actions_seen;
        my @actions;
        for ( my $i = @{$queue} - 1; $i >= 0; --$i ) {
            my $action = $event2action{ $queue->[$i]->[0] };
            if ( !$action ) {
                warn "Unknown master event $queue->[$i]->[0]";
                next;
            }
            if ( $action =~ /ARG/ ) {
                $action =~ s/ARG0/$queue->[$i]->[1]->[0]/;
                $action =~ s/ARG1/$queue->[$i]->[1]->[1]/;
                $action =~ s/ARG2/$queue->[$i]->[1]->[2]/;
                $action =~ s/ARG3/$queue->[$i]->[1]->[3]/;
            }
            next if $actions_seen{$action};
            $actions_seen{$action} = 1;
            unshift @actions, [ $action, $queue->[$i] ];
        }

        # print "Queue items: ".@{$queue}." => actions ".@actions."\n";

        @{$queue} = ();

        my $context = $self->get_context;

        my $node_slist
            = $self->cluster_ff->get_widget("cluster.nodes_list")
            ->get_gtk_widget;

        foreach my $action_item (@actions) {
            my $action = $action_item->[0];
            my $event  = $action_item->[1]->[0];
            my $args   = $action_item->[1]->[1];

            if ( $action eq 'update_projects_list' ) {
                $context->update_object_attr_widgets("cluster.projects_list");
                $context->update_object_widgets("cluster_project");

            }
            elsif ( $action =~ /^update_jobs_list/ ) {
                my ($project_id) = @{$args};
                next unless $self->selected_project_id;

# print "update_jobs_list: $project_id <> ".$self->selected_project_id->[0]."\n";
                $context->update_object_attr_widgets("cluster_gui.jobs_list")
                    if $project_id == $self->selected_project_id->[0];

            }
            elsif ( $action =~ /^update_job_progress/ ) {
                next unless $self->selected_project_id;
                my ( $project_id, $job_nr, $state, $progress ) = @{$args};
                next if $project_id != $self->selected_project_id->[0];
#                $job_slist->{data}->[ $job_nr - 1 ]->[4] = $state;
#                $job_slist->{data}->[ $job_nr - 1 ]->[5] = $progress;

            }
            elsif ( $action =~ /^update_node_progress/ ) {
                my ( $name, $job, $progress ) = @{$args};
                for ( my $i = 0; $i < @{ $node_slist->{data} }; ++$i ) {
                    if ( $node_slist->{data}->[$i]->[0] eq $name ) {
                        $node_slist->{data}->[$i]->[3] = $job;
                        $node_slist->{data}->[$i]->[4] = $progress;
                        last;
                    }
                }

            }
            elsif ( $action =~ /^update_job_add/ ) {
                my ($job_id) = @{$args};
                my $job = $self->master->get_job_from_id($job_id);
                $cluster_ff->get_widget("cluster_exec_flow")->add_job($job)
                    if $job;

            }
            elsif ( $action =~ /^update_job_removed/ ) {
                my ($job_id) = @{$args};
                $cluster_ff->get_widget("cluster_exec_flow")->remove_job_with_id($job_id);

            }
            elsif ( $action =~ /^update_job/ ) {
                my ($job_id) = @{$args};
                my $job = $self->master->get_job_from_id($job_id);
                $cluster_ff->get_widget("cluster_exec_flow")->update_job($job)
                    if $job;

            }
            elsif ( $action eq 'update_nodes_list' ) {
                $context->update_object_attr_widgets("cluster.nodes_list");
                $context->update_object_attr_widgets("cluster_node");

            }
            elsif ( $action eq 'no_master_node_found' ) {
                $self->error_window(
                    message => __ "Please configure the master node first",
                );
                my $node_gui = $self->node_gui;
                $node_gui->stop_node_test_progress if $node_gui;
            }
            elsif ( $action eq 'node_test_finished' ) {
                my $node_gui = $self->node_gui;
                $node_gui->node_test_finished if $node_gui;
            }
        }

        1;
    }
}

sub client_server_error {
    my $self = shift;

    return unless $self->master;

    $self->error_window (
        message => __"Connection to master daemon lost!",
    );

    $self->disconnect_master;

    1;
}

sub add_project {
    my $self = shift;
    my %par  = @_;
    my ( $project, $title ) = @par{ 'project', 'title' };

    my $cluster_project = Video::DVDRip::Cluster::Project->new(
        project  => $project,
        title_nr => $title->nr,
    );

    $self->master->add_project( project => $cluster_project, );

    $self->edit_project(
        project    => $cluster_project,
        just_added => 1,
    );

    1;
}

sub edit_project {
    my $self      = shift;
    my %par       = @_;
    my ($project, $just_added) = @par{'project','just_added'};

    $project ||= $self->selected_project;
    return 1 if not $project;

    Video::DVDRip::GUI::Cluster::Title->new(
        cluster_ff => $self->cluster_ff,
        master     => $self->master,
        title      => $project->title,
        just_added => $just_added,
    )->open_window;

    1;
}

sub remove_project {
    my $self = shift;

    my $project = $self->selected_project;
    return if not $project;

    $self->confirm_window(
        message      => __"Do you want to remove the selected project?",
        yes_callback => sub {
            return unless $self->master;
            return if $project->state eq 'running';
            $self->master->remove_project( project => $project );
        },
    );

    1;
}

sub add_node {
    my $self = shift;

    my $node_gui = Video::DVDRip::GUI::Cluster::Node->new(
        cluster_ff => $self->cluster_ff,
        master     => $self->master,
        node       => Video::DVDRip::Cluster::Node->new,
        just_added => 1,
    );

    $node_gui->open_window;

    $self->set_node_gui($node_gui);

    1;
}

sub edit_node {
    my $self = shift;

    my $node = $self->selected_node;
    return 1 if not $node;
    return 1 if $node->state eq 'running';

    my $node_gui = Video::DVDRip::GUI::Cluster::Node->new(
        cluster_ff => $self->cluster_ff,
        master     => $self->master,
        node       => $node,
    );

    $node_gui->open_window;

    $self->set_node_gui($node_gui);

    1;
}

sub stop_node {
    my $self = shift;

    my $node = $self->selected_node;
    return 1 if not $node;
    return 1 if $node->state eq 'stopped';

    $node->stop;

    1;
}

sub start_node {
    my $self = shift;

    my $node = $self->selected_node;
    return 1 if not $node;
    return 1
        if $node->state  ne 'stopped'
        and $node->state ne 'aborted';

    $node->start;

    1;
}

sub remove_node {
    my $self = shift;

    my $node = $self->selected_node;
    return 1 if not $node;
    return 1 if $node->state eq 'running';

    $self->confirm_window(
        message      => __ "Do you want to remove the selected node?",
        yes_callback => sub {
            return unless $self->master;
            $self->master->remove_node( node => $self->selected_node );
        },
    );

    1;
}

sub select_job {
    my $self = shift;
    my ( $widget, $row ) = @_;

    $self->set_selected_job_row($row);
    $self->set_selected_job_id( $self->gtk_widgets->{job_clist_ids}->[$row] );

    1;
}

sub select_node {
    my $self = shift;
    my ( $widget, $row ) = @_;

    $self->set_selected_node_row($row);
    $self->set_selected_node( $self->master->nodes->[$row] );

    1;
}

sub start_project {
    my $self = shift;

    my $project = $self->selected_project;
    return if not $project;
    return if $project->state ne 'not scheduled';

    $self->master->schedule_project( project => $project );

    1;
}

sub cancel_project {
    my $self = shift;

    my $project = $self->selected_project;
    return if not $project;
    return if $project->state ne 'running';

    $self->master->cancel_project( project => $project );

    1;
}

sub restart_project {
    my $self = shift;

    my $project = $self->selected_project;
    return if not $project;

    $self->master->restart_project( project => $project );

    1;
}

sub shutdown_master {
    my $self = shift;

    $self->confirm_window(
        message => __
            "Do you really want to shutdown\nthe Cluster Control Daemon?",
        yes_callback => sub {
            return unless $self->master;
            $self->master->shutdown;
            $self->disconnect_master;
            1;
        },
    );

    1;
}

1;
