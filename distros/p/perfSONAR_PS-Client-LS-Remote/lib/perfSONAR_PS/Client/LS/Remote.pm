package perfSONAR_PS::Client::LS::Remote;

=head1 NAME

perfSONAR_PS::Client::LS::Remote - A module that provides a client API for an LS

=head1 DESCRIPTION

This module aims to offer simple methods for dealing with requests for information, and the
related tasks of interacting with backend storage.

=head1 SYNOPSIS

    use perfSONAR_PS::Client::LS::Remote;

    my %conf = ();
    $conf{"SERVICE_ACCESSPOINT"} = "http://someorganization.org:8080/perfSONAR_PS/services/service";
    $conf{"SERVICE_NAME"} = "Some Organization's Service MA"
    $conf{"SERVICE_TYPE"} = "MA"
    $conf{"SERVICE_DESCRIPTION"} = "Service MA"

    my $ls = "http://someorganization.org:8080/perfSONAR_PS/services/LS";

    my $ls_client = perfSONAR_PS::Client::LS::Remote->new($ls, \%conf, \%ns);

    # or
    # $ls_client = perfSONAR_PS::Client::LS::Remote->new;
    # $ls_client->setURI($ls);
    # $ls_client->setConf(\%conf);
    # $ls_client->setNamespaces(\%ns);

    $ls_client->registerStatic(\@data);

    $ls_client->sendKeepalive($conf{"SERVICE_ACCESSPOINT"});

    $ls_client->sendDeregister($conf{"SERVICE_ACCESSPOINT"});

    my $ls2 = "http://otherorganization.org:8080/perfSONAR_PS/services/LS";

    my $ls_client2 = perfSONAR_PS::Client::LS::Remote->new($ls2);

    my %queries = ();

    $queries{"req1"} = "";
    $queries{"req1"} .= "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $queries{"req1"} .= "for \$data in /nmwg:store/nmwg:data\n";
    $queries{"req1"} .= "  let \$metadata_id := \$data/\@metadataIdRef\n";
    $queries{"req1"} .= "  where \$data//*:link[\@id=\"link1\"] and \$data//nmwg:eventType[text()=\"http://ggf.org/ns/nmwg/characteristic/link/status/20070809\"]\n";
    $queries{"req1"} .= " return /nmwg:store/nmwg:metadata[\@id=\$metadata_id]\n";

    $queries{"req2"} = "";
    $queries{"req2"} .= "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $queries{"req2"} .= "for \$data in /nmwg:store/nmwg:data\n";
    $queries{"req2"} .= "  let \$metadata_id := \$data/\@metadataIdRef\n";
    $queries{"req2"} .= "  where \$data//*:link[\@id=\"link2\"] and \$data//nmwg:eventType[text()=\"http://ggf.org/ns/nmwg/characteristic/link/status/20070809\"]\n";
    $queries{"req2"} .= " return /nmwg:store/nmwg:metadata[\@id=\$metadata_id]\n";

    my ($status, $res) = $ls_client2->query(\%queries);
    if ($status != 0 or not defined $res{"req1"} or not defined $res{"req2"}) {
      print "Error: querying $ls2 failed\n";
      exit(-1);
    }

    my ($query_status, $query_res);

    ($query_status, $query_res) = $res{"req1"};

    if ($query_status != 0) {
      print "Couldn't get information on query req1: ".$query_res."\n";
      exit(-1);
    } else {
      print "Results for res1: ".$query_res->toString()."\n";
    }

    ($query_status, $query_res) = $res{"req2"};

    if ($query_status != 0) {
      print "Couldn't get information on query req2: ".$query_res."\n";
      exit(-1);
    } else {
      print "Results for res1: ".$query_res->toString()."\n";
    }

=cut

use fields 'URI', 'CONF', 'CHUNK', 'ALIVE', 'FIRST';

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Common;
use perfSONAR_PS::Transport;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Client::Echo;

our $VERSION = 0.09;

=head1 API

The offered API is simple, but offers the key functions we need in a measurement archive.

=head2 new ($package, $uri, \%conf) 

The parameters are the URI of the Lookup Service, a %conf describing the service for registration purposes.

The %conf can have 4 keys in it:

SERVICE_NAME - The name of the service registering data
SERVICE_ACCESSPOINT - The URL for the service registering data
SERVICE_TYPE - The type (MA, LS, etc) of the service registering data
SERVICE_DESCRIPTION - A description of the service registering data

=cut

sub new {
    my ($package, $uri, $conf) = @_;

    my $self = fields::new($package);

    $self->{URI} = $uri;

    if(defined $conf and $conf ne "") {
        $self->{CONF} = \%{$conf};
    }

    $self->{CHUNK} = 50;

    $self->{ALIVE} = 0;
    $self->{FIRST} = 1;

    return $self;
}

=head2 setURI ($self, $uri)
	(Re-)Sets the value for the LS URI.
=cut

sub setURI {
    my ($self, $uri) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");

    if(defined $uri and $uri ne "") {
        $self->{URI} = $uri;
    }
    else {
        $logger->error("Missing argument.");
    }
    return;

}

=head2 setConf ($self, \%conf)
    (Re-)Sets the value for the 'conf' hash.
=cut
sub setConf {
    my ($self, $conf) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");

    if(defined $conf and $conf ne "") {
        $self->{CONF} = \%{$conf};
    }
    else {
        $logger->error("Missing argument.");
    }
    return;
}

=head2 createKey ($self, $key)
    Creates a 'key' value that is used to access the LS.
=cut
sub createKey {
    my($self, $lsKey) = @_;
    my $key = "    <nmwg:key id=\"key.".genuid()."\">\n";
    $key = $key . "      <nmwg:parameters id=\"parameters.".genuid()."\">\n";
    if (defined $lsKey and $lsKey ne "") {
        $key = $key . "        <nmwg:parameter name=\"lsKey\">".$lsKey."</nmwg:parameter>\n";
    } else {
        $key = $key . "        <nmwg:parameter name=\"lsKey\">".$self->{CONF}->{"SERVICE_ACCESSPOINT"}."</nmwg:parameter>\n";
    }
    $key = $key . "      </nmwg:parameters>\n";
    $key = $key . "    </nmwg:key>\n";
    return $key;
}

=head2 createService ($self)
    Creates the 'service' subject (description of the service) for LS registration.
=cut
sub createService {
    my($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");
    my $service = "    <perfsonar:subject xmlns:perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\">\n";
    $service = $service . "      <psservice:service xmlns:psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\">\n";
    $service = $service . "        <psservice:serviceName>".$self->{CONF}->{"SERVICE_NAME"}."</psservice:serviceName>\n" if (defined $self->{CONF}->{"SERVICE_NAME"});
    $service = $service . "        <psservice:accessPoint>".$self->{CONF}->{"SERVICE_ACCESSPOINT"}."</psservice:accessPoint>\n" if (defined $self->{CONF}->{"SERVICE_ACCESSPOINT"});
    $service = $service . "        <psservice:serviceType>".$self->{CONF}->{"SERVICE_TYPE"}."</psservice:serviceType>\n" if (defined $self->{CONF}->{"SERVICE_TYPE"});
    $service = $service . "        <psservice:serviceDescription>".$self->{CONF}->{"SERVICE_DESCRIPTION"}."</psservice:serviceDescription>\n" if (defined $self->{CONF}->{"SERVICE_DESCRIPTION"});
    $service = $service . "      </psservice:service>\n";
    $service = $service . "    </perfsonar:subject>\n";
    return $service;
}

=head2 callLS ($self, $sender, $message)
    Given a message and a sender, contact an LS and parse the results.
=cut
sub callLS {
    my($self, $sender, $message) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");
    my $error;
    my $responseContent = $sender->sendReceive(makeEnvelope($message), "", \$error);
    if($error ne "") {
        $logger->error("sendReceive failed: $error");
        return -1;
    }
    my $parser = XML::LibXML->new();
    if(defined $responseContent and $responseContent ne "" and
            not ($responseContent =~ m/^\d+/x)) {
        my $doc = "";
        eval {
            $doc = $parser->parse_string($responseContent);
        };
        if($@) {
            $logger->error("Parser failed: ".$@);
            return -1;
        }
        else {
            my $msg = $doc->getDocumentElement->getElementsByTagNameNS("http://ggf.org/ns/nmwg/base/2.0/", "message")->get_node(1);
            if($msg) {
                my $eventType = findvalue($msg, "./nmwg:metadata/nmwg:eventType");
                if(defined $eventType and $eventType =~ m/success/x) {
                    return 0;
                }
            }
        }
    }
    return -1;
}

=head2 sendDeregister ($self, $key)
    Deregisters the data with the specified key
=cut
sub sendDeregister {
    my ($self, $key) = @_;

    if (not defined $self->{URI}) {
        return -1;
    }

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($self->{URI});
    if (not defined $host and not defined $port and not defined $endpoint) {
        return -1;
    }

    my $sender = new perfSONAR_PS::Transport($host, $port, $endpoint);


    my $doc = perfSONAR_PS::XML::Document_string->new();
    startMessage($doc, "message.".genuid(), "", "LSDeregisterRequest", "", {perfsonar=>"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/", psservice=>"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/"});

    my $mdID = "metadata.".genuid();
    createMetadata($doc, $mdID, "", createKey($self, $key), undef);
    createData($doc, "data.".genuid(), $mdID, "", undef);
    endMessage($doc);

    return callLS($self, $sender, $doc->getValue());
}

=head2 sendKeepalive ($self, $key)
    Sends a keepalive message for the data with the specified key
=cut
sub sendKeepalive {
    my ($self, $key) = @_;

    if (not defined $self->{URI}) {
        return -1;
    }

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($self->{URI});
    if (not defined $host and not defined $port and not defined $endpoint) {
        return -1;
    }

    my $sender = new perfSONAR_PS::Transport($host, $port, $endpoint);


    my $doc = perfSONAR_PS::XML::Document_string->new();
    startMessage($doc, "message.".genuid(), "", "LSKeepaliveRequest", "", {perfsonar=>"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/", psservice=>"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/"});

    my $mdID = "metadata.".genuid();
    createMetadata($doc, $mdID, "", createKey($self, $key), undef);
    createData($doc, "data.".genuid(), $mdID, "", undef);
    endMessage($doc);

    return callLS($self, $sender, $doc->getValue());
}

=head2 registerStatic ($self, \@data_ref)
    Performs registration of 'static' data with an LS.  Static in this sense
    indicates that the data in the underlying storage DOES NOT change.  This
    function uses special messages that intend to simply keep the data alive,
    not worrying at all if something comes in that is new or goes away that is
    old.
=cut
sub registerStatic {
    my($self, $data_ref) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");

    if (not defined $self->{URI}) {
        return -1;
    }

    if(!$self->{ALIVE}) {
        my $echo_service = perfSONAR_PS::Client::Echo->new($self->{URI});
        my ($status, $res) = $echo_service->ping();
        if ($status == -1) {
            $logger->error("Ping to ".$self->{URI}." failed: $res");
            return -1;
        }
        $self->{ALIVE} = 1;
    }

    if($self->{FIRST}) {
        if ($self->sendDeregister($self->{CONF}->{"SERVICE_ACCESSPOINT"}) == 0) {
            $logger->debug("Nothing registered.");
        }
        else {
            $logger->debug("Removed old registration.");
        }

        my @resultsString = ();

        @resultsString = @{$data_ref};

        if($#resultsString != -1) {
            my ($status, $res) = $self->__register(createService($self), $data_ref);
            if ($status == -1) {
                $logger->error("Unable to register data with LS.");
                $self->{ALIVE} = 0;
            }
        }
    }
    else {
        if ($self->sendKeepalive() == -1) {
            my @resultsString = ();

            @resultsString = @{$data_ref};

            if($#resultsString != -1) {
                my ($status, $res) = $self->__register(createService($self), $data_ref);
                if ($status == -1) {
                    $logger->error("Unable to register data with LS.");
                    $self->{ALIVE} = 0;
                    return -1;
                }
            }
        }
    }

    $self->{FIRST} = 0 if $self->{FIRST};
    return 0;
}

=head2 __register ($self, $subject, $data_ref)
    Performs the actual data registration. Unlike the above registration
    functions, this function does not try to perform any of the
    keepalive/deregister registration tricks. It simply registers the specified
    data. As part of the registration, it splits the data into chunks and
    registers each independently.
=cut
sub __register {
    my ($self, $subject, $data_ref) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");

    if (not defined $self->{URI}) {
        return -1
    }

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($self->{URI});
    if (not defined $host and not defined $port and not defined $endpoint) {
        return -1
    }

    my $sender = new perfSONAR_PS::Transport($host, $port, $endpoint);

    my @data = @{ $data_ref };
    my $iterations = int((($#data+1)/$self->{CHUNK}));
    my $x = 0;

    for(my $y = 1; $y <= ($iterations+1); $y++) {
        my $doc = perfSONAR_PS::XML::Document_string->new();
        startMessage($doc, "message.".genuid(), "", "LSRegisterRequest", "", {perfsonar=>"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/", psservice=>"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/"});
        my $mdID = "metadata.".genuid();
        createMetadata($doc, $mdID, "", createService($self), undef);
        for(; $x < ($y*$self->{CHUNK}) and $x <= $#data; $x++) {
            createData($doc, "data.".genuid(), $mdID, $data[$x], undef);
        }
        endMessage($doc);
        unless(callLS($self, $sender, $doc->getValue()) == 0) {
            $logger->error("Unable to register data with LS.");
            return -1;
        }
    }

    return 0;
}

=head2 registerDynamic ($self, \@data_ref)
    Performs registration of 'dynamic' data with an LS.  Dynamic in this sense
    indicates that the data in the underlying storage DOES change.  This
    function uses special messages that will remove all old data and insert
    everything brand new with each registration. 
=cut
sub registerDynamic {
    my($self, $data_ref) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");

    if (not defined $self->{URI}) {
        return -1;
    }

    if(!$self->{ALIVE}) {
        my $echo_service = perfSONAR_PS::Client::Echo->new($self->{URI});
        my ($status, $res) = $echo_service->ping();
        if ($status == -1) {
            $logger->error("Ping to ".$self->{URI}." failed: $res");
            return -1;
        }

        $self->{ALIVE} = 1;
    }

    if($self->{FIRST}) {
        if ($self->sendDeregister($self->{CONF}->{"SERVICE_ACCESSPOINT"}) == 0) {
            $logger->debug("Nothing registered.");
        }
        else {
            $logger->debug("Removed old registration.");
        }

        my @resultsString = @{$data_ref};

        if($#resultsString != -1) {
            if ($self->__register(createService($self), $data_ref) == -1) {
                $logger->error("Unable to register data with LS.");
                $self->{ALIVE} = 0;
            }
        }
    } else {
        my @resultsString = @{$data_ref};

        my $subject = "";
        if ($self->sendKeepalive() == -1) {
            $subject = createService($self);
        }
        else {
            $subject = createKey($self, $self->{CONF}->{SERVICE_ACCESSPOINT})."\n".createService($self);
        }

        if($#resultsString != -1) {
            if ($self->__register($subject, $data_ref) == -1) {
                $logger->error("Unable to register data with LS.");
                $self->{ALIVE} = 0;
                return -1;
            }
        }
    }

    $self->{FIRST} = 0 if ($self->{FIRST});

    return 0;
}

=head2 query ($self, \%queries)
    This function sends the specified queries to the LS and returns the
    results.  The queries are given as a hash table with each key/value pair
    being an identifier/a query. Each query gets executed and the returned
    value is a hash containing the same identifiers as keys, but instead of
    pointing to queries, they point to an array containing a status and a
    result. The status is either 0 or -1. If it's 0, the result is a pointer to
    the data element. If it's -1, the result is the error message.
=cut
sub query {
    my ($self, $queries) = @_;
    my $logger = get_logger("perfSONAR_PS::Client::LS::Remote");

    if (not defined $self->{URI}) {
        return -1;
    }

    my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($self->{URI});
    if (not defined $host and not defined $port and not defined $endpoint) {
        return -1;
    }

    my $request = "";
    $request .= "<nmwg:message type=\"LSQueryRequest\" id=\"msg1\"\n";
    $request .= "     xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"\n";
    $request .= "     xmlns:xquery=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/\">\n";
    foreach my $query_id (keys %{ $queries }) {
        $request .= "  <nmwg:metadata id=\"perfsonar_ps.meta.$query_id\">\n";
        $request .= "    <xquery:subject id=\"sub1\">\n";
        $request .= $queries->{$query_id};
        $request .= "    </xquery:subject>\n";
        $request .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0</nmwg:eventType>\n";
        $request .= "  <xquery:parameters id=\"params.1\">\n";
        $request .= "    <nmwg:parameter name=\"lsOutput\">native</nmwg:parameter>\n";
        $request .= "  </xquery:parameters>\n";
        $request .= "  </nmwg:metadata>\n";
        $request .= "  <nmwg:data metadataIdRef=\"perfsonar_ps.meta.$query_id\" id=\"data.$query_id\"/>\n";
    }
    $request .= "</nmwg:message>\n";

    my ($status, $res) = consultArchive($host, $port, $endpoint, $request);
    if ($status != 0) {
        my $msg = "Error consulting LS: $res";
        $logger->error($msg);
        return -1;
    }

    $logger->debug("Response: ".$res->toString);

    my %ret_structure = ();

    foreach my $d ($res->getChildrenByTagName("nmwg:data")) {
        foreach my $m ($res->getChildrenByTagName("nmwg:metadata")) {
            my $md_id = $m->getAttribute("id");
            my $md_idref = $m->getAttribute("metadataIdRef");
            my $d_idref = $d->getAttribute("metadataIdRef");

            if($md_id eq $d_idref) {
                my $query_id;
                my $eventType = findvalue($m, "nmwg:eventType");

                if (defined $md_idref and $md_idref =~ /perfsonar_ps\.meta\.(.*)/x) {
                    $query_id = $1;
                } elsif ($md_id =~ /perfsonar_ps\.meta\.(.*)/x) {
                    $query_id = $1;
                } else {
                    my $msg = "Received unknown response: $md_id/$md_idref";
                    $logger->error($msg);
                    next;
                }

                my @retval;
                if (defined $eventType and $eventType =~ /^error\./x) {
                    my $error_msg = findvalue($d, "./nmwgr:datum");
                    $error_msg = "Unknown error" if (not defined $error_msg or $error_msg eq "");
                    @retval = (-1, $error_msg);
                } else {
                    @retval = (0, $d);
                }

                $ret_structure{$query_id} = \@retval;
            }
        }
    }

    return (0, \%ret_structure);
}

1;


__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<perfSONAR_PS::Common>, L<perfSONAR_PS::Transport>,
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Client::Echo>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

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
