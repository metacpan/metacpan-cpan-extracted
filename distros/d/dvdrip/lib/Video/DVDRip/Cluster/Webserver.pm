# $Id: Webserver.pm 2187 2006-08-16 19:34:38Z joern $

#-----------------------------------------------------------------------
# Copyright (C) 2001-2006 Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
#
# This module is part of Video::DVDRip, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Video::DVDRip::Cluster::Webserver;
use Locale::TextDomain qw (video.dvdrip);

use base qw ( Video::DVDRip::Base );

# use strict;

use Time::Local;
use Symbol;
use Socket;
use FileHandle;

sub port			{ shift->{port}				}
sub master			{ shift->{master}			}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $port, $master ) = @par{ 'port', 'master' };

    $port ||= 8888;

    my $self = bless {
        port   => $port,
        master => $master,
    }, $class;

    $self->log("Cluster webserver started on TCP port $port");
    $self->setup_http_listener;

    return $self;
}

sub setup_http_listener {
    my $self = shift;

    my $proto = getprotobyname('tcp');
    my $sock  = gensym;
    my $port  = $self->port;

    socket( $sock, PF_INET, SOCK_STREAM, $proto )
        or die "socket: $!";
    setsockopt( $sock, SOL_SOCKET, SO_REUSEADDR, pack( 'l', 1 ) )
        or die "setsockopt: $!";
    bind( $sock, sockaddr_in( $port, INADDR_ANY ) )
        or die "bind: $!";
    listen( $sock, SOMAXCONN );

    Event->io(
        fd   => $sock,
        poll => 'r',
        nice => -1,
        cb   => [ $self, 'new_http_client' ],
        desc => "http listener $port"
    );

    1;
}

sub new_http_client {
    my $self = shift;
    my ($e) = @_;

    my $sock = FileHandle->new;
    my $paddr = accept $sock, $e->w->fd or die "accept: $!";
    my ( $port, $iaddr ) = sockaddr_in($paddr);

    select $sock;
    $| = 1;
    select STDOUT;

    $self->log("HTTP client request");

    Video::DVDRip::Cluster::Webserver::Client->new(
        sock      => $sock,
        webserver => $self,
    );

    1;
}

package Video::DVDRip::Cluster::Webserver::Client;
use Locale::TextDomain qw (video.dvdrip);

use FileHandle;
use constant NICE => -1;

use base Video::DVDRip::Base;

sub webserver			{ shift->{webserver}			}

sub get_fd			{ shift->{fd}				}
sub get_request			{ shift->{request}			}
sub get_ip			{ shift->{ip}				}
sub get_event			{ shift->{event}			}

sub set_fd			{ shift->{fd}			= $_[1]	}
sub set_request			{ shift->{request}		= $_[1]	}
sub set_ip			{ shift->{ip}			= $_[1]	}
sub set_event			{ shift->{event}		= $_[1]	}

sub state			{ shift->{state}			}

sub new {
    my $class = shift;
    my %par   = @_;
    my ( $sock, $webserver ) = @par{ 'sock', 'webserver' };

    my $self = bless {
        fd        => $sock,
        request   => '',
        refresh   => 0,
        webserver => $webserver,
        state     => {},
    }, $class;

    Event->io(
        fd   => $sock,
        poll => 'r',
        nice => NICE,
        cb   => [ $self, 'read_http_request' ],
        desc => "http reader",
    );

    return $self;
}

sub get_url {
    my $self         = shift;
    my %change_state = @_;

    my $state = $self->state;

    my %new_state;

    foreach my $key ( keys %{$state} ) {
        $new_state{$key} = $state->{$key}
            if not exists $change_state{$key};
    }

    foreach my $key ( keys %change_state ) {
        $new_state{$key} = $change_state{$key};
    }

    my $url;

    foreach my $key ( sort keys %new_state ) {
        $url .= "/$key/$new_state{$key}";
    }

    return $url;
}

sub parse_url {
    my $self = shift;

    my $request = $self->get_request;

    my ($url) = ( $request =~ /^GET\s+([^\s]+)/ );

    while ( $url =~ m!/([^/]*)/([^/]*)!g ) {
        $self->state->{$1} = $2;
    }

    1;
}

sub read_http_request {
    my $self = shift;
    my ($e) = @_;

    $self->set_event($e);

    my $fd = $self->get_fd;
    my $request;

    if ( !sysread( $fd, $request, 4096 ) ) {
        $self->close_connection;
        return 1;
    }

    $self->set_request($request);

    $self->process_request;

    1;
}

sub close_connection {
    my $self = shift;

    my $e  = $self->get_event;
    my $fd = $self->get_fd;

    $e->w->cancel;
    close $fd;

    1;
}

sub send_http_header {
    my $self = shift;

    my $fd = $self->get_fd;

    print $fd "HTTP/1.0 200 OK\r\n";
    print $fd "Connection: close\r\n";

    if ( $self->state->{reload} ) {
        my $url = $self->get_url;
        print $fd "Refresh: 5;$url\r\n";
    }

    print $fd "Content-type: text/html\r\n\r\n";
}

sub send_html_header {
    my $self = shift;

    my $fd = $self->get_fd;

    my $menu = "";

    my $url = $self->get_url( reload => !$self->state->{reload} || 0 );

    $menu .= qq{[<a href="$url">switch refresh }
        . ( $self->state->{reload} ? 'off' : 'on' )
        . qq{</a>] };

    print $fd <<__EOF;
<html>
<head><title>dvd::rip cluster master daemon</title>
<style>
td,p,li,dt,dd,blockquote {
  font-family: Verdana, Arial, Helvetica, sans-serif;
  font-size: 10px; 
  font-style: normal;
  line-height: normal;
  font-weight: normal; 
  color: #000000;
}
a { 
  font-family: Verdana, Arial, Helvetica, sans-serif;
  font-style: normal;
  font-size: 10px; 
  line-height: normal;
  font-weight: bold;
  color: #000000;
}
table {
  border-width: 0;
}
td {
  vertical-align: top
}
.pagetitle {
  font-size: 14px; 
  font-weight: bold; 
  color: #002e93;
}
.table_title {
  font-size: 10px; 
  font-weight: bold; 
  color: #ffffff;
  background-color:#002e93
}
.column_title {
  font-size: 10px; 
  font-weight: bold; 
  color: #000000;
  background-color:#d6d8ff
}
.row {
  font-size: 10px; 
  color: #000000;
  background-color:#f0f0f0
}
.row_selected {
  font-size: 10px; 
  font-weight: bold; 
  color: #000000;
  background-color:#ee7788
}
.page_footer {
  font-size: 8px; 
  color: #000000;
}
</style>
</head>
<body bgcolor="white">
<table width="100%" cellpadding="0" cellspacing="0">
<tr><td align="left">
  <p class="pagetitle">
  dvd::rip cluster control daemon
  </p>
</td><td align="right">
  $menu
</td></tr>
</table>
__EOF
    1;
}

sub send_state {
    my $self = shift;

    my $fd = $self->get_fd;

    #-- Projects

    my $projects   = $self->webserver->master->projects_list;
    my $project_id = $self->state->{project};

    $project_id = $projects->[0]->[0]
        if $projects->[0]
        and not defined $project_id;

    if ( $projects->[0] ) {

        print $fd <<__EOF;
<p></p>
<table width="100%">
<tr>
  <td colspan="4" class="table_title">Project Queue</td>
</tr>
<tr>
  <td class="column_title">Nr</td>
  <td class="column_title">Project</td>
  <td class="column_title">Jobs</td>
  <td class="column_title">State</td>
</tr>
__EOF

        my $nr = 0;
        my $row_class;
        foreach my $p ( @{$projects} ) {
            ++$nr;
            $row_class = $p->[0] == $project_id ? "row_selected" : "row";
            my $url = $self->get_url( project => $p->[0] );
            print $fd <<__EOF;
<tr>
  <td class="$row_class">$nr</td>
  <td class="$row_class"><a href="$url">$p->[2]</a></td>
  <td class="$row_class">$p->[3]</td>
  <td class="$row_class">$p->[4]</td>
</tr>
__EOF
        }

        print $fd "</table>\n";
    }

    #-- Jobs
    my $project_job
        = $self->webserver->master->scheduler->get_jobs_by_project_id
        ->{$project_id};

    if ($project_job) {
        print $fd <<__EOF;
<p></p>
<table width="100%">
<tr>
  <td colspan="5" class="table_title">Jobs of the selected project</td>
</tr>
<tr>
  <td class="column_title">Title</td>
  <td class="column_title">Progress</td>
</tr>
__EOF
        $self->print_project_job($project_job);
        print $fd "</table>\n";
    }

    #-- Nodes

    print $fd <<__EOF;
<p></p>
<table width="100%">
<tr>
  <td colspan="4" class="table_title">Registered Nodes</td>
</tr>
<tr>
  <td class="column_title">Nr</td>
  <td class="column_title">Name</td>
  <td class="column_title">Job</td>
  <td class="column_title">Progress</td>
</tr>
__EOF

    my $nodes = $self->webserver->master->nodes_list;

    my $nr = 0;
    my ( $name, $job_info, $progress );
    foreach my $n ( @{$nodes} ) {
        print $fd <<__EOF;
<tr>
  <td class="row">$n->[1]</td>
  <td class="row">$n->[2]</td>
  <td class="row">$n->[3]</td>
  <td class="row">$n->[4]</td>
</tr>
__EOF
    }

    print $fd "</table>\n";
    1;
}

sub print_project_job {
    my $self = shift;
    my ( $job, $indent ) = @_;

    my $fd    = $self->get_fd;
    my $space = "&nbsp;&nbsp;&nbsp;" x $indent;

    print $fd qq{<tr><td class="row">$space}
        . $job->get_info
        . qq{</td><td class="row">}
        . $job->get_progress_text
        . qq{</td></tr>\n};

    if ( $job->get_type eq 'group' ) {
        foreach my $child ( @{ $job->get_jobs } ) {
            $self->print_project_job( $child, $indent + 1 );
        }
    }

    1;
}

sub send_html_footer {
    my $self = shift;

    my $fd = $self->get_fd;

    my $year = ( localtime(time) )[5] + 1900;

    print $fd <<__EOF;
<p class="page_footer">
dvd::rip cluster control daemon -
&copy; 2003-$year Jörn Reder, All Rights Reserverd -
__EOF
    print $fd <<'__EOF';
$Id: Webserver.pm 2187 2006-08-16 19:34:38Z joern $
</p>
</body></html>
__EOF

    1;
}

sub process_request {
    my $self = shift;
    my ($e) = @_;

    $self->parse_url;

    $self->send_http_header;
    $self->send_html_header;

    if ( $self->action ) {
        $self->finish_request;
    }

    1;
}

sub finish_request {
    my $self = shift;

    $self->send_state;
    $self->send_html_footer;
    $self->close_connection;

    1;
}

sub action {
    my $self = shift;

    1;
}

1;
