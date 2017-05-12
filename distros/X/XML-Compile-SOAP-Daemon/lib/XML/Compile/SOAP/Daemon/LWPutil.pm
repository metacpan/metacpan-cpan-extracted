# Copyrights 2007-2016 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package XML::Compile::SOAP::Daemon::LWPutil;
use vars '$VERSION';
$VERSION = '3.12';

use parent 'Exporter';


our @EXPORT = qw(
    lwp_action_from_header
    lwp_add_header
    lwp_handle_connection
    lwp_make_response
    lwp_run_request
    lwp_wsdl_response
    lwp_socket_init
    lwp_http11_connection
);

use Log::Report 'xml-compile-soap-daemon';
use XML::Compile::SOAP::Util ':daemon';
use LWP;
use HTTP::Status qw/RC_OK RC_METHOD_NOT_ALLOWED RC_NOT_ACCEPTABLE/;

sub lwp_add_header($$@);
sub lwp_handle_connection($@);
sub lwp_run_request($$;$$);
sub lwp_make_response($$$$;$);
sub lwp_action_from_header($);



our @default_headers;
BEGIN
{   foreach my $pkg (qw/XML::Compile XML::Compile::SOAP
        XML::Compile::SOAP::Daemon XML::LibXML LWP/)
    {   no strict 'refs';
        my $version = ${"${pkg}::VERSION"} || 'undef';
        (my $field = "X-$pkg-Version") =~ s/\:\:/-/g;
        push @default_headers, $field => $version;
    }
}

sub lwp_add_header($$@) { push @default_headers, @_ }


my $wsdl_response;
sub lwp_wsdl_response(;$$)
{   @_ or return $wsdl_response;

    my ($file, $ft) = @_;
    $file && !ref $file
        or return $wsdl_response = $file;

    local *SRC;
    open SRC, '<:raw', $file
        or fault __x"cannot read wsdl file {file}", file => $file;
    local $/;
    my $spec = <SRC>;
    close SRC;

    $ft ||= 'application/wsdl+xml';
    $wsdl_response = HTTP::Response->new
      ( RC_OK, "WSDL specification"
      , [ @default_headers
        , "Content-Type" => "$ft; charset=utf-8"
        ]
      , $spec
      );
}
    

sub lwp_handle_connection($@)
{   my ($connection, %args) = @_;
    my $expires  = $args{expires};
    my $maxmsgs  = $args{maxmsgs};
    my $reqbonus = $args{reqbonus};
    my $postproc = $args{postprocess};

    local $SIG{ALRM} = sub { die "timeout\n" };

    my $timeleft;
    while(($timeleft = $expires - time) > 0.01)
    {   alarm $timeleft if $timeleft;
        my $request  = $connection->get_request;
        alarm 0;
        $request or last;

        my $response = lwp_run_request $request, $args{handler}
          , $connection, $postproc;

        $connection->force_last_request if $maxmsgs==1;
        $connection->send_response($response);

        --$maxmsgs or last;
        $expires += $reqbonus;
    }
}


sub lwp_run_request($$;$$)
{   my ($request, $handler, $connection, $postproc) = @_;

#   my $client   = $connection->peerhost;
    return $wsdl_response
        if $wsdl_response
        && $request->method eq 'GET'
        && uc($request->uri->query || '') eq 'WSDL';

    if($request->method !~ m/^(?:M-)?POST/ )
    {   return lwp_make_response $request
          , RC_METHOD_NOT_ALLOWED
          , 'only POST or M-POST'
          , "attempt to connect via ".$request->method;
    }

    my $media    = $request->content_type || 'text/plain';
    $media =~ m{[/+]xml$}i
        or return lwp_make_response $request
          , RC_NOT_ACCEPTABLE
          , 'required is XML'
          , "content-type seems to be $media, must be some XML";

    my $action   = lwp_action_from_header $request;
    my $ct       = $request->header('Content-Type');
    my $charset  = $ct =~ m/\;\s*type\=(["']?)([\w-]*)\1/ ? $2: 'utf-8';
    my $xmlin    = $request->decoded_content(charset => $charset, ref => 1);

    my ($status, $status_msg, $xml)
      = $handler->($xmlin, $request, $action);

    lwp_make_response $request, $status, $status_msg, $xml, $postproc;
}


sub lwp_make_response($$$$;$)
{   my ($request, $status, $msg, $body, $postproc) = @_;

    my $response = HTTP::Response->new($status, $msg);
    $response->header(@default_headers);
    $response->protocol($request->protocol);  # match request's

    my $s;
    if(UNIVERSAL::isa($body, 'XML::LibXML::Document'))
    {   $s = $body->toString($status == RC_OK ? 0 : 1);
        $response->header('Content-Type' => 'text/xml; charset=utf-8');
    }
    else
    {   $s = "[$status] $body";
        $response->header(Content_Type => 'text/plain');
    }

    $postproc->($request, $response, $status, \$s)
        if $postproc;

    $response->content_ref(\$s);
    { use bytes; $response->header('Content-Length' => length $s); }

    if(substr($request->method, 0, 2) eq 'M-')
    {   # HTTP extension framework.  More needed?
        $response->header(Ext => '');
    }

    $response;
}


sub lwp_action_from_header($)
{   my ($request) = @_;

    my $action;
    if($request->method eq 'POST')
    {   $action = $request->header('SOAPAction');
    }
    elsif($request->method eq 'M-POST')
    {   # Microsofts HTTP Extension Framework
        my $http_ext_id = '"' . MSEXT . '"';
        my $man = first { m/\Q$http_ext_id\E/ } $request->header('Man');
        defined $man or return undef;

        $man =~ m/\;\s*ns\=(\d+)/ or return undef;
        $action = $request->header("$1-SOAPAction");
    }
    else
    {   return undef;
    }

    defined $action or return;

    $action =~ s/["'\s]//g;  # often wrong blanks and quotes
    $action;
}


sub lwp_socket_init($)
{   my $socket = shift;
    my $http11_impl = $socket->isa('IO::Socket::SSL')
      ? 'HTTP::Daemon::SSL' : 'HTTP::Daemon';

    eval "require $http11_impl";
    error $@ if $@;
}


sub lwp_http11_connection($$)
{   my ($daemon, $client) = @_;
    my $http11_impl = $client->isa('IO::Socket::SSL')
      ? 'HTTP::Daemon::ClientConn::SSL' : 'HTTP::Daemon::ClientConn';

    # Ugly hack: hijack the HTTP11 implementation of HTTP::Daemon
    my $connection  = bless $client, $http11_impl;
    ${*$connection}{httpd_daemon} = $daemon;
    $connection;
}


#------------------------------

1;
