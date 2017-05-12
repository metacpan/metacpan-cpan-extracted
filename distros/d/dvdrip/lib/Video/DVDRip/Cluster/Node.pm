# $Id: Node.pm 2369 2009-02-22 18:27:33Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This program is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Node;
use Locale::TextDomain qw (video.dvdrip);

use base Video::DVDRip::Base;

use Carp;
use strict;

use FileHandle;
use Data::Dumper;
use Scalar::Util;

sub state                       { shift->{state}                        }
sub filename                    { shift->{filename}                     }
sub name                        { shift->{name}                         }
sub hostname                    { my $s = shift; $s->{hostname} || $s->{name} }
sub data_base_dir               { shift->{data_base_dir}                }
sub is_master                   { shift->{is_master}                    }
sub data_is_local               { shift->{data_is_local}                }
sub username                    { shift->{username}                     }
sub ssh_cmd                     { shift->{ssh_cmd}                      }
sub speed                       { shift->{speed}                        }
sub tc_options                  { shift->{tc_options}                   }
sub answered_last_ping          { shift->{answered_last_ping}           }
sub speed_index                 { shift->{speed_index}                  }

sub progress_cnt                { shift->{progress_cnt}                 }
sub progress_max                { shift->{progress_max}                 }
sub progress_merge              { shift->{progress_merge}               }
sub progress_start_time         { shift->{progress_start_time}          }
sub assigned_job                { shift->{assigned_job}                 }
sub assigned_chunk              { shift->{assigned_chunk}               }

sub set_state {
    my $self = shift, my ($state) = @_;

    $self->{state} = $state;

    Video::DVDRip::Cluster::Master->get_master->emit_event( "NODE_UPDATE",
        $self->name );

    return $state;
}

sub set_filename                { shift->{filename}             = $_[1] }
sub set_name                    { shift->{name}                 = $_[1] }
sub set_hostname                { shift->{hostname}             = $_[1] }
sub set_data_base_dir           { shift->{data_base_dir}        = $_[1] }
sub set_is_master               { shift->{is_master}            = $_[1] }
sub set_data_is_local           { shift->{data_is_local}        = $_[1] }
sub set_username                { shift->{username}             = $_[1] }
sub set_ssh_cmd                 { shift->{ssh_cmd}              = $_[1] }
sub set_speed                   { shift->{speed}                = $_[1] }
sub set_tc_options              { shift->{tc_options}           = $_[1] }
sub set_answered_last_ping      { shift->{answered_last_ping}   = $_[1] }
sub set_speed_index             { shift->{speed_index}          = $_[1] }

sub set_progress_cnt            { shift->{progress_cnt}         = $_[1] }
sub set_progress_max            { shift->{progress_max}         = $_[1] }
sub set_progress_merge          { shift->{progress_merge}       = $_[1] }
sub set_progress_start_time     { shift->{progress_start_time}  = $_[1] }
sub set_assigned_job            {
    my $self = shift;
    my ($job) = @_;
    $self->{assigned_job} = $job;
    Scalar::Util::weaken($self->{assigned_job});
    return $job;
}
sub set_assigned_chunk          { shift->{assigned_chunk}       = $_[1] }

sub test_finished               { shift->{test_finished}                }
sub test_result                 { shift->{test_result}                  }

sub set_test_finished           { shift->{test_finished}        = $_[1] }
sub set_test_result             { shift->{test_result}          = $_[1] }

sub alive { shift->{alive} }

sub set_alive {
    my $self = shift;
    my ($alive) = @_;

    my $was_alive = $self->alive;

    $self->{alive} = $alive;

    if ( not $alive ) {
        $self->stop if $was_alive;
        $self->set_state("offline");
        $self->save;

    }
    elsif ($self->state eq "offline"
        or $self->state eq "unknown" ) {
        $self->set_state("idle");
        $self->save;
    }

    1;
}

sub project_name {
    my $self = shift;
    my $job  = $self->assigned_job;
    return "" if not $job;
    return $job->project->label;
}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $name, $hostname, $data_base_dir )
        = @par{ 'name', 'hostname', 'data_base_dir' };

    my ( $is_master, $username, $tc_options )
        = @par{ 'is_master', 'username', 'tc_options' };

    my $self = {
        name          => $name,
        hostname      => $hostname,
        data_base_dir => $data_base_dir,
        is_master     => $is_master,
        username      => $username,
        tc_options    => $tc_options,
        alive         => $is_master,
    };

    bless $self, $class;

    if ($is_master) {
        $self->set_state("idle");
    }
    else {
        $self->set_state("unknown");
    }

    return $self;
}

sub new_from_file {
    my $class      = shift;
    my %par        = @_;
    my ($filename) = @par{'filename'};

    confess "missing filename" if not $filename;

    my $self = bless { filename => $filename, }, $class;

    $self->load;

    $self->set_filename($filename);

    return $self;
}

sub load {
    my $self = shift;

    my $filename = $self->filename;
    croak "no filename set"      if not $filename;
    croak "can't read $filename" if not -r $filename;

    my $fh = FileHandle->new;
    open( $fh, $filename ) or croak "can't read $filename";
    my $data_blob = join( '', <$fh> );
    close $fh;

    my $data;
    $data = eval($data_blob);
    croak "can't load $filename. Perl error: $@" if $@;

    %{$self} = %{$data};

    1;
}

sub save {
    my $self = shift;

    my $filename = $self->filename;
    confess "not filename set" if not $filename;

    my $assigned_job = $self->assigned_job;
    my $test_result  = $self->test_result;
    $self->set_assigned_job(undef);
    $self->set_test_result(undef);

    my $dd = Data::Dumper->new( [$self], ['data'] );
    $dd->Indent(1);
    my $data = $dd->Dump;

    $self->set_assigned_job($assigned_job);
    $self->set_test_result($test_result);

    my $fh = FileHandle->new;

    open( $fh, "> $filename" ) or confess "can't write $filename";
    print $fh $data;
    close $fh;

    Video::DVDRip::Cluster::Master->get_master->emit_event( "NODE_UPDATE",
        $self->name );

    1;
}

sub prepare_command {
    my $self = shift;
    my ($command, $job) = @_;

    if ( $job ) {
        my %params = (
            DVDRIP_NODE_DATA_BASE_DIR   => $self->data_base_dir,
            DVDRIP_NODE_NAME            => $self->name,
            DVDRIP_JOB_PSU              => sprintf("%02d",$job->get_stash->{psu}+0),
            DVDRIP_JOB_ADD_ONE_PSU      => sprintf("%02d",$job->get_stash->{psu}+1),
            DVDRIP_JOB_CHUNK            => sprintf("%05d",$job->get_stash->{chunk}),
            DVDRIP_JOB_AVI_NR           => sprintf("%02d",$job->get_stash->{avi_nr}),
            DVDRIP_JOB_CHUNK_CNT        => $job->get_stash->{chunk_cnt},
        );
        $command =~ s/(DVDRIP_[A-Z_]+)/$params{$1}/eg;
    }

    if ( $self->is_master ) {
        $command = "execflow $command" unless $command =~ /execflow/;
        $command = "umask 0002; $command";
        return $command;
    }

    $command = "umask 0002; $command";

    warn "Node's transcode options currently ignored" if $self->tc_options;

    #-- Set LD_ASSUME_KERNEL on the nodes as well,
    #-- if set on the master.
    $command = "export LD_ASSUME_KERNEL=$ENV{LD_ASSUME_KERNEL}; $command"
        if $ENV{LD_ASSUME_KERNEL};

    my $username = $self->username;
    my $name     = $self->hostname;
    my $ssh_cmd  = $self->ssh_cmd || 'ssh';

    $ssh_cmd .= " -o PreferredAuthentications=publickey";

    $command =~ s/execflow/`which nice`/g;
    $command =~ s/"/\\"/g;
    $command = qq{execflow $ssh_cmd $username\@$name "$command"};

    return $command;
}

sub reset {
    my $self = shift;

    my $startup_state = $self->state;

    $self->set_alive(0);
    $self->set_state($startup_state);
    $self->set_answered_last_ping(0);
    $self->set_state( $self->is_master ? 'idle' : 'unknown' )
        if $startup_state  ne 'stopped'
        and $startup_state ne 'aborted';
    $self->save;

    1;
}

sub progress {
    my $self = shift;
    return "" if not $self->assigned_job;
    return $self->assigned_job->get_progress_text;
}

sub stop {
    my $self = shift;

    my $job = $self->assigned_job;

    $self->set_state('stopped');
    $self->log( __x( "Node '{node}' stopped", node => $self->name ) );
    $self->save;

    $job->cancel if $job;

    1;
}

sub start {
    my $self = shift;

    croak "Can't start a non stopped node"
        if $self->state  ne 'stopped'
        and $self->state ne 'aborted';

    $self->log( __x( "Node '{node}' started", node => $self->name ) );

    $self->set_alive(0);
    $self->set_state( $self->is_master ? 'idle' : 'unknown' );
    $self->set_answered_last_ping(1);
    $self->save;

    Video::DVDRip::Cluster::Master->get_master->node_check;
    Video::DVDRip::Cluster::Master->get_master->job_control;

    1;
}

sub job_info {
    my $self = shift;

    my $job = $self->assigned_job;

    my $info;
    if ( not $job ) {
        $info = $self->state;
    }
    else {
        $info = $job->nr . ": " . $job->project->label . ": " . $job->info;
    }

    return $info;
}

sub run_tests {
    my $self          = shift;
    my %par           = @_;
    my ($cb_finished) = @par{'cb_finished'};

    # First reset the finished flag
    $self->set_test_finished(0);

    # get test command for this node
    my $command = $self->get_test_command;

    my $popen_command = $self->prepare_command($command);

    my $output = "";
    Video::DVDRip::Cluster::Pipe->new(
        command      => $popen_command,
        timeout      => 5,
        cb_line_read => sub { $output .= $_[0] . "\n" },
        cb_finished => sub {
            $self->log(
                __x( "Node {name} finished tests", name => $self->name ) );
            $self->set_test_result(
                $self->parse_test_output( output => $output ) );
            $self->set_test_finished(1);
            &$cb_finished() if $cb_finished;
        }
    )->open;

    1;
}

sub get_test_command {
    my $self = shift;

    my $data_base_dir = $self->data_base_dir;

    my $command          = "sh -c 'export LC_ALL=C; ";
    my $create_test_file =
        $self->is_master
        ? "touch $data_base_dir/00DVDRIP-CLUSTER; "
        : "";

    # 1. confirm ssh connection
    $command
        .= "echo --ssh_connect--; " . "echo Ok; " . "echo --ssh_connect--;";

    # 2. get content of data_base_dir
    $command .= "echo --data_base_dir_content--; "
        . $create_test_file
        . "cd $data_base_dir && echo * | perl -pe \"s/ /chr(10)/eg\" | sort;"
        . "echo --data_base_dir_content--; ";

    # 3. try writing in the data_base_dir
    my $test_file = "$data_base_dir/" . $self->name . "-file-write-test";
    $command .= "echo --write_test--; "
        . "echo node write test > $test_file && echo SUCCESS; "
        . "rm -f $test_file; "
        . "echo --write_test--; ";

    # 4. program versions
    my $depend = $self->depend_object;
    
    $command .= "echo --program_versions--; ";
    foreach my $tool ( sort keys %{$depend->tools} ) {
        my $def = $depend->tools->{$tool};
        next if not $def->{cluster};
        $command .= $def->{version_cmd}." 2>&1;";
    }
    $command .= "echo --program_versions--; ";
    $command .= "' 2>&1";

    return $command;
}

sub parse_test_output {
    my $self     = shift;
    my %par      = @_;
    my ($output) = @par{'output'};

    # parse output
    my %result;
    $result{output} = $output;
    foreach my $case (
        qw ( ssh_connect data_base_dir_content
             write_test program_versions ) ) {
        $output =~ s/--$case--\n(.*?)--$case--//s;
        $result{$case} = $1;
    }

    $result{output_rest} = $output;

    return \%result;
}

1;
