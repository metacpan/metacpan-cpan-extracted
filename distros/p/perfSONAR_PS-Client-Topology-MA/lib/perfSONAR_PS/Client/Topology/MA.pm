package perfSONAR_PS::Client::Topology::MA;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Common;
use perfSONAR_PS::Transport;

use fields 'URI_STRING';

our $VERSION = 0.09;

sub new {
    my ($package, $uri_string) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::Topology::MA");

    my $self = fields::new($package);

    if (defined $uri_string and $uri_string ne "") { 
        $self->{"URI_STRING"} = $uri_string;

    }

    return $self;
}

sub open {
    my ($self) = @_;

    return (0, "");
}

sub close {
    my ($self) = @_;

    return 0;
}

sub setURIString {
    my ($self, $uri_string) = @_;

    $self->{URI_STRING} = $uri_string;

    return;
}

sub dbIsOpen {
    return 1;
}

sub getURIString {
    my ($self) = @_;

    return $self->{URI_STRING};
}

sub buildGetAllRequest {
    my $request = "";

    $request .= "<nmwg:message type=\"SetupDataRequest\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= "<nmwg:metadata id=\"meta0\">\n";
    $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/topology/query/all/20070809</nmwg:eventType>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\" />\n";
    $request .= "</nmwg:message>\n";

    return ("", $request);
}

sub buildXqueryRequest {
    my ($xquery) = @_;
    my $request = "";

    $request .= "<nmwg:message type=\"SetupDataRequest\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= "<nmwg:metadata id=\"meta0\">\n";
    $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/topology/query/xquery/20070809</nmwg:eventType>\n";
    $request .= "  <xquery:subject id=\"sub1\" xmlns:xquery=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/\">\n";
    $request .= $xquery;
    $request .= "  </xquery:subject>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\" />\n";
    $request .= "</nmwg:message>\n";

    return ("", $request);

}

sub buildChangeTopologyRequest {
    my ($type, $topology) = @_;
    my $eventType;

    if ($type eq "add") {
        $eventType = "http://ggf.org/ns/nmwg/topology/change/add/20070809";
    } elsif ($type eq "update") {
        $eventType = "http://ggf.org/ns/nmwg/topology/change/update/20070809";
    } elsif ($type eq "replace") {
        $eventType = "http://ggf.org/ns/nmwg/topology/change/replace/20070809";
    }

    my $request = "";

	$request .= "<nmwg:message type=\"TopologyChangeRequest\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
	$request .= "<nmwg:metadata id=\"meta0\">\n";
	$request .= "  <nmwg:eventType>$eventType</nmwg:eventType>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\">\n";
    my $elm = $topology->cloneNode(1);
    $elm->unbindNode();

    $request .= $elm->toString;
    $request .= "</nmwg:data>\n";
    $request .= "</nmwg:message>\n";

    return $request;
}

sub xQuery {
    my ($self, $xquery) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::Topology::MA");
    my $localContent = "";
    my $error;
    my ($status, $res, $request);

    ($status, $request) = buildXqueryRequest($xquery);

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if (not defined $host and not defined $port and not defined $endpoint) {
        my $msg = "Specified argument is not a URI";
        my $logger->error($msg);
        return (-1, $msg);
    }

    ($status, $res) = consultArchive($host, $port, $endpoint, $request);
    if ($status != 0) {
        my $msg = "Error consulting archive: $res";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $topo_msg = $res;

    my $data_elms = find($topo_msg, './*[local-name()="data"]', 0);
    if ($data_elms) {
    foreach my $data ($data_elms->get_nodelist) {
        my $metadata_elms = find($topo_msg, './*[local-name()="metadata"]', 0);
        if ($metadata_elms) {
        foreach my $metadata ($metadata_elms->get_nodelist) {
            if ($data->getAttribute("metadataIdRef") eq $metadata->getAttribute("id")) {
                my $topology = find($data, './*[local-name()="topology"]', 1);
                if (defined $topology) {
                    return (0, $topology->toString);
                } 
            }
        }
        }
    }
    }

    my $msg = "Response does not contain a topology";
    $logger->error($msg);
    return (-1, $msg);
}

sub getAll {
    my($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::Topology::MA");
    my @results;
    my $error;
    my ($status, $res);

    my $request = buildGetAllRequest();

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if (not defined $host and not defined $port and not defined $endpoint) {
        my $msg = "Specified argument is not a URI";
        my $logger->error($msg);
        return (-1, $msg);
    }

    ($status, $res) = consultArchive($host, $port, $endpoint, $request);
    if ($status != 0) {
        my $msg = "Error consulting archive: $res";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $topo_msg = $res;

    my $data_elms = find($topo_msg, './*[local-name()="data"]', 0);
    if ($data_elms) {
    foreach my $data ($data_elms->get_nodelist) {

        my $metadata_elms = find($topo_msg, './*[local-name()="metadata"]', 0);
        if ($metadata_elms) {
        foreach my $metadata ($metadata_elms->get_nodelist) {
            if ($data->getAttribute("metadataIdRef") eq $metadata->getAttribute("id")) {
                my $topology = find($data, './nmtopo:topology', 1);
                if (defined $topology) {
                    return (0, $topology);
                } 
            }
        }
	}
    }
    }

    my $msg = "Response does not contain a topology";
    $logger->error($msg);
    return (-1, $msg);
}

sub changeTopology {
    my ($self, $type, $topology) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::Topology::MA");
    my @results;
    my $error;
    my ($status, $res);

    my $request = buildChangeTopologyRequest($type, $topology);

    $logger->debug("Change Request: ".$request);

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if (not defined $host and not defined $port and not defined $endpoint) {
        my $msg = "Specified argument is not a URI";
        my $logger->error($msg);
        return (-1, $msg);
    }

    ($status, $res) = consultArchive($host, $port, $endpoint, $request);
    if ($status != 0) {
        my $msg = "Error consulting archive: $res";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $topo_msg = $res;

    $logger->debug("Change Response: ".$topo_msg->toString);

    my $find_res;

    $find_res = find($res, "./nmwg:data", 0);
    if ($find_res) {
        foreach my $data ($find_res->get_nodelist) {
            my $metadata = find($res, "./nmwg:metadata[\@id='".$data->getAttribute("metadataIdRef")."']", 1);
            if (not defined $metadata) {
                return (-1, "No metadata in response");
            }

            my $eventType = findvalue($metadata, "nmwg:eventType");
            if (defined $eventType and $eventType =~ /^error\./x) {
                my $error_msg = findvalue($data, "./nmwgr:datum");
                $error_msg = "Unknown error" if (not defined $error_msg or $error_msg eq "");
                return (-1, $error_msg);
            } elsif (defined $eventType and $eventType =~ /^success\./x) {
                return (0, "Success");
            }
        }
    }

    my $msg = "Response does not contain status";
    $logger->error($msg);
    return (-1, $msg);
}

1;

__END__

=head1 NAME

perfSONAR_PS::Client::Topology::MA - A module that provides methods for
interacting with Topology MA servers.

=head1 DESCRIPTION

This modules allows one to interact with the Topology MA via its Web Services
interface. The API provided is identical to the API for interacting with the
topology database directly. Thus, a client written to read from or update a
Topology MA can be easily modified to interact directly with its underlying
database allowing more efficient interactions if required.

The module is to be treated as an object, where each instance of the object
represents a connection to a single database. Each method may then be invoked
on the object for the specific database.  

=head1 SYNOPSIS

=head1 DETAILS

=head1 API

The API for perfSONAR_PS::Client::Topology::MA is rather simple and greatly
resembles the messages types received by the server. It is also identical to
the perfSONAR_PS::Client::Topology::SQL API allowing easy construction of
programs that can interface via the MA server or directly with the database.

=head2 new($package, $uri_string)

    The new function takes a URI connection string as its first argument. This
    specifies which MA to interact with.

=head2 open($self)

    The open function could be used to open a persistent connection to the MA.
    However, currently, it is simply a stub function.

=head2 close($self)

    The close function could close a persistent connection to the MA. However,
    currently, it is simply a stub function.

=head2 setURIString($self, $uri_string)

    The setURIString function changes the MA that the instance uses.

=head2 dbIsOpen($self)

    This function is a stub function that always returns 1.

=head2 getURIString($)

    The getURIString function returns the current URI string

=head2 getAll($self)

    The getAll function gets the full contents of the MA. It returns the results as
    a ref to a LibXML element pointing to the <nmtopo:topology> structure
    containing the contents of the MA's database. 

=head2 xQuery($self, $xquery)

    The xQuery function performs an xquery on the specified MA. It returns the
    results as a string.

    =head1 SEE ALSO

    L<perfSONAR_PS::Client::Topology::XMLDB>, L<Log::Log4perl>

    To join the 'perfSONAR-PS' mailing list, please visit:

    https://mail.internet2.edu/wws/info/i2-perfsonar

    The perfSONAR-PS subversion repository is located at:

    https://svn.internet2.edu/svn/perfSONAR-PS 

    Questions and comments can be directed to the author, or the mailing list. 

    =head1 VERSION

    $Id$

    =head1 AUTHOR

    Aaron Brown, aaron@internet2.edu

    =head1 LICENSE

    You should have received a copy of the Internet2 Intellectual Property Framework along
    with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

    =head1 COPYRIGHT

    Copyright (c) 2004-2007, Internet2 and the University of Delaware

    All rights reserved.

    =cut

# vim: expandtab shiftwidth=4 tabstop=4
