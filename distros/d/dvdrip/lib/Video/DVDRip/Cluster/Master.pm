# $Id: Master.pm 2322 2007-08-05 16:56:51Z joern $
#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Master;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Event;
use constant NICE => -1;

use Video::DVDRip::Cluster::Node;
use Video::DVDRip::Cluster::Project;
use Video::DVDRip::Cluster::Pipe;
use Video::DVDRip::Cluster::Scheduler;

use Carp;
use strict;

use FileHandle;
use Data::Dumper;

sub config_filename             { shift->{config_filename}              }
sub data_dir                    { shift->{data_dir}                     }
sub node_dir                    { shift->{node_dir}                     }
sub project_dir                 { shift->{project_dir}                  }
sub nodes                       { shift->{nodes}                        }
sub projects                    { shift->{projects}                     }
sub job_id                      { shift->{job_id}                       }
sub project_id                  { shift->{project_id}                   }
sub in_job_control              { shift->{in_job_control}               }
sub node_check_watcher          { shift->{node_check_watcher}           }
sub rpc_server                  { shift->{rpc_server}                   }
sub scheduler                   { shift->{scheduler}                    }

sub set_config_filename         { shift->{config_filename}      = $_[1] }
sub set_data_dir                { shift->{data_dir}             = $_[1] }
sub set_node_dir                { shift->{node_dir}             = $_[1] }
sub set_project_dir             { shift->{project_dir}          = $_[1] }
sub set_nodes                   { shift->{nodes}                = $_[1] }
sub set_projects                { shift->{projects}             = $_[1] }
sub set_job_id                  { shift->{job_id}               = $_[1] }
sub set_project_id              { shift->{project_id}           = $_[1] }
sub set_in_job_control          { shift->{in_job_control}       = $_[1] }
sub set_node_check_watcher      { shift->{node_check_watcher}   = $_[1] }
sub set_rpc_server              { shift->{rpc_server}           = $_[1] }
sub set_scheduler               { shift->{scheduler}            = $_[1] }

my $MASTER_OBJECT;
sub get_master { $MASTER_OBJECT }

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $logger, $rpc_server ) = @par{ 'logger', 'rpc_server' };

    my $self = bless {
        data_dir        => $ENV{HOME} . "/.dvdrip-master",
        node_dir        => $ENV{HOME} . "/.dvdrip-master/nodes",
        project_dir     => $ENV{HOME} . "/.dvdrip-master/projects",
        config_filename => $ENV{HOME} . "/.dvdrip-master/master.conf",
        nodes           => [],
        projects        => [],
        job_id          => 0,
        logger          => $logger,
        rpc_server      => $rpc_server,
        scheduler       => Video::DVDRip::Cluster::Scheduler->new(),
    }, $class;

    $MASTER_OBJECT = $self;

    $self->set_logger($logger);

    if ( not -d $self->data_dir ) {
        mkdir( $self->data_dir, 0755 )
            or croak "can't create directory '" . $self->data_dir . "'";

    }

    if ( not -d $self->node_dir ) {
        mkdir( $self->node_dir, 0755 )
            or croak "can't create directory '" . $self->node_dir . "'";

    }

    if ( not -d $self->project_dir ) {
        mkdir( $self->project_dir, 0755 )
            or croak "can't create directory '" . $self->project_dir . "'";

    }

    $self->log( __ "Master daemon activated" );

    $self->load;

    $self->enable_node_check
        unless $self->node_check_unnecessary;

    foreach my $signal ( "INT", "HUP", "TERM" ) {
	    Event->signal (
		    signal => $signal,
		    cb     => sub {
                        $self->log(
                            __x("Got signal {signal}.",
                                signal => $signal)
                        );
                        $self->shutdown("now");
                    },
	    );
    }

    return $self;
}

my $FPING;
sub check_prerequisites {
    my $class = shift;

    foreach my $path ( "/usr/bin", "/usr/sbin" ) {
        if ( -f "$path/fping" and -x "$path/fping" ) {
            $FPING = "$path/fping";
            last;
        }
    }

    if ( !$FPING ) {
        croak "can't find a executable fping in /usr/bin and /usr/sbin";
    }

    my ( $mode, $uid ) = ( stat($FPING) )[ 2, 4 ];
    my $suid = $mode & 04000;

    croak "$FPING is not suid root"
        if not $suid or $uid != 0;

    1;
}

sub node_check_unnecessary {
    my $self = shift;
    return;
    return if $self->rpc_server->get_clients_connected;
    return if @{ $self->job_get_unfinished_projects };
    return 1;
}

sub enable_node_check {
    my $self = shift;

    return if $self->node_check_watcher;

    $self->node_check;

    my $watcher = Event->timer(
        interval => 5,
        cb       => sub { $self->node_check },
        desc     => "node check timer"
    );

    $self->log("Node check watcher enabled");

    $self->set_node_check_watcher($watcher);

    1;
}

sub disable_node_check {
    my $self = shift;

    return if not $self->node_check_watcher;

    $self->node_check_watcher->cancel;
    $self->set_node_check_watcher(undef);

    $self->log( __ "Node check watcher disabled" );

    1;
}

sub node_check {
    my $self = shift;

    my $nodes_list;
    foreach my $node ( @{ $self->nodes } ) {
        $nodes_list .= $node->hostname . " "
            if $node->state ne 'stopped'
            and not $node->is_master;
    }

    return 1 if not $nodes_list;

    my $command = "$FPING $nodes_list";

    my $buffer;

    Video::DVDRip::Cluster::Pipe->new(
        timeout      => 8,
        command      => $command,
        no_log       => 1,
        cb_line_read => sub {
            $self->log(4, "fping: $_[0]");
            $buffer .= $_[0] . "\n";
            1;
        },
        cb_finished => sub {
            if ( $buffer =~ /^\s*$/ ) {
                $self->log( __ "Warning: node check fping reported nothing" );
                return;
            }
            my $node_name;
            my $idle_nodes;
            foreach my $node ( @{ $self->nodes } ) {
                next if $node->state eq 'stopped';
                if ( $node->is_master ) {
                    ++$idle_nodes if $node->state eq 'idle';
                    next;
                }

                $node_name = $node->hostname;
                if ( $buffer =~ /^$node_name\s+is\s+alive/m ) {
                    if ( not $node->alive and $node->answered_last_ping == 2 )
                    {
                        $self->log(
                            __x("Node '{node_name}' is now online.",
                                node_name => $node_name
                            )
                        );
                        $node->set_alive(1);
                    }
                    if ( not $node->alive and $node->answered_last_ping == 1 )
                    {
                        $self->log(
                            __x("Node '{node_name}' is still reachable. Will be online in 5 seconds.",
                                node_name => $node_name
                            )
                        );
                        $node->set_answered_last_ping(2);
                    }
                    if ( not $node->alive and not $node->answered_last_ping )
                    {
                        $self->log(
                            __x("Node '{node_name}' is now reachable. Will be online in 10 seconds.",
                                node_name => $node_name
                            )
                        );
                        $node->set_answered_last_ping(1);
                    }
                    if ( $node->alive == 0.5 ) {
                        $self->log(
                            __x("Node '{node_name}' is Ok again",
                                node_name => $node_name
                            )
                        );
                        $node->set_alive(1);
                    }
                }
                else {
                    $node->set_answered_last_ping(0);
                    if ( $node->alive == 0.5 ) {
                        $self->log(
                            __x("Warning: Node '{node_name}' is unreachable",
                                node_name => $node_name
                            )
                            )
                            if $node->alive
                            or $node->state eq 'unknown';
                        $node->set_alive(0);
                    }
                    elsif ( $node->alive ) {
                        $self->log(
                            __x("Warning: Node '{node_name}' possibly offline",
                                node_name => $node_name
                            )
                        );
                        $node->set_alive(0.5);
                    }
                    else {
                        $node->set_alive(0);
                    }
                }
                ++$idle_nodes if $node->state eq 'idle';
            }

            $self->disable_node_check
                if $self->node_check_unnecessary;

            $self->job_control
                if $idle_nodes
                and not $self->in_job_control;
        },
    )->open;

    1;
}

sub hello {
    my $self = shift;

    $self->enable_node_check;

    1;
}

sub load {
    my $self = shift;

    my $filename = $self->config_filename;
    if ( not -f $filename ) {
        $self->save;
    }

    my $fh = FileHandle->new;
    open( $fh, $filename )
        or croak "can't read master config file '$filename'";
    my $data_blob = join( '', <$fh> );
    close $fh;

    my $data;
    $data = eval $data_blob;
    croak "Error loading master config file '$filename': $@" if $@;

    $self->set_job_id( $data->{job_id} );
    $self->set_project_id( $data->{project_id} );

    $self->load_nodes;
    $self->load_projects( project_order => $data->{project_order} );

    1;
}

sub save {
    my $self = shift;

    my $filename = $self->config_filename;

    my @project_order = map { $_->filename } @{ $self->projects };

    my $data = {
        job_id        => $self->job_id,
        project_id    => $self->project_id,
        project_order => \@project_order,
    };

    my $dd = Data::Dumper->new( [$data], ['data'] );
    $dd->Indent(1);
    my $data_blob = $dd->Dump;

    my $fh = FileHandle->new;
    open( $fh, "> $filename" )
        or croak "can't write master config file '$filename'";
    print $fh $data_blob;
    close $fh;

    1;
}

sub load_nodes {
    my $self = shift;

    my $dir = $self->node_dir;

    my @nodes;
    foreach my $file (<$dir/*>) {
        $self->log( __x( "Loading node file '{file}'", file => $file ) );
        my $node
            = Video::DVDRip::Cluster::Node->new_from_file( filename => $file,
            );
        $node->reset;
        push @nodes, $node;
    }

    $self->set_nodes( \@nodes );

    1;
}

sub load_projects {
    my $self = shift;
    my %par = @_;
    my ($project_order) = @par{'project_order'};

    my $dir = $self->project_dir;

    my @projects;
    foreach my $filename ( @{$project_order} ) {
        next if not -r $filename;
        $self->log(
            __x( "Loading project file '{filename}'", filename => $filename )
        );
        my $project = Video::DVDRip::Cluster::Project->new_from_file(
            filename => $filename, );
        push @projects, $project;
    }

    $self->set_projects( \@projects );

    $self->scheduler->init;

    1;
}

sub emit_event {
    my $self = shift;
    my ($event, @args) = @_;

    my $rpc_server  = $self->rpc_server;
    my $log_clients = $rpc_server->get_logging_clients;

    my $sock;
    foreach my $client ( values %{$log_clients} ) {
        $sock = $client->get_sock;
        print $sock "EVENT\t$event\t" . join( "\t", @args ) . "\n";
    }

    1;
}

sub add_node {
    my $self = shift;
    my %par = @_;
    my ($node) = @par{'node'};

    my $filename = $self->node_dir . '/' . $node->name . '.node';

    croak "msg: " . __ "Node must have a name" if $node->name eq '';
    croak "msg: " . __ "Node with this name already exists" if -f $filename;

    $node->set_state("idle") if $node->is_master;

    push @{ $self->nodes }, $node;
    $node->set_filename($filename);
    $node->save;

    $self->log(
        __x("Node '{node_name}' saved to '{filename}'",
            node_name => $node->name,
            filename  => $filename
        )
    );

    1;
}

sub remove_node {
    my $self = shift;
    my %par = @_;
    my ($node) = @par{'node'};

    my $i = 0;
    foreach my $n ( @{ $self->nodes } ) {
        last if $n == $node;
        ++$i;
    }

    croak "Unknown node $node" if $i == @{ $self->nodes };

    unlink $node->filename;

    splice @{ $self->nodes }, $i, 1;

    $self->emit_event( "NODE_DELETED", $node->name );

    1;
}

sub get_project_index {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    my $projects = $self->projects;

    my $i = 0;
    foreach my $p ( @{$projects} ) {
        last if $p == $project;
        ++$i;
    }

    croak "Unknown project $project" if $i == @{$projects};

    return $i;
}

sub project_by_id {
    my $self = shift;
    my %par = @_;
    my ($id) = @par{'id'};

    my $p;
    foreach $p ( @{ $self->projects } ) {
        return $p if $p->id == $id;
    }

    croak "Unknown project id $id";
}

sub add_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    push @{ $self->projects }, $project;

    my $job_id   = $self->set_project_id( 1 + $self->project_id );
    my $filename = sprintf( "%s/%08d-%s.rip",
        $self->project_dir, $job_id, $project->name );

    $project->set_filename($filename);
    $project->set_state('not scheduled');
    $project->set_id($job_id);

    # save changes to project
    $project->save;

    $self->log(
        __x("Project with filename '{filename}' added",
            filename => $filename
        )
    );

    # save new state
    $self->save;

    $self->emit_event( "PROJECT_UPDATE", $project->id );

    1;
}

sub move_up_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    my $i = $self->get_project_index( project => $project );

    # already on top?
    return if $i == 0;

    # move project up
    my $projects = $self->projects;
    @{$projects}[ $i, $i - 1 ] = @{$projects}[ $i - 1, $i ];

    # save new state
    $self->save;

    $self->emit_event("PROJECT_LIST_UPDATE");

    1;
}

sub move_down_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    my $i = $self->get_project_index( project => $project );

    # already on bottom?
    my $projects = $self->projects;
    return if $i == @{$projects} - 1;

    # move project up
    @{$projects}[ $i, $i + 1 ] = @{$projects}[ $i + 1, $i ];

    # save new state
    $self->save;

    $self->emit_event("PROJECT_LIST_UPDATE");

    1;
}

sub schedule_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    # check for existence
    $self->get_project_index( project => $project );

    # create job plan
    $project->create_job_plan;

    # change project state
    $project->set_state('waiting');
    $self->scheduler->add_project($project);

    # save project's state
    $project->save;

    # emit update events to connected GUI clients
    $self->emit_event("PROJECT_LIST_UPDATE");

    # maybe the job controller can dispose some work now...
    $self->job_control;

    1;
}

sub cancel_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    return if $project->state ne 'running';
    
    $self->scheduler->cancel_project($project);

    # emit update events to connected GUI clients
    $self->emit_event("PROJECT_LIST_UPDATE");
    1;
}

sub restart_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    return if $project->state ne 'cancelled' &&
              $project->state ne 'error';
    
    $self->scheduler->restart_project($project);

    $self->emit_event("PROJECT_LIST_UPDATE");

    $self->scheduler->run;

    1;
}

sub remove_project {
    my $self = shift;
    my %par = @_;
    my ($project) = @par{'project'};

    # check for existence
    my $i = $self->get_project_index( project => $project );

    # check project state
    return if $project->state eq 'running';

    unlink $project->filename;
    splice @{ $self->projects }, $i, 1;

    $self->scheduler->remove_project($project)
        if $project->state ne 'not scheduled';

    $self->log(
        __x( "Project {project} removed", project => $project->label ) );

    $self->emit_event( "PROJECT_DELETED", $project->id );

    1;
}

sub projects_list {
    my $self = shift;

    my $nr;
    my @projects;
    foreach my $project ( @{ $self->projects } ) {
        push @projects,
            [
            $project->id,    ++$nr, $project->label,
            $project->state, $project->progress,
            ];
    }

    return \@projects;
}

sub jobs_list {
    my $self = shift;
    my %par = @_;
    my ($project_id) = @par{'project_id'};

    my $project = $self->project_by_id( id => $project_id );

    return $project->jobs_list;
}

sub nodes_list {
    my $self = shift;

    my $nr;
    my @nodes;
    foreach my $node ( @{ $self->nodes } ) {
        push @nodes,
            [
            $node->name,
            ++$nr,
            $node->name,
            ( $node->assigned_job ? $node->assigned_job->get_info : undef ),
            (     $node->assigned_job
                ? $node->assigned_job->get_progress_stats
                : $node->state
            ),
            ];
    }

    return \@nodes;
}

sub job_control {
    my $self = shift;

    $self->scheduler->run;

    1;
}

sub job_get_unfinished_projects {
    my $self = shift;

    my @projects;

    foreach my $project ( @{ $self->projects } ) {
        push @projects, $project
            if $project->state eq 'waiting'
            or $project->state eq 'running';
    }

    $self->enable_node_check if @projects;

    return \@projects;
}

sub shutdown {
    my $self = shift;
    my ($now) = @_;

    my $exec_flow_group = $self->scheduler->get_exec_flow_group;
    
    if ( $exec_flow_group->get_state eq 'running' ) {
        $self->log( __"Master shutdown. Stopping active jobs." );
        $exec_flow_group->cancel;
    }
    else {
        $self->log( __"Master shutdown" );
        Event::unloop_all();
        return;
    }

    Event->timer(
        interval => 2,
        cb       => sub { Event::unloop_all() },
        desc     => "dvd::rip shutdown timer"
    );

    $self->log( __ "Cluster control daemon will shutdown in 2 seconds..." );

    1;

}

sub get_online_nodes_cnt {
    my $self = shift;

    my $cnt = 0;
    foreach my $node ( @{ $self->nodes } ) {
        ++$cnt
            if $node->state  ne 'unknown'
            and $node->state ne 'offline';
    }

    return $cnt;
}

sub get_node_by_name {
    my $self = shift;
    my ($name) = @_;
    foreach my $node ( @{ $self->nodes } ) {
        return $node if $node->name eq $name;
    }
    return;
}

sub get_project_by_id {
    my $self = shift;
    my ($id) = @_;
    foreach my $project ( @{ $self->projects } ) {
        return $project if $project->id eq $id;
    }
    return;
}

sub get_master_node {
    my $self = shift;

    foreach my $node ( @{ $self->nodes } ) {
        return $node if $node->is_master;
    }

    return;
}

sub node_test {
    my $self   = shift;
    my %par    = @_;
    my ($node) = @par{'node'};

    my $master_node = $self->get_master_node;

    if ( $master_node ) {
print "RUN MASTER TESTS\n";
        $master_node->run_tests(
            cb_finished => sub {
print "RUN NODE TESTS\n";
                $node->run_tests(
                    cb_finished => sub {
                        $self->emit_event( "NODE_TEST_FINISHED", $node->name );
                    },
                );
            },
        );
    }
    else {
        $node->run_tests(
            cb_finished => sub {
                $self->emit_event( "NODE_TEST_FINISHED", $node->name );
            },
        );
    }
    
    1;
}

sub exec_flow_job {
    my $self = shift;
    
    return $self->scheduler->get_exec_flow_group;
}

sub get_job_from_id {
    my $self = shift;
    my ($job_id) = @_;
    return $self->scheduler->get_jobs_by_id->{$job_id};
}

sub reset_job {
    my $self = shift;
    my ($job_id) = @_;

    my $job = $self->get_job_from_id($job_id);

    $job->reset;

    my $project = $self->scheduler->get_projects_by_job_id->{$job_id};
    $project->set_state("not scheduled");
    $project->save;

    1;
}

1;
