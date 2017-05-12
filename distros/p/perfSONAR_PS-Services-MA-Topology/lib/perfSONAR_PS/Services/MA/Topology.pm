package perfSONAR_PS::Services::MA::Topology;

=head1 NAME

perfSONAR_PS::Services::MA::Topology - A module that provides methods for a
Topology Service. The Topology Service can be used to make Topology Data
available to individuals via webservice interface.

=head1 DESCRIPTION

This module, in conjunction with other parts of the perfSONAR-PS framework,
handles specific messages from interested actors in search of Topology data.

There are two major message types that this service can act upon:
    QueryRequest/SetupDataRequest   - Allows queries to the database
    TopologyChangeRequest           - Allows updates to the topology database
=head1 API

=cut

use base 'perfSONAR_PS::Services::Base';

use fields 'CLIENT', 'LS_CLIENT', 'LOGGER';

use warnings;
use strict;
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Topology::Common;
use perfSONAR_PS::Client::Topology::XMLDB;
use perfSONAR_PS::Client::LS::Remote;
use perfSONAR_PS::ParameterValidation;

our $VERSION = 0.09;

=head2 init 
    Called at startup by the daemon when this particular module is loaded into
    the perfSONAR-PS deployment. Checks the configuration file for the necessary
    items and fills in others when needed. Initializes the backed metadata storage
    (Oracle Sleepycat XML Database). Finally the message handler registers the
    appropriate message types and eventTypes for this module. Any other
    'pre-startup' tasks should be placed in this function.
=cut
sub init {
    my ($self, $handler) = @_;

    $self->{LOGGER} = get_logger("perfSONAR_PS::Services::MA::Topology");

    if (not defined $self->{CONF}->{"topology"}->{"db_type"} or $self->{CONF}->{"topology"}->{"db_type"} eq q{}) {
        $self->{LOGGER}->error("No database type specified");
        return -1;
    }

    if (lc($self->{CONF}->{"topology"}->{"db_type"}) eq "xml") {
        if (not defined $self->{CONF}->{"topology"}->{"db_file"} or $self->{CONF}->{"topology"}->{"db_file"} eq q{}) {
            $self->{LOGGER}->error("You specified a Sleepycat XML DB Database, but then did not specify a database file (db_file)");
            return -1;
        }

        if (not defined $self->{CONF}->{"topology"}->{"db_environment"} or $self->{CONF}->{"topology"}->{"db_environment"} eq q{}) {
            $self->{LOGGER}->error("You specified a Sleepycat XML DB Database, but then did not specify a database name (db_environment)");
            return -1;
        }

        my $environment = $self->{CONF}->{"topology"}->{"db_environment"};
        if (defined $self->{DIRECTORY}) {
            if (!($environment =~ "^/")) {
                $environment = $self->{DIRECTORY}."/".$environment;
            }
        }

        my $read_only = 0;

        if (defined $self->{CONF}->{"topology"}->{"read_only"} and $self->{CONF}->{"topology"}->{"read_only"} == 1) {
            $read_only = 1;
        }

        my $file = $self->{CONF}->{"topology"}->{"db_file"};
        my %ns = getTopologyNamespaces();

        $self->{CLIENT}= new perfSONAR_PS::Client::Topology::XMLDB($environment, $file, \%ns, $read_only);
    } else {
        $self->{LOGGER}->error("Invalid database type specified");
        return -1;
    }

    if ($self->{CONF}->{"topology"}->{"enable_registration"}) {
        if (not defined $self->{CONF}->{"topology"}->{"service_accesspoint"} or $self->{CONF}->{"topology"}->{"service_accesspoint"} eq q{}) {
            $self->{LOGGER}->error("No access point specified for SNMP service");
            return -1;
        }

        if (not defined $self->{CONF}->{"topology"}->{"ls_instance"} or $self->{CONF}->{"topology"}->{"ls_instance"} eq q{}) {
            if (defined $self->{CONF}->{"ls_instance"} and $self->{CONF}->{"ls_instance"} ne q{}) {
                $self->{CONF}->{"topology"}->{"ls_instance"} = $self->{CONF}->{"ls_instance"};
            } else {
                $self->{LOGGER}->error("No LS instance specified for SNMP service");
                return -1;
            }
        }

        if (not defined $self->{CONF}->{"topology"}->{"ls_registration_interval"} or $self->{CONF}->{"topology"}->{"ls_registration_interval"} eq q{}) {
            if (defined $self->{CONF}->{"ls_registration_interval"} and $self->{CONF}->{"ls_registration_interval"} ne q{}) {
                $self->{CONF}->{"topology"}->{"ls_registration_interval"} = $self->{CONF}->{"ls_registration_interval"};
            } else {
                $self->{LOGGER}->warn("Setting registration interval to 30 minutes");
                $self->{CONF}->{"topology"}->{"ls_registration_interval"} = 1800;
            }
        } else {
            # turn the registration interval from minutes to seconds
            $self->{CONF}->{"topology"}->{"ls_registration_interval"} *= 60;
        }

        if(not defined $self->{CONF}->{"topology"}->{"service_description"} or
                $self->{CONF}->{"topology"}->{"service_description"} eq q{}) {
            $self->{CONF}->{"topology"}->{"service_description"} = "perfSONAR_PS Topology MA";
            $self->{LOGGER}->warn("Setting 'service_description' to 'perfSONAR_PS Topology MA'.");
        }

        if(not defined $self->{CONF}->{"topology"}->{"service_name"} or
                $self->{CONF}->{"topology"}->{"service_name"} eq q{}) {
            $self->{CONF}->{"topology"}->{"service_name"} = "Topology MA";
            $self->{LOGGER}->warn("Setting 'service_name' to 'Topology MA'.");
        }

        if(not defined $self->{CONF}->{"topology"}->{"service_type"} or
                $self->{CONF}->{"topology"}->{"service_type"} eq q{}) {
            $self->{CONF}->{"topology"}->{"service_type"} = "MA";
            $self->{LOGGER}->warn("Setting 'service_type' to 'MA'.");
        }
    }

    $handler->registerEventHandler("QueryRequest", "http://ggf.org/ns/nmwg/topology/20070809", $self);
#    $handler->registerEventHandler("KeepaliveRequest", "http://ggf.org/ns/nmwg/topology/20070809", $self);
#    $handler->registerEventHandler("AddRequest", "http://ggf.org/ns/nmwg/topology/20070809", $self);
#    $handler->registerEventHandler("UpdateRequest", "http://ggf.org/ns/nmwg/topology/20070809", $self);
#    $handler->registerEventHandler("RemoveRequest", "http://ggf.org/ns/nmwg/topology/20070809", $self);

    $handler->registerEventHandler("SetupDataRequest", "http://ggf.org/ns/nmwg/topology/query/xquery/20070809", $self);
    $handler->registerEventHandler("SetupDataRequest", "http://ggf.org/ns/nmwg/topology/query/all/20070809", $self);
    $handler->registerEventHandler("TopologyChangeRequest", "http://ggf.org/ns/nmwg/topology/change/add/20070809", $self);
    $handler->registerEventHandler("TopologyChangeRequest", "http://ggf.org/ns/nmwg/topology/change/update/20070809", $self);
    $handler->registerEventHandler("TopologyChangeRequest", "http://ggf.org/ns/nmwg/topology/change/replace/20070809", $self);

    return 0;
}

sub needLS {
    my ($self) = @_;

    return ($self->{CONF}->{"topology"}->{"enable_registration"});
}

=head2 registerLS($self $sleep_time)
    Given the service information (specified in configuration) and the contents
    of our xmldb backend, we can contact the specified LS and register the
    top-level identifiers (a summarized form of the elements in the database).
=cut
sub registerLS {
    my ($self, $sleep_time) = @_;
    my ($status, $res1);

    if (not defined $self->{LS_CLIENT}) {
        my %ls_conf = (
                LS_INSTANCE => $self->{CONF}->{"topology"}->{"ls_instance"},
                SERVICE_TYPE => $self->{CONF}->{"topology"}->{"service_type"},
                SERVICE_NAME => $self->{CONF}->{"topology"}->{"service_name"},
                SERVICE_DESCRIPTION => $self->{CONF}->{"topology"}->{"service_description"},
                SERVICE_ACCESSPOINT => $self->{CONF}->{"topology"}->{"service_accesspoint"},
                LS_REGISTRATION_INTERVAL => $self->{CONF}->{"topology"}->{"registration_interval"},
                  );

        my %ns = getTopologyNamespaces();
        $self->{LS_CLIENT} = new perfSONAR_PS::Client::LS::Remote($self->{CONF}->{"topology"}->{"ls_instance"}, \%ls_conf, \%ns);
    }

    ($status, $res1) = $self->{CLIENT}->open;
    if ($status != 0) {
        my $msg = "Couldn't open from database: $res1";
        $self->{LOGGER}->error($msg);
        return -1;
    }

    ($status, $res1) = $self->{CLIENT}->getUniqueIDs;
    if ($status != 0) {
        my $msg = "Couldn't get link nformation from database: $res1";
        $self->{LOGGER}->error($msg);
        return -1;
    }

    my @mds = ();
    my @md_ids = ();

    foreach my $info (@{ $res1 }) {
        my ($md, $md_id) = buildLSMetadata($info->{id}, $info->{type}, $info->{prefix}, $info->{uri});
        push @mds, $md;
    }

    $res1 = q{};

    my $n = $self->{LS_CLIENT}->registerDynamic(\@mds);

    if (defined $sleep_time) {
        ${$sleep_time} = $self->{CONF}->{"topology"}->{"ls_registration_interval"};
    }

    return $n;
}

=head2 buildLSMetadata ($id, $type, $prefix, $url)
    This function is used to build the metadata that is registered with the LS.
    This element contains the prefix and the local name of the element to be
    register as well as the id for that element. 
=cut
sub buildLSMetadata {
    my ($id, $type, $prefix, $uri) = @_;
    my $md = q{};
    my $md_id = "meta".genuid();

    $md .= "<nmwg:metadata id=\"$md_id\">\n";
    $md .= "<nmwg:subject id=\"sub0\">\n";
    if (not defined $prefix or $prefix eq q{}) {
    $md .= " <$type xmlns=\"$uri\" id=\"$id\" />\n";
    } else {
    $md .= " <$prefix:$type xmlns:$prefix=\"$uri\" id=\"$id\" />\n";
    }
    $md .= "</nmwg:subject>\n";
    $md .= "<nmwg:eventType>topology</nmwg:eventType>\n";
    $md .= "<nmwg:eventType>http://ggf.org/ns/nmwg/topology/query/all/20070809</nmwg:eventType>\n";
    $md .= "<nmwg:eventType>http://ggf.org/ns/nmwg/topology/query/xquery/20070809</nmwg:eventType>\n";
    $md .= "<nmwg:eventType>http://ggf.org/ns/nmwg/topology/change/add/20070809</nmwg:eventType>\n";
    $md .= "<nmwg:eventType>http://ggf.org/ns/nmwg/topology/change/update/20070809</nmwg:eventType>\n";
    $md .= "<nmwg:eventType>http://ggf.org/ns/nmwg/topology/change/replace/20070809</nmwg:eventType>\n";
    $md .= "</nmwg:metadata>\n";

    return ($md, $md_id);
}

=head2 handleEvent
    This is the function that is called by the daemon whenever a metadata/data
    pair with one of our eventTypes is found in a message we've regeistered in.
=cut
sub handleEvent {
    my ($self, @args) = @_;
      my $parameters = validateParams(@args,
            {
                output => 1,
                messageId => 1,
                messageType => 1,
                messageParameters => 1,
                eventType => 1,
                subject => 1,
                filterChain => 1,
                data => 1,
                rawRequest => 1,
                doOutputMetadata => 1,
            });

    my $output = $parameters->{"output"};
    my $messageId = $parameters->{"messageId"};
    my $messageType = $parameters->{"messageType"};
    my $message_parameters = $parameters->{"messageParameters"};
    my $eventType = $parameters->{"eventType"};
    my $d = $parameters->{"data"};
    my $raw_request = $parameters->{"rawRequest"};
    my @subjects = @{ $parameters->{"subject"} };
    my $md = $subjects[0];

    my @filters = @{ $parameters->{"filterChain"} };
    if ($#filters > -1) {
        throw perfSONAR_PS::Error_compat("error.ma.select", "Topology Service does not yet support filtering");
    }

    my ($status, $res) = $self->{CLIENT}->open;
    if ($status != 0) {
        my $msg = "Couldn't open database";
        $self->{LOGGER}->error("Error changing topology: $res");
        throw perfSONAR_PS::Error_compat("error.topology.ma", $msg);
    } 

    if ($messageType eq "SetupDataRequest") {
        $self->handleSetupDataRequest($output, $eventType, $md, $d);
    } elsif ($messageType eq "TopologyChangeRequest") {
        $self->handleChangeTopologyRequest($output, $eventType, $md, $d);
    } elsif ($messageType eq "QueryRequest") {
        $self->handleQueryRequest($output, $eventType, $md, $d);
#    } elsif ($messageType eq "AddRequest") {
#        $self->handleChangeTopologyRequest($output, "add", $m, $d);
#    } elsif ($messageType eq "UpdateRequest") {
#        $self->handleChangeTopologyRequest($output, "update", $m, $d);
#    } elsif ($messageType eq "RemoveRequest") {
#        $self->handleChangeTopologyRequest($output, "remove", $m, $d);
    }

    return;
}

=head2 handleQueryRequest ($self, $output, $eventType, $m, $d)
    This function handles the (hopefully to be standardized) QueryRequest
    message. The semantics of the message are as follows:

    If no subject is included, the semantics are "give me the whole database",
    and a XQuery for "//*" (i.e. everything) is submitted to the backend database.

    If an xquery subject is included, the semantics are "use the included
    XQuery to query the database". It simply passes the included XQuery to the
    backend database.

    If any other subject is included, an invalid subject error is thrown.
=cut
sub handleQueryRequest {
    my ($self, $output, $eventType, $m, $d) = @_;

    my $subjects = find($m, "./*[local-name()='subject']", 0);
    if ($subjects->size() > 1) {
        throw perfSONAR_PS::Error_compat("error.ma.subject", "Multiple subjects specified");
    }

    my $xquery;

    if ($subjects->size() == 0) {
        # no subject is the query all request
        $xquery = "//*";
    } else{
        my $subject = $subjects->get_node(1);
        if ($subject->namespaceURI() eq "http://ggf.org/ns/nmwg/tools/org/perfsonar/xquery/1.0/") {
            $xquery = $subject->textContent;
        } else {
            throw perfSONAR_PS::Error_compat("error.ma.subject", "Invalid subject type: ".$subject->namespaceURI());
        }
    }

    my ($status, $res) = $self->{CLIENT}->xQuery($xquery);
    if ($status != 0) {
        my $msg = "Database query failed: $res";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat("error.common.storage.query", $msg);
    }

    createData($output, "data.".genuid(), $m->getAttribute("id"), $res, undef);
    
    return;
}

=head2 handleSetupDataRequest ($self, $output, $eventType, $m, $d)
    This function handles the older protocol's query mechanism.
    The semantics of the message are as follows:

    If an "http://ggf.org/ns/nmwg/topology/query/all/20070809" eventType is
    included in the metadata, the entire backend database is returned.

    If an "http://ggf.org/ns/nmwg/topology/query/xquery/20070809" eventType is
    included in the metadata, an xquery subject must be included as well. The
    xquery inside the xquery subject will be passed to the backend database.
=cut
sub handleSetupDataRequest {
    my ($self, $output, $eventType, $m, $d) = @_;
    my ($status, $res);
    my $dataContent;

    if ($eventType eq "http://ggf.org/ns/nmwg/topology/query/all/20070809") {
        ($status, $res) = $self->{CLIENT}->getAll;
        if ($status != 0) {
            my $msg = "Database dump failed: $res";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat("error.common.storage.fetch", $msg);
        }

        $dataContent = $res->toString;
    } elsif ($eventType eq "http://ggf.org/ns/nmwg/topology/query/xquery/20070809") {
        my $query = findvalue($m, "./xquery:subject");

        if (not defined $query or $query eq q{}) {
            my $msg = "No query given in request";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat("error.topology.query.query_not_found", $msg);
        }

        my ($status, $res) = $self->{CLIENT}->xQuery($query);
        if ($status != 0) {
            my $msg = "Database query failed: $res";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat("error.common.storage.query", $msg);
        }

        $dataContent = $res;
    }

    createData($output, "data.".genuid(), $m->getAttribute("id"), $dataContent, undef);

    return;
}

=head2 handleChangeTopologyRequest 
    The hope is to standardize the information changing protocol between the LS
    and the Topology Service. In the interim, this handler handle metadata/data
    pairs corresponding to the current TS protocol.

    The metadata contains an eventType specifying how the data should modify
    the backend database and the data contains a topology wrapper containing
    the topology elements to add or update.

    If the eventType is "http://ggf.org/ns/nmwg/topology/change/add/20070809",
    the elements in the data segment are added to the database. If any of the
    elements (based on identifiers), already exist in the database, an error is
    returned. 

    If the eventType is
    "http://ggf.org/ns/nmwg/topology/change/update/20070809", the elements in
    the data segment are merged with the existing elements with the same
    identifier in the database. If any element in the data segment does not
    exist in the database, an error will be returned.

    If the eventType is
    "http://ggf.org/ns/nmwg/topology/change/replace/20070809", the elements in
    the data segment are added to the database. If any of the elements already
    exist in the database, they will be replaced with the element in the data
    segment.
=cut
sub handleChangeTopologyRequest {
    my ($self, $output, $eventType, $m, $d) = @_;
    my ($status, $res);
    my $changeType;

    if ($eventType eq "http://ggf.org/ns/nmwg/topology/change/add/20070809") {
        $changeType = "add";
    } elsif ($eventType eq "http://ggf.org/ns/nmwg/topology/change/update/20070809") {
        $changeType = "update";
    } elsif ($eventType eq "http://ggf.org/ns/nmwg/topology/change/replace/20070809") {
        $changeType = "replace";
    }

    my $topology = find($d, "./*[local-name()='topology']", 1);

    if (not defined $topology) {
        my $msg = "No topology defined in change topology request for metadata: ".$m->getAttribute("id");
        $self->{LOGGER}->error("Error changing topology: $msg");
        throw perfSONAR_PS::Error_compat("error.topology.query.topology_not_found", $msg);
    }

    ($status, $res) = topologyNormalize($topology);
    if ($status != 0) {
        $self->{LOGGER}->error("Couldn't normalize topology");
        throw perfSONAR_PS::Error_compat("error.topology.invalid_topology", $res);
    }

    ($status, $res) = $self->{CLIENT}->changeTopology($changeType, $topology);
    if ($status != 0) {
        $self->{LOGGER}->error("Error handling topology request");
        throw perfSONAR_PS::Error_compat("error.topology.ma", $res);
    }

    my $changeDesc;
    my $mdID = "metadata.".genuid();

    if ($changeType eq "add") {
        $changeDesc = "added";
    } elsif ($changeType eq "replace") {
        $changeDesc = "replaced";
    } elsif ($changeType eq "update") {
        $changeDesc = "updated";
    }

    getResultCodeMetadata($output, $mdID, $m->getAttribute("id"), "success.ma.".$changeDesc);
    getResultCodeData($output, "data.".genuid(), $mdID, "data element(s) successfully $changeDesc", 1);

    return;
}

1;

__END__
=head1 SEE ALSO

L<perfSONAR_PS::Services::Base>, L<perfSONAR_PS::Services::MA::General>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Client::LS::Remote>,
L<perfSONAR_PS::Topology::Common>, L<perfSONAR_PS::Client::Topology::XMLDB>

To join the 'perfSONAR-PS' mailing list, please visit:

https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
