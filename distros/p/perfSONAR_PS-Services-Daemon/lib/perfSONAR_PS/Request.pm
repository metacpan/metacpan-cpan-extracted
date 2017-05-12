package perfSONAR_PS::Request;

use fields 'REQUEST', 'REQUESTDOM', 'RESPONSE', 'RESPONSEMESSAGE', 'START_TIME', 'CALL', 'NAMESPACES';

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use XML::LibXML;

use perfSONAR_PS::Common;

our $VERSION = 0.09;

sub new {
    my ($package, $call, $http_request) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");

    my $self = fields::new($package);

    $self->{"CALL"} = $call;
    if (defined $http_request and $http_request ne "") {
        $self->{"REQUEST"} = $http_request;
    } else {
        $self->{"REQUEST"} = $call->get_request;
    }
    my %empty = ();
    $self->{"NAMESPACES"} = \%empty;

    $self->{"RESPONSE"} = HTTP::Response->new();
    $self->{"RESPONSE"}->header('Content-Type' => 'text/xml');
    $self->{"RESPONSE"}->header('user-agent' => 'perfSONAR-PS/1.0b');
    $self->{"RESPONSE"}->code("200");

    $self->{"START_TIME"} = [Time::HiRes::gettimeofday];

    return $self;
}

sub setRequest {
    my ($self, $request) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if(defined $request and $request ne "") {
        $self->{REQUEST} = $request;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}

sub getEndpoint {
    my ($self) = @_;
    my $endpoint = $self->{REQUEST}->uri;

    $endpoint =~ s/\/\//\//;

    return $endpoint;
}

sub parse {
    my ($self, $namespace_map, $error) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");

    if (!defined $self->{REQUEST}) {
        my $msg = "No request to parse";
        $logger->error($msg);
        $$error = $msg;
        return -1;
    }

    $logger->debug("Parsing request: ".$self->{REQUEST}->content); 

    my $parser = XML::LibXML->new();
    my $dom;
    eval {
        $dom = $parser->parse_string($self->{REQUEST}->content);
    };
    if($@) {
        my $msg = escapeString("Parse failed: ".$@);

        $logger->error($msg);
        $$error = $msg if (defined $error);
        return -1;
    }

    &perfSONAR_PS::Common::mapNamespaces($dom->getDocumentElement, $self->{NAMESPACES});

    &perfSONAR_PS::Common::reMap($self->{NAMESPACES}, $namespace_map, $dom->getDocumentElement, 0);

    my $nmwg_prefix = $self->{NAMESPACES}->{"http://ggf.org/ns/nmwg/base/2.0/"};
    if (!defined $nmwg_prefix) {
        my $msg = "Received message with incorrect message URI";
        $logger->error($msg);
        $$error = $msg if (defined $error);
        return -1;
    }

    my $messages = find($dom->getDocumentElement, ".//nmwg:message", 0);

    if (not defined $messages or $messages->size() <= 0) {
        my $msg = "Couldn't find message element in request";
        $logger->error($msg);
        $$error = $msg if (defined $error);
        return -1;
    }

    if($messages->size() > 1) {
        my $msg = "Too many message elements found within request";
        $logger->error($msg);
        $$error = $msg if (defined $error);
        return -1;
    }

    my $new_dom;
    $new_dom = $parser->parse_string($messages->get_node(1)->toString);

    $logger->debug("Parsed incoming request: ".$new_dom->toString);

    $self->{REQUESTDOM} = $new_dom;
    $$error = "";
    return 0;
}

sub remapRequest {
    my ($self, $ns) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");

    if (not defined $self->{REQUESTDOM} or $self->{REQUESTDOM} eq "") {
        $logger->error("Tried to remap an unparsed request");
        return;
    }

    $self->{NAMESPACES} = &perfSONAR_PS::Common::reMap($self->{NAMESPACES}, $ns, $self->{REQUESTDOM});

    return;
}

sub getURI {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if (!defined $self->{REQUEST}) {
        $logger->error("Tried to get URI with no request");
        return "";
    }
    return $self->{REQUEST}->uri;
}

sub getRawRequest {
    my ($self) = @_;

    return $self->{REQUEST};
}

sub getRawRequestAsString {
    my ($self) = @_;

    return $self->{REQUEST}->content;
}

sub setResponse {
    my ($self, $content) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if(defined $content and $content ne "") {
        $self->{RESPONSE}->message("success");
        $self->{RESPONSE}->content(makeEnvelope($content));
        $self->{RESPONSEMESSAGE} = $content;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}

sub getRequestDOM {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if($self->{REQUESTDOM}) {
        return $self->{REQUESTDOM};
    } else {
        $logger->error("Request DOM not found.");
        return "";
    }
}

sub getResponse {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if($self->{RESPONSEMESSAGE}) {
        return $self->{RESPONSEMESSAGE};
    } else {
        $logger->error("Response not found.");
        return "";
    }
}

sub setNamespaces {
    my ($self, $ns) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if(defined $ns and $ns ne "") {
        $self->{NAMESPACES} = $ns;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}


sub getNamespaces {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if($self->{NAMESPACES}) {
        return $self->{NAMESPACES};
    } else {
        $logger->error("Request namespace object not found.");
        return ();
    }
}


sub setRequestDOM {
    my ($self, $dom) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if(defined $dom and $dom ne "") {
        $self->{REQUESTDOM} = $dom;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}

sub finish {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Request");
    if(defined $self->{CALL} and $self->{CALL} ne "") {
        my $end_time = [Time::HiRes::gettimeofday];
        my $diff = Time::HiRes::tv_interval $self->{START_TIME}, $end_time;
        $logger->info("Total service time for request from ".$self->{CALL}->peerhost().": ".$diff." seconds");
        $self->{CALL}->send_response($self->{RESPONSE});
        $self->{CALL}->close;
        delete $self->{CALL};
        $logger->debug("Closing call.");
    } else {
        $logger->error("Call not established.");
    }
    return;
}

1;

__END__
=head1 NAME

perfSONAR_PS::Request - A module that provides an object to interact with for
each client request.

=head1 DESCRIPTION

This module is to be treated as an object representing a request from a user.
The object can be used to get the users request in DOM format as well as set
and send the response.

=head1 SYNOPSIS

=head1 DETAILS

=head1 API

=head2 new ($package, $call, $http_request)

The 'call' argument is the resonse from HTTP::Daemon->accept(). The request is
the actual http request from the user. In general, it can be obtained from the call
variable specified above using the '->get_request' function. If it is
unspecified, new will try to obtain the request from $call directly.

=head2 getURI($self)

Returns the URI of the given request

=head2 setRequest($self, $request)

(Re-)Sets the request from the client. The request must be a
HTT::Daemon::ClientConn object.

=head2 getURI($self)

Returns the URI for the specified request.

=head2 getRawRequest($self)

Returns the request as it was given to the object(i.e. the underlying
HTTP::Daemon::ClientConn object).

=head2 getRequestDOM($self)

Gets and returns the contents of the request as a DOM object.

=head2 setResponse($self, $content)

Sets the response to the content.

=head2 getResponse($self)

Gets and returns the response as a string.

=head2 setNamespaces($self,\%ns)

(Re-)Sets the the namespaces in the request.

=head2 getNamespaces($self)

Gets and returns the hash containing the namespaces for the given request.

=head2 parse($self, $ns, $error)

Parses the request and remaps the elements in the request according to the
specified namespaces. It returns -1 on error and 0 if everything parsed.

=head2 remapRequest($self, $ns)

Remaps the given request according to the prefix/uri pairs specified in the $ns
hash.

=head2 finish($self)

Sends the response to the client and closes the connection

=head1 SEE ALSO

L<Exporter>, L<HTTP::Daemon>, L<Log::Log4perl>, L<perfSONAR_PS::Transport>
L<XML::XPath>, L<perfSONAR_PS::Common>, L<perfSONAR_PS::Messages>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu, Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
