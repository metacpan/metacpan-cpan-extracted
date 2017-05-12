package perfSONAR_PS::Client::Status::MA;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Common;
use perfSONAR_PS::Status::Link;
use perfSONAR_PS::Status::Common;
use perfSONAR_PS::Transport;
use perfSONAR_PS::Time;

our $VERSION = 0.09;

use fields 'URI_STRING';

sub new {
    my ($package, $uri_string) = @_;

    my $self = fields::new($package);

    if (defined $uri_string and $uri_string ne "") { 
        $self->{URI_STRING} = $uri_string;

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

sub getDBIString {
    my ($self) = @_;

    return $self->{URI_STRING};
}

sub buildGetAllRequest {
    my $request = "";

    $request .= "<nmwg:message type=\"SetupDataRequest\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= "<nmwg:metadata id=\"meta0\">\n";
    $request .= "  <topoid:subject xmlns:topoid=\"http://ogf.org/schema/network/topology/id/20070828/\">urn:ogf:network:domain=*:node=*:port=*:link=*</topoid:subject>\n";
    $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/characteristic/link/status/20070809</nmwg:eventType>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\" />\n";
    $request .= "</nmwg:message>\n";

    return ($request);
}

sub buildLinkRequest {
    my ($links, $time) = @_;
    my $request = "";

    $request .= "<nmwg:message type=\"SetupDataRequest\"\n";
    $request .= "  xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n\n";

    my %metadata_ids = ();
    my $i = 0;

    foreach my $link_id (@{ $links }) {
        $request .= "<nmwg:metadata id=\"meta$i\">\n";
        $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/characteristic/link/status/20070809</nmwg:eventType>\n";
        $request .= "  <nmwg:subject id=\"sub$i\">\n";
        $request .= "    <nmtopo:link xmlns:nmtopo=\"http://ogf.org/schema/network/topology/base/20070828/\" id=\"".escapeString($link_id)."\" />\n";
        $request .= "  </nmwg:subject>\n";
        if (defined $time and $time ne "") {
            $request .= "  <nmwg:parameters>\n";
            $request .= "    <nmwg:parameter name=\"time\">".$time->getTime."</nmwg:parameter>\n";
            $request .= "  </nmwg:parameters>\n";
        }
        $request .= "</nmwg:metadata>\n";
        $request .= "<nmwg:data id=\"data$i\" metadataIdRef=\"meta$i\" />\n";

        $metadata_ids{"meta$i"} = $link_id;


        $i++;
    }

    $request .= "</nmwg:message>\n";

    return ($request, \%metadata_ids);
}

sub buildUpdateRequest {
    my ($link_id, $time, $knowledge_level, $oper_value, $admin_value, $do_update) = @_;
    my $request = "";

    $request .= "<nmwg:message type=\"MeasurementArchiveStoreRequest\"\n";
    $request .= "        xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= "<nmwg:metadata id=\"meta0\">\n";
    $request .= "  <nmwg:subject id=\"sub0\">\n";
    $request .= "    <nmtopo:link xmlns:nmtopo=\"http://ogf.org/schema/network/topology/base/20070828/\" id=\"".escapeString($link_id)."\" />\n";
    $request .= "  </nmwg:subject>\n";
    $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/characteristic/link/status/20070809</nmwg:eventType>\n";
    $request .= "  <nmwg:parameters>\n";
    $request .= "    <nmwg:parameter name=\"knowledge\">$knowledge_level</nmwg:parameter>\n";
    if ($do_update != 0) {
        $request .= "    <nmwg:parameter name=\"update\">yes</nmwg:parameter>\n";
    }
    $request .= "  </nmwg:parameters>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\">\n";
    $request .= "<ifevt:datum xmlns:ifevt=\"http://ggf.org/ns/nmwg/event/status/base/2.0/\" timeType=\"unix\" timeValue=\"$time\">\n";
    $request .= "  <ifevt:stateAdmin>$admin_value</ifevt:stateAdmin>\n";
    $request .= "  <ifevt:stateOper>$oper_value</ifevt:stateOper>\n";
    $request .= "</ifevt:datum>\n";
    $request .= "</nmwg:data>\n";
    $request .= "</nmwg:message>\n";

    my %metadata_ids = ( "meta0" => $link_id );

    return ($request, \%metadata_ids);
}

sub getStatusArchive {
    my ($self, $request, $meta_ids) = @_;
    my ($status, $res);

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if (not defined $host and not defined $port and not defined $endpoint) {
        my $msg = "Specified argument is not a URI";
        return (-1, $msg);
    }

    ($status, $res) = consultArchive($host, $port, $endpoint, $request);
    if ($status != 0) {
        my $msg = "Error consulting archive: $res";
        return (-1, $msg);
    }

    my $stat_msg = $res;

    my %links = ();

    foreach my $data ($stat_msg->getElementsByLocalName("data")) {
        foreach my $metadata ($stat_msg->getElementsByLocalName("metadata")) {
            my $mdidref = $metadata->getAttribute("metadataIdRef");
            my $mdid = $metadata->getAttribute("id");

            next if (not defined $mdidref and not defined $mdid);

            if ($data->getAttribute("metadataIdRef") eq $mdid) {
                my $link_id;

                if (not defined $meta_ids) {
                    $link_id = findvalue($metadata, './topoid:subject');
                } else {
                    $link_id = $meta_ids->{$mdid};
                    if (not defined $link_id and defined $mdidref) {
                        $link_id = $meta_ids->{$mdidref};
                    }
                }

                if (not defined $link_id or $link_id eq "") {
                    my $msg = "Response does not have an associated a link id";
                    return (-1, $msg);
                }

                ($status, $res) = parseResponse($link_id, $data, \%links);
                if ($status != 0) {
                    my $msg = "Error parsing archive response: $res";
                    return (-1, $msg);
                }
            }
        }
    }

    return (0, \%links);
}

sub parseResponse {
    my ($link_id, $data, $links) = @_;

    foreach my $link ($data->getElementsByLocalName("datum")) {
        my $time = $link->getAttribute("timeValue");
        my $time_type = $link->getAttribute("timeType");
        my $start_time = $link->getAttribute("startTime");
        my $start_time_type = $link->getAttribute("startTimeType");
        my $end_time = $link->getAttribute("endTime");
        my $end_time_type = $link->getAttribute("endTimeType");
        my $knowledge = $link->getAttribute("knowledge");
        my $operStatus = findvalue($link, "./ifevt:stateOper");
        my $adminStatus = findvalue($link, "./ifevt:stateAdmin");

        if (not defined $knowledge or not defined $operStatus or not defined $adminStatus or $adminStatus eq "" or $operStatus eq "" or $knowledge eq "") {
            my $msg = "Response from server contains incomplete link status: ".$link->toString;
            return (-1, $msg);
        }

        if ((not defined $time or not defined $time_type) and (not defined $start_time or not defined $start_time_type or not defined $end_time or not defined $end_time_type)) {
            my $msg = "Response from server contains incomplete link status: ".$link->toString;
            return (-1, $msg);
        }

        if (defined $time_type and $time_type ne "unix") {
            my $msg = "Response from server contains invalid time type \"".$time_type."\": ".$link->toString;
            return (-1, $msg);
        }

        if (defined $start_time_type and $start_time_type ne "unix") {
            my $msg = "Response from server contains invalid time type \"".$start_time_type."\": ".$link->toString;
            return (-1, $msg);
        }

        if (defined $end_time_type and $end_time_type ne "unix") {
            my $msg = "Response from server contains invalid time type \"".$end_time_type."\": ".$link->toString;
            return (-1, $msg);
        }

        my $new_link;

        if (not defined $start_time) {
            $new_link = new perfSONAR_PS::Status::Link($link_id, $knowledge, $time, $time, $operStatus, $adminStatus);
        } else {
            $new_link = new perfSONAR_PS::Status::Link($link_id, $knowledge, $start_time, $end_time, $operStatus, $adminStatus);
        }

        if (not defined $links->{$link_id}) {
            $links->{$link_id} = ();
        }

        push @{ $links->{$link_id} }, $new_link;
    }

    return (0, "");
}

sub getAll {
    my ($self) = @_;

    my ($request) = buildGetAllRequest;

    my ($status, $res) = $self->getStatusArchive($request, undef);

    return ($status, $res);
}

sub getLinkHistory {
    my ($self, $link_ids) = @_;

    my ($request, $metas) = buildLinkRequest($link_ids, perfSONAR_PS::Time->new("point", -1));

    my ($status, $res) = $self->getStatusArchive($request, $metas);

    return ($status, $res);
}

sub getLinkStatus {
    my ($self, $link_ids, $time) = @_;

    my ($request, $metas) = buildLinkRequest($link_ids, $time);

    my ($status, $res) = $self->getStatusArchive($request, $metas);

    return ($status, $res);
}

sub updateLinkStatus {
    my($self, $time, $link_id, $knowledge_level, $oper_value, $admin_value, $do_update) = @_;
    my $prev_end_time;

    $oper_value = lc($oper_value);
    $admin_value = lc($admin_value);

    if (!isValidOperState($oper_value)) {
        return (-1, "Invalid operational state: $oper_value");
    }

    if (!isValidAdminState($admin_value)) {
        return (-1, "Invalid administrative state: $admin_value");
    }

    my ($request, $mdids) = buildUpdateRequest($link_id, $time, $knowledge_level, $oper_value, $admin_value, $do_update);

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if (not defined $host and not defined $port and not defined $endpoint) {
        my $msg = "Specified argument is not a URI";
        return (-1, $msg);
    }

    my ($status, $res) = consultArchive($host, $port, $endpoint, $request);
    if ($status != 0) {
        my $msg = "Error consulting archive: $res";
        return (-1, $msg);
    }

    my $find_res;

    $find_res = find($res, "./nmwg:data", 0);
    if ($find_res) {
        foreach my $data ($find_res->get_nodelist) {
            my $metadata = find($res, "./nmwg:metadata[\@id='".$data->getAttribute("metadataIdRef")."']", 1);
            if (not defined $metadata) {
                return (-1, "No metadata in response");
            }

            my $eventType = findvalue($metadata, "nmwg:eventType");
            if (defined $eventType and $eventType =~ /^error\./) {
                my $error_msg = findvalue($data, "./nmwgr:datum");
                $error_msg = "Unknown error" if (not defined $error_msg or $error_msg eq "");
                return (-1, $error_msg);
            } elsif (defined $eventType and $eventType =~ /^success\./) {
                return (0, "Success");
            }
        }
    }

    return (-1, "Response message does not contain a valid response");
}

1;

__END__

=head1 NAME

perfSONAR_PS::Client::Status::MA - A module that provides methods for
interacting with Status MA servers.

=head1 DESCRIPTION

This module allows one to interact with the Status MA via its Web Services
interface. The API provided is identical to the API for interacting with the
MA database directly. Thus, a client written to read from or update a Status MA
can be easily modified to interact directly with its underlying database
allowing more efficient interactions if required.

The module is to be treated as an object, where each instance of the object
represents a connection to a single database. Each method may then be invoked
on the object for the specific database.  

=head1 SYNOPSIS

use perfSONAR_PS::Client::Status::MA;

my $status_client = new perfSONAR_PS::Client::Status::MA("http://localhost:4801/axis/services/status");
if (not defined $status_client) {
    print "Problem creating client for status MA\n";
    exit(-1);
}

my ($status, $res) = $status_client->open;
if ($status != 0) {
    print "Problem opening status MA: $res\n";
    exit(-1);
}

($status, $res) = $status_client->getAll();
if ($status != 0) {
    print "Problem getting complete database: $res\n";
    exit(-1);
}

my @links = (); 

foreach my $id (keys %{ $res }) {
    print "Link ID: $id\n";

    foreach my $link ( @{ $res->{$id} }) {
        print "\t" . $link->getStartTime . " - " . $link->getEndTime . "\n";
        print "\t-Knowledge Level: " . $link->getKnowledge . "\n";
        print "\t-operStatus: " . $link->getOperStatus . "\n";
        print "\t-adminStatus: " . $link->getAdminStatus . "\n";
    }

    push @links, $id;
}

($status, $res) = $status_client->getLinkStatus(\@links, "");
if ($status != 0) {
    print "Problem obtaining most recent link status: $res\n";
    exit(-1);
}

foreach my $id (keys %{ $res }) {
    print "Link ID: $id\n";

    foreach my $link ( @{ $res->{$id} }) {
        print "-operStatus: " . $link->getOperStatus . "\n";
        print "-adminStatus: " . $link->getAdminStatus . "\n";
    }
}

($status, $res) = $status_client->getLinkHistory(\@links);
if ($status != 0) {
    print "Problem obtaining link history: $res\n";
    exit(-1);
}

foreach my $id (keys %{ $res }) {
    print "Link ID: $id\n";

    foreach my $link ( @{ $res->{$id} }) {
        print "-operStatus: " . $link->getOperStatus . "\n";
        print "-adminStatus: " . $link->getAdminStatus . "\n";
    }
}

=head1 DETAILS

=head1 API

The API os perfSONAR_PS::Client::Status::MA is rather simple and greatly
resembles the messages types received by the server. It is also identical to
the perfSONAR_PS::Client::Status::SQL API allowing easy construction of
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
    a hash with the key being the link id. Each element of the hash is an array of
    perfSONAR_PS::Status::Link structures containing a the status of the
    specified link at a certain point in time.

=head2 getLinkHistory($self, $link_ids)

    The getLinkHistory function returns the complete history of a set of links. The
    $link_ids parameter is a reference to an array of link ids. It returns the
    results as a hash with the key being the link id. Each element of the hash is
    an array of perfSONAR_PS::Status::Link structures containing a the status
    of the specified link at a certain point in time.

=head2 getLinkStatus($self, $link_ids, $time)

    The getLinkStatus function returns the link status at the specified time. The
    $link_ids parameter is a reference to an array of link ids. $time is a
    perfSONAR_PS::Time element describing the time at which you'd like to know
    each link's status. If $time is undefined, it returns the most recent
    information it has about each link. It returns the results as a hash with
    the key being the link id. Each element of the hash is an array of
    perfSONAR_PS::Status::Link structures containing a the status of the
    specified link at a certain point in time.

=head2 updateLinkStatus($self, $time, $link_id, $knowledge_level, $oper_value, $admin_value, $do_update) 

    The updateLinkStatus function adds a new data point for the specified link.
    $time is a unix timestamp corresponding to when the measurement occured. $link_id is the link to
    update. $knowledge_level says whether or not this measurement can tell us
    everything about a given link ("full") or whether the information only
    corresponds to one side of the link("partial"). $oper_value is the current
    operational status and $admin_value is the current administrative status.
    $do_update is currently unused in this context, meaning that all intervals
    added have cover the second that the measurement occurred.

=head1 SEE ALSO

L<perfSONAR_PS::Status::Link>, L<perfSONAR_PS::Client::Status::SQL>, L<Log::Log4perl>
L<perfSONAR_PS::Common>, L<perfSONAR_PS::Status::Common>, L<perfSONAR_PS::Transport>,
L<perfSONAR_PS::Time>

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
