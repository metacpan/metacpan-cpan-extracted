# Copyrights 2007-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Daemon::AnyDaemon;
use vars '$VERSION';
$VERSION = '3.13';


# Any::Daemon at least version 0.13
use parent 'XML::Compile::SOAP::Daemon', 'Any::Daemon';

use Log::Report 'xml-compile-soap-daemon';

use Time::HiRes       qw/time alarm/;
use Socket            qw/SOMAXCONN/;
use IO::Socket::INET  ();

use XML::Compile::SOAP::Util  qw/:daemon/;
use XML::Compile::SOAP::Daemon::LWPutil;


sub new($%)
{   my ($class, %args) = @_;
    my $self = Any::Daemon->new(%args);
    (bless $self, $class)->init(\%args);  # $ISA[0] branch only
}

sub setWsdlResponse($;$)
{   my ($self, $fn, $ft) = @_;
    trace "setting wsdl response to $fn";
    lwp_wsdl_response $fn, $ft;
}

#-----------------------

sub _run($)
{   my ($self, $args) = @_;

    my $name = $args->{server_name} || 'soap server';
    lwp_add_header
       'X-Any-Daemon-Version' => $Any::Daemon::VERSION
      , Server => $name;

    my $socket = $args->{socket};
    unless($socket)
    {   my $host = $args->{host} or error "run() requires host";
        my $port = $args->{port} or error "run() requires port";

        $socket  = IO::Socket::INET->new
          ( LocalHost => $host
          , LocalPort => $port
          , Listen    => ($args->{listen} || SOMAXCONN)
          , Reuse     => 1
          ) or fault __x"cannot create socket at {interface}"
            , interface => "$host:$port";

        info __x"created socket at {interface}", interface => "$host:$port";
    }
    $self->{XCSDA_socket}    = $socket;
    lwp_socket_init $socket;

    $self->{XCSDA_conn_opts} =
     +{ timeout     => ($args->{client_timeout}  ||  30)
      , maxmsgs     => ($args->{client_maxreq}   || 100)
      , reqbonus    => ($args->{client_reqbonus} ||   0)
      , postprocess => $args->{postprocess}
      };

    my $child_init = $args->{child_init} || sub {};
    my $child_task = sub {$child_init->($self); $self->accept_connections};

    $self->Any::Daemon::run
      ( child_task => $child_task
      , max_childs => ($args->{max_childs} || 10)
      , background => (exists $args->{background} ? $args->{background} : 1)
      );
}

sub accept_connections()
{   my $self   = shift;
    my $socket = $self->{XCSDA_socket};

    while(my $client = $socket->accept)
    {   info __x"new client {remote}", remote => $client->peerhost;
        $self->handle_connection(lwp_http11_connection $self, $client);
        $client->close;
    }
}

sub handle_connection($)
{   my ($self, $connection) = @_;
    my $conn_opts = $self->{XCSDA_conn_opts};
    eval {
        lwp_handle_connection $connection
          , %$conn_opts
          , expires  => time() + $conn_opts->{timeout}
          , handler  => sub {$self->process(@_)}
    };
    info __x"connection ended with force; {error}", error => $@
        if $@;
    1;
}

sub url() { "url replacement not yet implemented" }
sub product_tokens() { shift->{prop}{name} }

#-----------------------------


1;
