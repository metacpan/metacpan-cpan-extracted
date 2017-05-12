# $Id: Node.pm 2304 2007-04-13 11:24:24Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::GUI::Cluster::Node;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::GUI::Base;

use strict;
use Carp;

use FileHandle;

sub master			{ shift->{master}			}
sub node			{ shift->{node}				}
sub cluster_ff			{ shift->{cluster_ff}			}
sub node_ff			{ shift->{node_ff}			}
sub just_added			{ shift->{just_added}			}
sub test_node			{ shift->{test_node}			}
sub node_test_timeout		{ shift->{node_test_timeout}		}

sub set_master			{ shift->{master}		= $_[1] }
sub set_node			{ shift->{node}			= $_[1]	}
sub set_cluster_ff		{ shift->{cluster_ff}		= $_[1]	}
sub set_node_ff			{ shift->{node_ff}		= $_[1]	}
sub set_just_added		{ shift->{just_added}		= $_[1] }
sub set_test_node		{ shift->{test_node}		= $_[1]	}
sub set_node_test_timeout	{ shift->{node_test_timeout}	= $_[1]	}

sub res_ssh_connect		{ shift->{res_ssh_connect}		}
sub res_ssh_connect_details	{ shift->{res_ssh_connect_details}	}
sub res_data_dir		{ shift->{res_data_dir}			}
sub res_data_dir_node		{ shift->{res_data_dir_node}		}
sub res_data_dir_master		{ shift->{res_data_dir_master}		}
sub res_write_access		{ shift->{res_write_access}		}
sub res_write_access_details	{ shift->{res_write_access_details}	}
sub res_transcode		{ shift->{res_transcode}		}
sub res_transcode_node		{ shift->{res_transcode_node}		}
sub res_transcode_master	{ shift->{res_transcode_master}		}

sub set_res_ssh_connect		{ shift->{res_ssh_connect}	= $_[1]	}
sub set_res_ssh_connect_details	{ shift->{res_ssh_connect_details}= $_[1]	}
sub set_res_data_dir		{ shift->{res_data_dir}		= $_[1]	}
sub set_res_data_dir_node	{ shift->{res_data_dir_node}	= $_[1]	}
sub set_res_data_dir_master	{ shift->{res_data_dir_master}	= $_[1]	}
sub set_res_write_access	{ shift->{res_write_access}	= $_[1]	}
sub set_res_write_access_details{ shift->{res_write_access_details}=$_[1]}
sub set_res_transcode		{ shift->{res_transcode}	= $_[1]	}
sub set_res_transcode_node	{ shift->{res_transcode_node}	= $_[1]	}
sub set_res_transcode_master	{ shift->{res_transcode_master}	= $_[1]	}

# GUI Stuff ----------------------------------------------------------

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $master, $cluster_ff, $just_added, $node )
        = @par{ 'master', 'cluster_ff', 'just_added', 'node' };

    my $self = $class->SUPER::new(@_);

    $self->set_form_factory($cluster_ff);
    $self->set_master($master);
    $self->set_node($node);
    $self->set_cluster_ff($cluster_ff);
    $self->set_just_added($just_added);

    $cluster_ff->get_form_factory->get_context->set_object(
        cluster_node_edited => $node, );
    $cluster_ff->get_form_factory->get_context->set_object(
        cluster_node_gui => $self, );

    $self->set_res_ssh_connect( __ "Not tested yet" );
    $self->set_res_data_dir( __ "Not tested yet" );
    $self->set_res_transcode( __ "Not tested yet" );
    $self->set_res_write_access( __ "Not tested yet" );

    return $self;
}

sub open_window {
    my $self = shift;

    my $cluster_gui
        = $self->cluster_ff->get_form_factory->get_context->get_object(
        "cluster_gui");

    my $node_ff = Gtk2::Ex::FormFactory->new(
        parent_ff => $self->cluster_ff,
        context   => $self->cluster_ff->get_context,
        sync      => 1,
        content   => [
            Gtk2::Ex::FormFactory::Window->new(
                title          => __ "dvd::rip - Edit cluster node",
                customize_hook => sub {
                    my ($gtk_window) = @_;
                    $_[0]->parent->set(
                        default_width  => 640,
                        default_height => 500,
                    );
                    1;
                },
                closed_hook => sub {
                    $self->close_window;
                    1;
                },
                properties => { modal => 1, },
                content    => [
                    $self->build_node_form, $self->build_node_test_result,
                    $self->build_buttons
                ],
            ),
        ],
    );

    $node_ff->build;
    $node_ff->show;
    $node_ff->update;

    $self->set_node_ff($node_ff);

    1;
}

sub close_window {
    my $self = shift;

    my $cluster_gui
        = $self->cluster_ff->get_form_factory->get_context->get_object(
        "cluster_gui");

    my $node_ff = $self->node_ff;
    $node_ff->close if $node_ff;
    $self->set_node_ff(undef);
    $self->set_master(undef);
    $cluster_gui->set_node_gui(undef);

    $self->cluster_ff->get_form_factory->get_context->set_object(
        cluster_node_gui => undef, );

    $self->cluster_ff->get_form_factory->get_context->set_object(
        cluster_node_edited => undef, );

    1;
}

sub build_node_form {
    my $self = shift;

    return Gtk2::Ex::FormFactory::Form->new(
        title   => __ "Edit node properties",
        content => [
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_node_edited.name",
                label => __ "Name",
                tip   => "Unique dvd::rip internal name of this node",
                rules => "alphanumeric",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_node_edited.hostname",
                label => __ "Hostname",
                tip   => __
                    "Network hostname of this node. Defaults to node name.",
                rules => sub {
                    $_[0] =~ /^[a-z0-9_.-]+$/i
                        ? undef
                        : __ "No valid hostname";
                }
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_node_edited.data_base_dir",
                label => __ "Local data directory",
                tip   => __ "This is the mount point of the dvd::rip "
                    . "data master directory on this node, e.g. "
                    . "connected via NFS or Samba",
            ),
            Gtk2::Ex::FormFactory::Combo->new(
                attr  => "cluster_node_edited.speed_index",
                label => __ "Speed index",
                tip   => __
                    "Enter an integer value indicating the speed of "
                    . "this node. The higher the value the faster it is. "
                    . "Faster nodes are preferred over slower nodes.",
                presets => [ 100, 90, 80, 70, 60, 50, 40, 30, 20, 10 ],
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_node_edited.tc_options",
                label => __ "Additional transcode options",
                tip   => __
                    "You can specify additional transcode options for this "
                    . "node, e.g. -u 4,2 to increase the performance on a "
                    . "two processor machine",
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr  => "cluster_node_edited.data_is_local",
                label => __ "Node has dvd::rip data harddrive?",
                tip   => __
                    "If this node has the dvd::rip data hardrive locally "
                    . "connected, I/O intensive jobs are executed on this node "
                    . "with higher priority",
                true_label => __"Yes",
                false_label  => __"No",
            ),
            Gtk2::Ex::FormFactory::YesNo->new(
                attr  => "cluster_node_edited.is_master",
                label => __ "Node runs Cluster Control Daemon?",
                tip   => __ "Specify whether on this node runs the cluster "
                    . "control daemon. In that case no ssh remote command "
                    . "execution is neccessary",
                true_label => __"Yes",
                false_label  => __"No",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_node_edited.username",
                label => __ "Username to connect with ssh",
                tip => __ "You need to setup passwordless authorization via "
                    . "~/.ssh/authorized_keys for this user from "
                    . "the master server to the node",
                rules => "alphanumeric",
            ),
            Gtk2::Ex::FormFactory::Entry->new(
                attr  => "cluster_node_edited.ssh_cmd",
                label => __ "SSH command and options",
                tip   => __
                    "Usually you leave this empty (defaults to 'ssh -x'), "
                    . "but if your setup needs special ssh options you may "
                    . "edit them here"
            ),
            Gtk2::Ex::FormFactory::HBox->new(
                content => [
                    Gtk2::Ex::FormFactory::Button->new(
                        name   => "node_test_button",
                        label  => __ "Test settings",
                        stock  => "gtk-network",
                        expand => 0,
                        tip    => __
                            "This triggers a simple test connection to the node, "
                            . "checking file permissions, transcode versions etc.",
                        clicked_hook => sub { $self->node_test },
                    ),
                    Gtk2::Ex::FormFactory::ProgressBar->new(
                        name           => "node_test_progress",
                        expand         => 1,
                        inactive       => "invisible",
                        active_cond    => sub { $self->node_test_timeout },
                        active_depends =>
                            "cluster_node_gui.node_test_timeout",
                    ),
                ],
            ),
        ],
    );
}

sub build_node_test_result {
    return Gtk2::Ex::FormFactory::VBox->new(
        expand  => 1,
        content => [
            Gtk2::Ex::FormFactory::Label->new(
                label => "\n" . __ "Node test results",
                bold  => 1,
            ),
            Gtk2::Ex::FormFactory::Table->new(
                scrollbars => [ "automatic", "automatic" ],
                expand     => 1,
                properties => {
                    column_spacing => 15,
                    row_spacing    => 5,
                    border_width   => 5,
                },
                layout => "
                        +----------------+--------+----------------------------+
                        ' What           ' Status | Details                    |
                        +----------------+--------+----------------------------+
                        | Separator                                            |
                        +----------------+--------+----------------------------+
                        ' SSH Connect    ' Result | Details                    |
                        +----------------+--------+-------------+--------------+
                        ' Data Access    ' Result ' Node dir    ' Master dir   |
                        +----------------+--------+-------------+--------------+
                        ' Write Access   ' Result ' Details                    |
                        +----------------+--------+-------------+--------------+
                        ' transcode      ' Result ' Node tc     ' Master tc    |
                        +----------------+--------+----------------------------+
		    ",
                content => [

                    #-- Header
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "Test",
                        bold  => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "Result",
                        bold  => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "Details",
                        bold  => 1,
                    ),
                    Gtk2::Ex::FormFactory::HSeparator->new,

                    #-- SSH Connection
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "SSH connection",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_ssh_connect",
                        with_markup => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr => "cluster_node_gui.res_ssh_connect_details",
                    ),

                    #-- Data access
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "Data directory",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_data_dir",
                        with_markup => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_data_dir_node",
                        with_markup => 1,
                        properties  => { wrap => 1, },
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_data_dir_master",
                        with_markup => 1,
                        properties  => { wrap => 1, },
                    ),

                    #-- Data access
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "Write access",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_write_access",
                        with_markup => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr => "cluster_node_gui.res_write_access_details",
                        with_markup => 1,
                        properties  => { wrap => 1, },
                    ),

                    #-- transcode version
                    Gtk2::Ex::FormFactory::Label->new(
                        label => __ "Program versions",
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_transcode",
                        with_markup => 1,
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr        => "cluster_node_gui.res_transcode_node",
                        with_markup => 1,
                        properties  => { wrap => 1, },
                    ),
                    Gtk2::Ex::FormFactory::Label->new(
                        attr => "cluster_node_gui.res_transcode_master",
                        with_markup => 1,
                        properties  => { wrap => 1, },
                    ),
                ],
            ),
        ],
    );
}

sub build_buttons {
    my $self = shift;

    return Gtk2::Ex::FormFactory::DialogButtons->new(
        clicked_hook_before => sub {
            my ($button) = @_;
            if ( $button eq 'ok' ) {
                $self->node_ff->apply;
                $self->master->add_node( node => $self->node )
                    if $self->just_added;
                $self->node->save;
                return 1;
            }

            #-- return TRUE to activate Cancel
            #-- Button Default Handler
            1;
        },
    );
}

sub node_test {
    my $self = shift;

    return if $self->node_test_timeout;

    my $context = $self->cluster_ff->get_context;

    # make a backup copy of the node and apply the
    # form values to it
    my $node  = $self->node->clone;
    my $proxy = $context->get_proxy("cluster_node_edited");
    $proxy->{object} = $node;
    $self->node_ff->apply;
    $proxy->{object} = $self->node;

    $self->set_test_node($node);

    my $gtk_progress
        = $self->node_ff->get_widget("node_test_progress")->get_gtk_widget;

    my $timeout = Glib::Timeout->add( 100, sub { $gtk_progress->pulse; 1; } );

    $self->set_node_test_timeout($timeout);

    $context->update_object_attr_widgets(
        "cluster_node_gui.node_test_timeout");

    # trigger test
    $self->master->node_test( node => $node );

    1;
}

sub trunc {
    my ($str) = @_;
    $str =~ s/^\s+//mg;
    $str =~ s/\s+$//;
    return $str;
}

sub stop_node_test_progress {
    my $self = shift;

    my $context = $self->cluster_ff->get_context;

    Glib::Source->remove( $self->node_test_timeout );

    $self->set_node_test_timeout(undef);

    $context->update_object_attr_widgets(
        "cluster_node_gui.node_test_timeout");

    1;
}

sub node_test_finished {
    my $self = shift;

    my $node          = $self->test_node;
    my $node_result   = $node->test_result;
    my $master_node   = $self->master->get_master_node;
    my $master_result = $master_node ? $master_node->test_result : $node_result;
    my $context       = $self->cluster_ff->get_context;
    my $proxy         = $context->get_proxy("cluster_node_gui");

    $self->stop_node_test_progress;

    my $no_details        = __ "No details available";
    my $no_details_no_ssh = __ "Not tested, no SSH connection!";
    my $ok                = "<b>" . __("OK") . "</b>";
    my $not_ok            = "<b>" . __("NOT OK") . "</b>";

    if ( $node_result->{ssh_connect} =~ /Ok/ ) {
        $proxy->set_attrs(
            {   "res_ssh_connect"         => $ok,
                "res_ssh_connect_details" => __ "Master can connect to node"
            }
        );
    }
    else {
        $proxy->set_attrs(
            {   "res_ssh_connect"          => $not_ok,
                "res_ssh_connect_details"  => trunc( $node_result->{output} ),
                "res_data_dir"             => $not_ok,
                "res_data_dir_node"        => $no_details_no_ssh,
                "res_data_dir_master"      => "",
                "res_write_access"         => $not_ok,
                "res_write_access_details" => $no_details_no_ssh,
                "res_transcode"            => $not_ok,
                "res_transcode_node"       => $no_details_no_ssh,
            }
        );
        return;
    }

    my $node_content   = trunc( $node_result->{data_base_dir_content} );
    my $master_content = trunc( $master_result->{data_base_dir_content} );
    if ( $node_content ne $master_content ) {
        if ( $node_content eq '*' ) {
            $node_content = __ "Empty";
        }
        $node_content = "<b><u>"
            . __("Node's data directory")
            . "</u></b>\n"
            . $node_content;
        $master_content = "<b><u>"
            . __("Masters' data directory")
            . "</u></b>\n"
            . $master_content;

        $proxy->set_attrs(
            {   "res_data_dir"        => $not_ok,
                "res_data_dir_node"   => $node_content,
                "res_data_dir_master" => $master_content,
            }
        );
    }
    else {
        $proxy->set_attrs(
            {   "res_data_dir"        => $ok,
                "res_data_dir_node"   => __ "Content of data directory matches",
                "res_data_dir_master" => "",
            }
        );
    }

    my $node_tc   = trunc( $node_result->{program_versions} );
    my $master_tc = trunc( $master_result->{program_versions} );

    if ( $node_tc ne $master_tc ) {
        $node_tc
            = "<b><u>" . __("Node's programs") . "</u></b>\n" . $node_tc;
        $master_tc = "<b><u>"
            . __("Masters's programs")
            . "</u></b>\n"
            . $master_tc;
        $proxy->set_attrs(
            {   "res_transcode"        => $not_ok,
                "res_transcode_node"   => $node_tc,
                "res_transcode_master" => $master_tc
            }
        );
    }
    else {
        $proxy->set_attrs(
            {   "res_transcode"      => $ok,
                "res_transcode_node" => $node_tc
            }
        );
    }

    if ( $node_result->{write_test} =~ /SUCCESS/ ) {
        $proxy->set_attrs(
            {   "res_write_access"         => $ok,
                "res_write_access_details" => __
                    "Node can write to data directory",
            }
        );
    }
    else {
        $proxy->set_attrs(
            {   "res_write_access"         => $not_ok,
                "res_write_access_details" =>
                    trunc( $node_result->{write_test} ),
            }
        );
    }

    1;
}

sub add_line_to_text_view {
    my $self = shift;
    my %par  = @_;
    my ( $line, $text_widget ) = @par{ 'line', 'text_widget' };

    my $buffer = $text_widget->get("buffer");
    my $iter   = $buffer->get_end_iter;
    $buffer->insert( $iter, $line );

    1;
}

sub test_node_show_result {
    my $self = shift;
    my %par  = @_;
    my ( $node, $test_file, $text_widget )
        = @par{ 'node', 'test_file', 'text_widget' };

    my $result = $node->test_result;

    #---------------------------------------------------------------
    # $result is a scalar containing a fatal error message, or
    # a hash reference with the following keys:
    #
    #   data_base_dir_content   sorted content of the data_base_dir,
    #			    or error message
    #   write_test		    SUCCESS if write was succesfull,
    #			    or error message otherwise
    #   program_versions       full output of program version numbers
    #---------------------------------------------------------------

    if ( not ref $result ) {
        $self->add_line_to_text_view(
            text_widget => $text_widget,
            line        => __("Can't execute tests:") . "\n\n" . $result
        );
        unlink $test_file;
        return 1;
    }

    # now execute the test command on this machine
    my $base_project_dir = $self->config('base_project_dir');
    my $local_command
        = $node->get_test_command( data_base_dir => $base_project_dir );

    my $local_output = qx[ ($local_command) 2>&1 ];

    my $local_result = $node->parse_test_output( output => $local_output );

    # remove test file
    unlink $test_file;

    # check if results are equal
    my $report;
    my $details;

    my %desc = (
        ssh_connect           => __"ssh connect",
        data_base_dir_content => __"Content of project base directory",
        write_test            => __"Project base directory writable",
        program_versions      => __"transcode version match",
    );

    foreach my $case (
        qw ( ssh_connect data_base_dir_content write_test program_versions ))
    {
        $report .= "Test case : $desc{$case}\n";
        $report .= "Result    : ";

        if ( $result->{$case} eq $local_result->{$case} ) {
            $report .= "Ok\n\n";
        }
        else {
            $report  .= "Not Ok!\n\n";
            $details .= "Test case    : $desc{$case}\n";
            if ( $case eq 'ssh_connect' ) {
                $details .= "Node output  :\n$result->{output}\n\n";
                last;
            }
            else {
                $details .= "Node output  :\n$result->{$case}\n\n";
            }
            $details .= "Local output :\n$local_result->{$case}\n\n";
        }
    }

    $self->add_line_to_text_view(
        text_widget => $text_widget,
        line        => __("All tests successful") . "\n\n"
        )
        unless $details;

    $self->add_line_to_text_view(
        text_widget => $text_widget,
        line        => __("Brief report") . ":\n\n" . $report
        )
        unless $details;

    if ($details) {
        if ( $result->{output_rest} =~ /\S/ ) {
            $details .= "Unrecognized output :\n$result->{output_rest}\n\n";
        }
        $self->add_line_to_text_view(
            text_widget => $text_widget,
            line        => __("Detailed report") . ":\n\n" . $details
        );
    }

    1;
}

1;
