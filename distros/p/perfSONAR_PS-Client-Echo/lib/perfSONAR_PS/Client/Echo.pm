package perfSONAR_PS::Client::Echo;

use strict;
use warnings;
use Log::Log4perl qw(get_logger :nowarn);
use perfSONAR_PS::Common;
use perfSONAR_PS::Transport;
use perfSONAR_PS::Messages;
use perfSONAR_PS::XML::Document_string;

our $VERSION = 0.09;

use fields 'URI', 'EVENT_TYPE';

sub new {
	my ($package, $uri_string, $eventType) = @_;

    my $self = fields::new($package);

	if (defined $uri_string and $uri_string ne "") { 
		$self->{"URI"} = $uri_string;

	}

	if (not defined $eventType or $eventType eq "") {
		$eventType = "http://schemas.perfsonar.net/tools/admin/echo/2.0";
	}

	$self->{"EVENT_TYPE"} = $eventType;

	return $self;
}

sub setEventType {
	my ($self, $eventType) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Echo");

	$self->{EVENT_TYPE} = $eventType;

    return;
}

sub setURIString {
	my ($self, $uri_string) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Echo");

	$self->{URI} = $uri_string;

    return;
}

sub createEchoRequest {
	my ($self, $output) = @_; 
	my $logger = get_logger("perfSONAR_PS::Client::Echo");

	my $messageID = "message.".genuid();
	my $mdID = "metadata.".genuid();
	my $dID = "data.".genuid();

	startMessage($output, $messageID, undef, "EchoRequest", "", undef);
	getResultCodeMetadata($output, $mdID, "", $self->{EVENT_TYPE});
	createData($output, $dID, $mdID, "", undef);
	endMessage($output);

	$logger->debug("Finished creating echo request");

	return 0;
}

sub ping {
	my ($self) = @_;
	my $logger = get_logger("perfSONAR_PS::Client::Echo");

	if (not defined $self->{URI}) {
		return (-1, "Invalid URI specified \"\"");
	}

	my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($self->{URI});
	if (not defined $host and not defined $port and not defined $endpoint) {
		return (-1, "Invalid URI specified \"".$self->{URI}."\"");
	}

	my $doc = perfSONAR_PS::XML::Document_string->new();
	$self->createEchoRequest($doc);

	my ($status, $res) = consultArchive($host, $port, $endpoint, $doc->getValue());
	if ($status != 0) {
		my $msg = "Error contacting service: $res";
		$logger->error($msg);
		return(-1, $msg);
	}

	$logger->debug("Response: ".$res->toString);

	foreach my $d ($res->getChildrenByTagName("nmwg:data")) {
		foreach my $m ($res->getChildrenByTagName("nmwg:metadata")) {
			my $md_id = $m->getAttribute("id");
			my $md_idref = $m->getAttribute("metadataIdRef");
			my $d_idref = $d->getAttribute("metadataIdRef");

			if($md_id eq $d_idref) {
				my $eventType = findvalue($m, "nmwg:eventType");

				$eventType =~ s/\s*//g;

				if ($eventType =~ /^success\./) {
					return (0, "");
				}
			}
		}
	}

	return (-1, "No successful return");;
}

1;

__END__

=head1 NAME

perfSONAR_PS::Client::Echo - A module that provides methods for
interacting with perfSONAR Echo services.

=head1 DESCRIPTION

This module allows one to test whether or not a perfSONAR service is running by testing by pinging it using the standardized pS ping request.

The module is to be treated as an object, where each instance of the object
represents a connection to an endpoint. Each method may then be invoked on the
object for the specific endpoint.  

=head1 SYNOPSIS

	use perfSONAR_PS::Client::Echo;

	my $echo_client = new perfSONAR_PS::Client::Echo("http://localhost:4801/axis/services/status");
	if (not defined $echo_client) {
		print "Problem creating echo client for service\n";
		exit(-1);
	}

	my ($status, $res) = $echo_client->ping;
	if ($status != 0) {
		print "Problem pinging service: $res\n";
		exit(-1);
	}

=head1 DETAILS

=head1 API

The API os perfSONAR_PS::Client::Echo is rather simple and greatly resembles
the messages types received by the server.

=head2 new($package, $uri_string, $eventType)

The new function takes a URI connection string as its first argument. This
specifies which service to interact with. The function can take an optional
eventType argument which can be used if a service only supports a specific echo
request event type.

=head2 ping($self)

The ping function is used to test if the service is up. It returns an array
containing two values. The first value is a number which specifies whether the
ping succeeded. If it's 0, that means the ping succeeded and the second value
is undefined. If it is -1, that means the ping failed and the second value
contains an error message.

=head2 setURIString($self, $uri_string)

The setURIString function changes the MA that the instance uses.

=head2 setEventType($self, $eventType)

The setEventType function changes the eventType that the instance uses.

=head1 SEE ALSO

L<perfSONAR_PS::Common>, L<perfSONAR_PS::Transport>, L<perfSONAR_PS::Messages>,
L<perfSONAR_PS::XML::Document_string>, L<Log::Log4perl>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
