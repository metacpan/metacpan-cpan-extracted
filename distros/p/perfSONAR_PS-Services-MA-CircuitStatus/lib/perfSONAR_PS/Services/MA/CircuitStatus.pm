package perfSONAR_PS::Services::MA::CircuitStatus;

use base 'perfSONAR_PS::Services::Base';

use fields
    'LOCAL_MA_CLIENT',
    'TOPOLOGY_CLIENT',
    'STORE',
    'LS',
    'DOMAIN',
    'CIRCUITS',
    'INCOMPLETE_NODES',
    'TOPOLOGY_LINKS',
    'NODES',
    'LOGGER';

use warnings;
use strict;
use Log::Log4perl qw(get_logger);
use Module::Load;
use Fcntl qw (:flock);
use Fcntl;
use Params::Validate qw(:all);

use perfSONAR_PS::Services::Base;
use perfSONAR_PS::Services::MA::General;
use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Transport;
use perfSONAR_PS::Time;
use perfSONAR_PS::Error_compat qw/:try/;

use perfSONAR_PS::Client::LS::Remote;
use perfSONAR_PS::Client::Status::MA;
use perfSONAR_PS::Client::Topology::MA;

our $VERSION = 0.09;

sub init {
    my ($self, $handler) = @_;

    $self->{LOGGER} = get_logger("perfSONAR_PS::Services::MA::CircuitStatus");

    if (not defined $self->{CONF}->{"circuitstatus"}->{"status_ma_type"} or $self->{CONF}->{"circuitstatus"}->{"status_ma_type"} eq q{}) {
        if (not defined $self->{CONF}->{"circuitstatus"}->{"ls_instance"} or $self->{CONF}->{"circuitstatus"}->{"ls_instance"} eq q{}) {
            $self->{LOGGER}->error("No LS nor Status MA specified");
            return -1;
        } else {
            $self->{CONF}->{"circuitstatus"}->{"status_ma_type"} = "ls";
        }
    }

    if (lc($self->{CONF}->{"circuitstatus"}->{"status_ma_type"}) eq "ls") {
        my ($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($self->{CONF}->{"circuitstatus"}->{"ls_instance"});
        if (not $host or not $port or not $endpoint) {
            $self->{LOGGER}->error("Specified LS is not a URI: ".$self->{CONF}->{"circuitstatus"}->{"ls_instance"});
            return -1;
        }

        $self->{LS} = $self->{CONF}->{"circuitstatus"}->{"ls_instance"};
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"status_ma_type"}) eq "ma") {
        if (not defined $self->{CONF}->{"circuitstatus"}->{"status_ma_uri"} or $self->{CONF}->{"circuitstatus"}->{"status_ma_uri"} eq q{}) {
            $self->{LOGGER}->error("You specified an MA for the status, but did not specify the URI(status_ma_uri)");
            return -1;
        }
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"status_ma_type"}) eq "sqlite") {
        load perfSONAR_PS::Client::Status::SQL;

        if (not defined $self->{CONF}->{"circuitstatus"}->{"status_ma_file"} or $self->{CONF}->{"circuitstatus"}->{"status_ma_file"} eq q{}) {
            $self->{LOGGER}->error("You specified a SQLite Database, but then did not specify a database file(status_ma_file)");
            return -1;
        }

        my $file = $self->{CONF}->{"circuitstatus"}->{"status_ma_file"};
        if (defined $self->{DIRECTORY}) {
            if (!($file =~ "^/")) {
                $file = $self->{DIRECTORY}."/".$file;
            }
        }

        $self->{LOCAL_MA_CLIENT} = perfSONAR_PS::Client::Status::SQL->new("DBI:SQLite:dbname=".$file, $self->{CONF}->{"circuitstatus"}->{"status_ma_table"});
        if (not defined $self->{LOCAL_MA_CLIENT}) {
            my $msg = "No database to dump";
            $self->{LOGGER}->error($msg);
            return -1;
        }
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"status_ma_type"}) eq "mysql") {
        load perfSONAR_PS::Client::Status::SQL;

        my $dbi_string = "dbi:mysql";

        if (not defined $self->{CONF}->{"circuitstatus"}->{"status_ma_name"} or $self->{CONF}->{"circuitstatus"}->{"status_ma_name"} eq q{}) {
            $self->{LOGGER}->error("You specified a MySQL Database, but did not specify the database (status_ma_name)");
            return -1;
        }

        $dbi_string .= ":".$self->{CONF}->{"circuitstatus"}->{"status_ma_name"};

        if (not defined $self->{CONF}->{"circuitstatus"}->{"status_ma_host"} or $self->{CONF}->{"circuitstatus"}->{"status_ma_host"} eq q{}) {
            $self->{LOGGER}->error("You specified a MySQL Database, but did not specify the database host (status_ma_host)");
            return -1;
        }

        $dbi_string .= ":".$self->{CONF}->{"circuitstatus"}->{"status_ma_host"};

        if (defined $self->{CONF}->{"circuitstatus"}->{"status_ma_port"} and $self->{CONF}->{"circuitstatus"}->{"status_ma_port"} ne q{}) {
            $dbi_string .= ":".$self->{CONF}->{"circuitstatus"}->{"status_ma_port"};
        }

        $self->{LOCAL_MA_CLIENT} = perfSONAR_PS::Client::Status::SQL->new($dbi_string, $self->{CONF}->{"circuitstatus"}->{"status_ma_username"}, $self->{CONF}->{"circuitstatus"}->{"status_ma_password"});
        if (not defined $self->{LOCAL_MA_CLIENT}) {
            my $msg = "Couldn't create SQL client";
            $self->{LOGGER}->error($msg);
            return -1;
        }
    } else {
        $self->{LOGGER}->error("Invalid MA type specified");
        return -1;
    }

    if (not defined $self->{CONF}->{"circuitstatus"}->{"circuits_file_type"} or $self->{CONF}->{"circuitstatus"}->{"circuits_file_type"} eq q{}) {
        $self->{LOGGER}->error("No circuits file type specified");
        return -1;
    }

    if($self->{CONF}->{"circuitstatus"}->{"circuits_file_type"} eq "file") {
        if (not defined $self->{CONF}->{"circuitstatus"}->{"circuits_file"} or $self->{CONF}->{"circuitstatus"}->{"circuits_file"} eq q{}) {
            $self->{LOGGER}->error("No circuits file specified");
            return -1;
        }

        try {
            ($self->{DOMAIN}, $self->{CIRCUITS}, $self->{INCOMPLETE_NODES}, $self->{TOPOLOGY_LINKS}, $self->{NODES}) = $self->parseCircuitsFile($self->{CONF}->{"circuitstatus"}->{"circuits_file"});
        } catch perfSONAR_PS::Error_compat with {
            my $ex = shift;
            my $msg = "Error parsing circuits file: $ex";
            $self->{LOGGER}->error($msg);
            return -1;
        };

        if ($self->{"CONF"}->{"circuitstatus"}->{"topology_ma_type"} eq "none" and scalar keys %{ $self->{INCOMPLETE_NODES} } > 0) {
            my $msg = "You specified no topology MA, but there are incomplete nodes";
            $self->{LOGGER}->error($msg);
            return -1;
        }
    } else {
        $self->{LOGGER}->error("Invalid circuits file type specified: ".$self->{CONF}->{"circuitstatus"}->{"link_file_type"});
        return -1;
    }

    if (not defined $self->{CONF}->{"circuitstatus"}->{"topology_ma_type"} or $self->{CONF}->{"circuitstatus"}->{"topology_ma_type"} eq q{}) {
        $self->{LOGGER}->error("No topology MA type specified");
        return -1;
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"topology_ma_type"}) eq "xml") {
        load perfSONAR_PS::Client::Topology::XMLDB;

        if (not defined $self->{CONF}->{"circuitstatus"}->{"topology_ma_file"} or $self->{CONF}->{"circuitstatus"}->{"topology_ma_file"} eq q{}) {
            $self->{LOGGER}->error("You specified a Sleepycat XML DB Database, but then did not specify a database file(topology_ma_file)");
            return -1;
        }

        if (not defined $self->{CONF}->{"circuitstatus"}->{"topology_ma_environment"} or $self->{CONF}->{"circuitstatus"}->{"topology_ma_environment"} eq q{}) {
            $self->{LOGGER}->error("You specified a Sleepycat XML DB Database, but then did not specify a database name(topology_ma_environment)");
            return -1;
        }

        my $environment = $self->{CONF}->{"circuitstatus"}->{"topology_ma_environment"};
        if (defined $self->{DIRECTORY}) {
            if (!($environment =~ "^/")) {
                $environment = $self->{DIRECTORY}."/".$environment;
            }
        }

        my $file = $self->{CONF}->{"circuitstatus"}->{"topology_ma_file"};
        my %ns = &perfSONAR_PS::Topology::Common::getTopologyNamespaces();

        $self->{TOPOLOGY_CLIENT} = perfSONAR_PS::Client::Topology::XMLDB->new($environment, $file, \%ns, 1);
        if (not defined $self->{TOPOLOGY_CLIENT}) {
            $self->{LOGGER}->error("Couldn't initialize topology client");
            return -1;
        }
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"topology_ma_type"}) eq "none") {
        $self->{LOGGER}->warn("Ignoring the topology MA. Everything must be specified explicitly in the circuits.conf file");
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"topology_ma_type"}) eq "ma") {
        if (not defined $self->{CONF}->{"circuitstatus"}->{"topology_ma_uri"} or $self->{CONF}->{"circuitstatus"}->{"topology_ma_uri"} eq q{}) {
            $self->{LOGGER}->error("You specified that you want a Topology MA, but did not specify the URI (topology_ma_uri)");
            return -1;
        }

        $self->{TOPOLOGY_CLIENT} = perfSONAR_PS::Client::Topology::MA->new($self->{CONF}->{"circuitstatus"}->{"topology_ma_uri"});
    } else {
        $self->{LOGGER}->error("Invalid database type specified: ".lc($self->{CONF}->{"circuitstatus"}->{"topology_ma_type"}) );
        return -1;
    }

    if (lc($self->{CONF}->{"circuitstatus"}->{"topology_ma_type"}) ne "none" and 
        defined $self->{INCOMPLETE_NODES} and keys %{ $self->{INCOMPLETE_NODES} } != 0) {
        my ($status, $res);

        ($status, $res) = $self->{TOPOLOGY_CLIENT}->open;
        if ($status != 0) {
            my $msg = "Problem opening topology MA: $res";
            $self->{LOGGER}->error($msg);
            return -1;
        }

        ($status, $res) = $self->{TOPOLOGY_CLIENT}->getAll;
        if ($status != 0) {
            my $msg = "Error getting topology information: $res";
            $self->{LOGGER}->error($msg);
            return -1;
        }

        my $topology = $res;

        ($status, $res) = $self->parseTopology($topology, $self->{INCOMPLETE_NODES}, $self->{DOMAIN});
        if ($status ne q{}) {
            my $msg = "Error parsing topology: $res";
            $self->{LOGGER}->error($msg);
            return -1;
        }
    }

    $self->{STORE} = $self->createMetadataStore($self->{NODES}, $self->{CIRCUITS});

    $self->{LOGGER}->debug("Store: ".$self->{STORE}->toString);

    if (defined $self->{CONF}->{"circuitstatus"}->{"cache_length"} and $self->{CONF}->{"circuitstatus"}->{"cache_length"} > 0) {
        if (not defined $self->{CONF}->{"circuitstatus"}->{"cache_file"} or $self->{CONF}->{"circuitstatus"}->{"cache_file"} eq q{}) {
            my $msg = "If you specify a cache time period, you need to specify a file to cache to \"cache_file\"";
            $self->{LOGGER}->error($msg);
            return -1;
        }

        my $file = $self->{CONF}->{"circuitstatus"}->{"cache_file"};
        if (defined $self->{DIRECTORY}) {
            if (!($file =~ "^/")) {
                $file = $self->{DIRECTORY}."/".$file;
            }
        }

        $self->{CONF}->{"circuitstatus"}->{"cache_file"} = $file;

        $self->{LOGGER}->debug("Using \"$file\" to cache current results");
    }

    $handler->registerEventHandler("SetupDataRequest", "Path.Status", $self);
    $handler->registerEventHandler_Regex("SetupDataRequest", ".*select.*", $self);
    $handler->registerEventHandler("MetadataKeyRequest", "Path.Status", $self);

    return 0;
}

sub needLS {
    return 0;
}

sub handleEvent {
    my ($self, @args) = @_;
      my $parameters = validate(@args, {
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
    my $doOutputMetadata = $parameters->{doOutputMetadata};

    my $md = $subjects[0];

    ${$doOutputMetadata} = 0;

    my ($status, $res1, $res2);

    # This could be wrapped in try/catch
    ($res1, $res2) = $self->resolveSelectChain($md, $raw_request);

    my $selectTime = $res1;
    my $subject_md = $res2;

    $eventType = undef;
    my $eventTypes = find($subject_md, "./nmwg:eventType", 0);
    foreach my $e ($eventTypes->get_nodelist) {
        my $value = extract($e, 1);
        $self->{LOGGER}->debug("Found: \"$value\"");
        if ($value eq "Path.Status") {
            $eventType = $value;
            last;
        }
    }

    if (not defined $eventType) {
        throw perfSONAR_PS::Error_compat("error.ma.event_type", "No supported event types for message of type \"$messageType\"");
    }

    if (defined $selectTime and $selectTime->getType("point") and $selectTime->getTime() eq "now") {
        $selectTime = undef;
    }

    my @circuits;
    if (find($subject_md, "./nmwg:key", 1)) {
        my $circuit_name = findvalue(find($subject_md, "./nmwg:key", 1), "./nmwg:parameters/nmwg:parameter[\@name=\"linkId\"]");

        if (not defined $circuit_name or not defined $self->{CIRCUITS}->{$circuit_name}) {
            my $msg = "The specified key is invalid";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat ("error.ma.invalid_key", "The specified key is invalid");
        }

        push @circuits, $circuit_name;
    } elsif (find($subject_md, "./nmwg:subject", 1)) {
        # this could get wrapped in try/catch
        
        my $circuit_name;
        try {
            $circuit_name  = $self->compatParseSubject(find($subject_md, "./nmwg:subject", 1));
        } catch perfSONAR_PS::Error_compat with {
            my $ex = shift;
            $self->{LOGGER}->error("Error parsing subject: ".$ex->errorMessage());
            $ex->rethrow();
        };

        push @circuits, $circuit_name;
    } else {
        @circuits = keys %{ $self->{CIRCUITS} };
    }

    $self->handlePathStatus($output, \@circuits, $selectTime);

    return (q{}, q{});
}

sub compatParseSubject {
    my ($self, $subject) = @_;
    my $circuit_name;

    if (!find($subject, "./nmtl2:link", 1)) {
        throw perfSONAR_PS::Error_compat("error.ma.invalid_subject", "The specified subject does not contain a link element");
    }

    $circuit_name = findvalue($subject, "./nmtl2:link/nmtl2:name");
    if (defined $circuit_name and defined $self->{CIRCUITS}->{$circuit_name}) {
        return $circuit_name;
    }

    my $nodes = find($subject, "./nmtl2:link/nmwgtopo3:node", 0);
    my $count = 0;
    my ($node1, $node2);
    foreach my $node ($nodes->get_nodelist) {
        my $node_name = findvalue($node, "./nmwgtopo3:name");
        if (not defined $node_name) {
            throw perfSONAR_PS::Error_compat("error.ma.invalid_subject", "The specified subject contains an unfinished node");
        }
    }

    return $circuit_name;
}

sub generateMDXpath {
    my ($subject) = @_;

    return q{};
}

sub createMetadataStore {
    my ($self, $nodes, $circuits) = @_;

    my $doc = perfSONAR_PS::XML::Document_string->new();

    $doc->startElement(prefix => "nmwg", tag => "store", namespace => "http://ggf.org/ns/nmwg/base/2.0/");
    foreach my $node_id (keys %{ $nodes }) {
        my $node = $nodes->{$node_id};

        $self->outputNodeElement($doc, $node);
    }

    foreach my $circuit_id (keys %{ $circuits }) {
        my $circuit = $circuits->{$circuit_id};

        $self->outputCircuitElement($doc, $circuit);
    }
    $doc->endElement("store");

    my $parser = XML::LibXML->new();
    my $xmlDoc;
    eval {
        $xmlDoc = $parser->parse_string($doc->getValue);
    };
    if ($@ or not defined $xmlDoc) {
        my $msg = "Couldn't parse metadata store: $@";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat("error.configuration", $msg);
    }

    return $xmlDoc->documentElement;
}

sub resolveSelectChain {
    my ($self, $md, $request) = @_;

    if (!$request->getNamespaces()->{"http://ggf.org/ns/nmwg/ops/select/2.0/"}) {
        $self->{LOGGER}->debug("No select namespace means there is no select chain");
    }

    if (!find($md, "./select:subject", 1)) {
        $self->{LOGGER}->debug("No select subject means there is no select chain");
    }

    if ($request->getNamespaces()->{"http://ggf.org/ns/nmwg/ops/select/2.0/"} and find($md, "./select:subject", 1)) {
        my $other_md = find($request->getRequestDOM(), "//nmwg:metadata[\@id=\"".find($md, "./select:subject", 1)->getAttribute("metadataIdRef")."\"]", 1);
        if(!$other_md) {
            throw perfSONAR_PS::Error_compat("error.ma.chaining", "Cannot resolve supposed subject chain in metadata.");
        }

        if (!find($md, "./select:subject/select:parameters", 1)) {
            throw perfSONAR_PS::Error_compat ("error.ma.select", "No select parameters specified in given chain.");
        }

        my $time = findvalue($md, "./select:subject/select:parameters/select:parameter[\@name=\"time\"]");
        my $startTime = findvalue($md, "./select:subject/select:parameters/select:parameter[\@name=\"startTime\"]");
        my $endTime = findvalue($md, "./select:subject/select:parameters/select:parameter[\@name=\"endTime\"]");
        my $duration = findvalue($md, "./select:subject/select:parameters/select:parameter[\@name=\"duration\"]");

        if (defined $time and (defined $startTime or defined $endTime or defined $duration)) {
            throw perfSONAR_PS::Error_compat ("error.ma.select", "Ambiguous select parameters");
        }

        if (defined $time) {
            return (perfSONAR_PS::Time->new("point", $time), $other_md);
        }

        if (not defined $startTime) {
            throw perfSONAR_PS::Error_compat ("error.ma.select", "No start time specified");
        } elsif (not defined $endTime and not defined $duration) {
            throw perfSONAR_PS::Error_compat ("error.ma.select", "No end time specified");
        } elsif (defined $endTime) {
            return (perfSONAR_PS::Time->new("range", $startTime, $endTime), $other_md);
        } else {
            return (perfSONAR_PS::Time->new("duration", $startTime, $duration), $other_md);
        }
    } else {
        # No select subject means they didn't specify one which results in "now"
        $self->{LOGGER}->debug("No select chain");

        my $ret_time;
        my $time = findvalue($md, "./nmwg:parameters/nmwg:parameter[\@name=\"time\"]");
        if (defined $time and lc($time) ne "now" and $time ne q{}) {
            $ret_time = perfSONAR_PS::Time->new("point", $time);
        }

        return ($ret_time, $md);
    }
}

sub getLinkStatus {
    my ($self, $link_ids, $time) = @_;

    my %clients = ();

    if (lc($self->{CONF}->{"circuitstatus"}->{"status_ma_type"}) eq "ma") {
        my %client;
        my @children;

        foreach my $link_id (keys %{ $self->{TOPOLOGY_LINKS} }) {
            push @children, $link_id;
        }

        $client{"CLIENT"} = perfSONAR_PS::Client::Status::MA->new($self->{CONF}->{"circuitstatus"}->{"status_ma_uri"});
        $client{"LINKS"} = $link_ids;

        my ($status, $res) = $client{"CLIENT"}->open;
        if ($status != 0) {
            my $msg = "Problem opening status MA ".$self->{CONF}->{"circuitstatus"}->{"status_ma_uri"}.": $res";
            $self->{LOGGER}->warn($msg);
        } else {
            $clients{$self->{CONF}->{"circuitstatus"}->{"status_ma_uri"}} = \%client;
        }
    } elsif (lc($self->{CONF}->{"circuitstatus"}->{"status_ma_type"}) eq "ls") {
        # Consult the LS to find the Status MA for each link

        my %queries = ();

        foreach my $link_id (@{ $link_ids }) {
            my $xquery = q{};
            $xquery .= "        declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
            $xquery .= "        for \$data in /nmwg:store/nmwg:data\n";
            $xquery .= "          let \$metadata_id := \$data/\@metadataIdRef\n";
            $xquery .= "          where \$data//*:link[\@id=\"$link_id\"] and \$data//nmwg:eventType[text()=\"http://ggf.org/ns/nmwg/characteristic/link/status/20070809\"]\n";
            $xquery.= "          return /nmwg:store/nmwg:metadata[\@id=\$metadata_id]\n";

            $queries{$link_id} = $xquery;
        }

        my $ls = perfSONAR_PS::Client::LS::Remote->new($self->{LS});
        my ($status, $res) = $ls->query(\%queries);
        if ($status != 0) {
            my $msg = "Couldn't lookup Link Status MAs from LS: $res";
            $self->{LOGGER}->warn($msg);
        } else {
            foreach my $link_id (@{ $link_ids }) {
                if (not defined $res->{$link_id}) {
                    $self->{LOGGER}->warn("Couldn't find any information on link $link_id");
                    next;
                }

                my ($link_status, $link_res) = @{ $res->{$link_id} };

                if ($link_status != 0) {
                    $self->{LOGGER}->warn("Couldn't find any information on link $link_id");
                    next;
                }

                my $accessPoint;

                $accessPoint = findvalue($link_res, "./psservice:datum/nmwg:metadata/perfsonar:subject/psservice:service/psservice:accessPoint");

                if (not defined $accessPoint or $accessPoint eq q{}) {
                    my $msg = "Received response with no access point for link: $link_id";
                    $self->{LOGGER}->warn($msg);
                    next;
                }

                if (not defined $clients{$accessPoint}) {
                    my %client = ();
                    my @children = ();
                    my $new_client;

                    push @children, $link_id;

                    $client{"CLIENT"} = perfSONAR_PS::Client::Status::MA->new($accessPoint);
                    $client{"LINKS"} = \@children;

                    my ($status, $res) = $client{"CLIENT"}->open;
                    if ($status != 0) {
                        my $msg = "Problem opening status MA $accessPoint: $res";
                        $self->{LOGGER}->warn($msg);
                        next;
                    }

                    $clients{$accessPoint} = \%client;
                } else {
                    push @{ $clients{$accessPoint}->{"LINKS"} }, $link_id;
                }
            }
        }
    } else {
        my %client;

        $client{"CLIENT"} = $self->{LOCAL_MA_CLIENT};
        $client{"LINKS"} = $link_ids;

        my ($status, $res) = $client{"CLIENT"}->open;
        if ($status != 0) {
            my $msg = "Problem opening status MA ".$self->{CONF}->{"circuitstatus"}->{"status_ma_uri"}.": $res";
            $self->{LOGGER}->warn($msg);
        } else {
            $clients{"local"} = \%client;
        }
    }

    my %response = ();

    foreach my $ap_id (keys %clients) {
        my $ma = $clients{$ap_id};

        my ($status, $res) = $ma->{"CLIENT"}->getLinkStatus($ma->{"LINKS"}, $time);
        if ($status != 0) {
            my $msg = "Error getting link status: $res";
            $self->{LOGGER}->warn($msg);
        } else {
            foreach my $link_id (keys %{ $res }) {
                $response{$link_id} = $res->{$link_id};
            }
        }
    }

    return \%response;
}

sub handlePathStatus {
    my ($self, $output, $circuits, $time) = @_;
    my ($status, $res);
    
    if (defined $self->{CONF}->{"circuitstatus"}->{"cache_length"} and $self->{CONF}->{"circuitstatus"}->{"cache_length"} > 0 and not defined $time) {
        my $mtime = (stat $self->{CONF}->{"circuitstatus"}->{"cache_file"})[9];

        if (time - $mtime < $self->{CONF}->{"circuitstatus"}->{"cache_length"}) {
            $self->{LOGGER}->debug("Using cached results in ".$self->{CONF}->{"circuitstatus"}->{"cache_file"});
            if (open(CACHEFILE, $self->{CONF}->{"circuitstatus"}->{"cache_file"})) {
                my $response;
                local $/;
                flock CACHEFILE, LOCK_SH;
                $response = <CACHEFILE>;
                close CACHEFILE;
                $output->addOpaque($response);
                return;
            } else {
                $self->{LOGGER}->warn("Unable to open cached results in ".$self->{CONF}->{"circuitstatus"}->{"cache_file"});
            }
        }
    }

    # get the list of topology link IDs to lookup    
    my %link_ids = ();
    foreach my $circuit_name (@{ $circuits }) {
        my $circuit = $self->{CIRCUITS}->{$circuit_name};

        foreach my $sublink_id (@{ $circuit->{"sublinks"} }) {
            $link_ids{$sublink_id} = q{};
        }
    }

    # Lookup the link status
    my @links = keys %link_ids;

    $res = $self->getLinkStatus(\@links, $time);

    # Fill in any missing links
    foreach my $link_id (@links) {
        if (not defined $res->{$link_id}) {
            my $msg = "Did not receive any information about link $link_id";
            $self->{LOGGER}->warn($msg);

            my $link;
            if (not defined $time) {
            my $curr_time = time;
            $link = perfSONAR_PS::Status::Link->new($link_id, "full", $curr_time, $curr_time, "unknown", "unknown");
            } else {
            $link = perfSONAR_PS::Status::Link->new($link_id, "full", $time->getStartTime(), $time->getEndTime(), "unknown", "unknown");
            }

            $res->{$link_id} = [ $link ];
        }
    }

    my %circuit_status = ();

    foreach my $circuit_name (@{ $circuits }) {
        my $circuit = $self->{CIRCUITS}->{$circuit_name};

        my @data_points = ();

        if (defined $time and $time->getType() ne "point") {
            foreach my $sublink_id (@{ $circuit->{"sublinks"} }) {
                foreach my $link_status (@{ $res->{$sublink_id} }) {
                    push @data_points, $link_status;
                }
            }
        } else {
            my $circuit_admin_value = "unknown";
            my $circuit_oper_value = "unknown";
            my $circuit_time;

            foreach my $sublink_id (@{ $circuit->{"sublinks"} }) {
                foreach my $link_status (@{ $res->{$sublink_id} }) {
                    $self->{LOGGER}->debug("Sublink: $sublink_id");
                    my $oper_value = $link_status->getOperStatus;
                    my $admin_value = $link_status->getAdminStatus;
                    my $end_time = $link_status->getEndTime;

                    $circuit_time = $end_time if (not defined $circuit_time or $end_time > $circuit_time);

                    if ($circuit_oper_value eq "down" or $oper_value eq "down")  {
                        $circuit_oper_value = "down";
                    } elsif ($circuit_oper_value eq "degraded" or $oper_value eq "degraded")  {
                        $circuit_oper_value = "degraded";
                    } elsif ($circuit_oper_value eq "up" or $oper_value eq "up")  {
                        $circuit_oper_value = "up";
                    } else {
                        $circuit_oper_value = "unknown";
                    }

                    if ($circuit_admin_value eq "maintenance" or $admin_value eq "maintenance") {
                        $circuit_admin_value = "maintenance";
                    } elsif ($circuit_admin_value eq "troubleshooting" or $admin_value eq "troubleshooting") {
                        $circuit_admin_value = "troubleshooting";
                    } elsif ($circuit_admin_value eq "underrepair" or $admin_value eq "underrepair") {
                        $circuit_admin_value = "underrepair";
                    } elsif ($circuit_admin_value eq "normaloperation" or $admin_value eq "normaloperation") {
                        $circuit_admin_value = "normaloperation";
                    } else {
                        $circuit_admin_value = "unknown";
                    }
                }
            }

            if (not defined $time and defined $self->{CONF}->{"circuitstatus"}->{"max_recent_age"} and $self->{CONF}->{"circuitstatus"}->{"max_recent_age"} ne q{}) {
                my $curr_time = time;

                if ($curr_time - $circuit_time > $self->{CONF}->{"circuitstatus"}->{"max_recent_age"}) {
                    $self->{LOGGER}->debug("Old link time: $circuit_time Current Time: ".$curr_time.": ".($curr_time - $circuit_time));
                    $circuit_time = $curr_time;
                    $circuit_oper_value = "unknown";
                    $circuit_admin_value = "unknown";
                }
            } else {
                $circuit_time = $time->getTime();
            }

            my $link = perfSONAR_PS::Status::Link->new(q{}, q{}, $circuit_time, $circuit_time, $circuit_oper_value, $circuit_admin_value);
            push @data_points, $link;
        }

        $circuit_status{$circuit_name} = \@data_points;
    }

    my $doc = perfSONAR_PS::XML::Document_string->new();

    startParameters($doc, "params.0");
     addParameter($doc, "DomainName", $self->{DOMAIN});
    endParameters($doc);
    $self->outputResults($doc, \%circuit_status, $time);

    if (not defined $time and defined $self->{CONF}->{"circuitstatus"}->{"cache_length"} and $self->{CONF}->{"circuitstatus"}->{"cache_length"} > 0) {
        $self->{LOGGER}->debug("Caching results in ".$self->{CONF}->{"circuitstatus"}->{"cache_file"});

        unlink($self->{CONF}->{"circuitstatus"}->{"cache_file"});

        if (sysopen(CACHEFILE, $self->{CONF}->{"circuitstatus"}->{"cache_file"}, O_WRONLY | O_CREAT, 0600)) {
            flock CACHEFILE, LOCK_EX;
            print CACHEFILE $doc->getValue();
            close CACHEFILE;
        } else {
            $self->{LOGGER}->warn("Unable to cache results");
        }
    }

    $output->addOpaque($doc->getValue());

    return;
}

sub outputResults {
    my ($self, $output, $results, $time) = @_;

    my %output_endpoints = ();
    my $i = 0;

    foreach my $circuit_name (keys %{ $results }) {
        my $circuit = $self->{CIRCUITS}->{$circuit_name};
        foreach my $endpoint (@{ $circuit->{"endpoints"} }) {
            next if (not defined $self->{NODES}->{$endpoint->{name}});
            next if (defined $output_endpoints{$endpoint->{name}});

            startMetadata($output, "metadata.".genuid(), q{}, undef);
             $output->startElement(prefix => "nmwg", tag => "subject", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => { id => "sub-".$endpoint->{name} });
              $self->outputNodeElement($output, $self->{NODES}->{$endpoint->{name}});
             $output->endElement("subject");
            endMetadata($output);

            $output_endpoints{$endpoint->{name}} = 1;
        }

        my $mdid = "metadata.".genuid();

        startMetadata($output, $mdid, q{}, undef);
         $output->startElement(prefix => "nmwg", tag => "subject", namespace => "http://ggf.org/ns/nmwg/base/2.0/", attributes => { id => "sub$i" });
          $self->outputCircuitElement($output, $circuit);
         $output->endElement("subject");
        endMetadata($output);

        my @data = @{ $results->{$circuit_name} };
        startData($output, "data.$i", $mdid, undef);
        foreach my $datum (@data) {
            my %attrs = ();

            $attrs{"timeType"} = "unix";
            $attrs{"timeValue"} = $datum->getEndTime();
            if (defined $time and $time ne "point") {
                $attrs{"startTime"} = $datum->getStartTime();
                $attrs{"endTime"} = $datum->getEndTime();
            }

            $output->startElement(prefix => "ifevt", tag => "datum", namespace => "http://ggf.org/ns/nmwg/event/status/base/2.0/", attributes => \%attrs);
            $output->createElement(prefix => "ifevt", tag => "stateAdmin", namespace => "http://ggf.org/ns/nmwg/event/status/base/2.0/", content => $datum->getAdminStatus);
            $output->createElement(prefix => "ifevt", tag => "stateOper", namespace => "http://ggf.org/ns/nmwg/event/status/base/2.0/", content => $datum->getOperStatus);
            $output->endElement("datum");
        }
        endData($output);

        $i++;
    }

    return;
}

sub outputNodeElement {
    my ($self, $output, $node) = @_;

    $output->startElement(prefix => "nmwgtopo3", tag => "node", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", attributes => { id => $self->{DOMAIN}."-".$node->{"name"} });
      $output->createElement(prefix => "nmwgtopo3", tag => "type", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", attributes => { type => "logical" }, content => "TopologyPoint");
      $output->createElement(prefix => "nmwgtopo3", tag => "name", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", attributes => { type => "logical" }, content => $node->{"name"});
    if (defined $node->{"city"} and $node->{"city"} ne q{}) {
        $output->createElement(prefix => "nmwgtopo3", tag => "city", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", content => $node->{"city"});
    }
    if (defined $node->{"country"} and $node->{"country"} ne q{}) {
        $output->createElement(prefix => "nmwgtopo3", tag => "country", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", content => $node->{"country"});
    }
    if (defined $node->{"latitude"} and $node->{"latitude"} ne q{}) {
        $output->createElement(prefix => "nmwgtopo3", tag => "latitude", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", content => $node->{"latitude"});
    }
    if (defined $node->{"longitude"} and $node->{"longitude"} ne q{}) {
        $output->createElement(prefix => "nmwgtopo3", tag => "longitude", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", content => $node->{"longitude"});
    }
    if (defined $node->{"institution"} and $node->{"institution"} ne q{}) {
        $output->createElement(prefix => "nmwgtopo3", tag => "institution", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", , content => $node->{"institution"});
    }
    $output->endElement("node");

    return;
}

sub outputCircuitElement {
    my ($self, $output, $circuit) = @_;

    $output->startElement(prefix => "nmtl2", tag => "link", namespace => "http://ggf.org/ns/nmwg/topology/l2/3.0/");
      $output->createElement(prefix => "nmtl2", tag => "name", namespace => "http://ggf.org/ns/nmwg/topology/l2/3.0/", attributes => { type => "logical" }, content => $circuit->{"name"});
      $output->createElement(prefix => "nmtl2", tag => "globalName", namespace => "http://ggf.org/ns/nmwg/topology/l2/3.0/", attributes => { type => "logical" }, content => $circuit->{"globalName"});
      $output->createElement(prefix => "nmtl2", tag => "type", namespace => "http://ggf.org/ns/nmwg/topology/l2/3.0/", content => $circuit->{"type"});
      foreach my $endpoint (@{ $circuit->{"endpoints"} }) {
      $output->startElement(prefix => "nmwgtopo3", tag => "node", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", attributes => { nodeIdRef => $self->{DOMAIN}."-".$endpoint->{"name"} });
      $output->createElement(prefix => "nmwgtopo3", tag => "role", namespace => "http://ggf.org/ns/nmwg/topology/base/3.0/", content => $endpoint->{"type"});
      $output->endElement("node");
      }
#      startParameters($output, "params.0");
#        addParameter($output, "supportedEventType", "Path.Status");
#      endParameters($output);
    $output->endElement("link");

    return;
}

sub parseCircuitsFile {
    my ($self, $file) = @_;

    my %nodes = ();
    my %incomplete_nodes = ();
    my %topology_links = ();
    my %circuits = ();

    my $parser = XML::LibXML->new();
    my $doc;
    eval {
        $doc = $parser->parse_file($file);
    };
    if ($@ or not defined $doc) {
        my $msg = "Couldn't parse circuits file $file: $@";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
    }

    my $conf = $doc->documentElement;

    my $domain = findvalue($conf, "domain");
    if (not defined $domain) {
        my $msg = "No domain specified in configuration";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
    }

    my $find_res;

    $find_res = find($conf, "./*[local-name()='node']", 0);
    if ($find_res) {
    foreach my $endpoint ($find_res->get_nodelist) {
        my $node_id = $endpoint->getAttribute("id");
        my $node_type = $endpoint->getAttribute("type");
        my $node_name = $endpoint->getAttribute("name");
        my $city = findvalue($endpoint, "city");
        my $country = findvalue($endpoint, "country");
        my $longitude = findvalue($endpoint, "longitude");
        my $institution = findvalue($endpoint, "institution");
        my $latitude = findvalue($endpoint, "latitude");

        if (not defined $node_name or $node_name eq q{}) {
            my $msg = "Node needs to have a name";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
        }

        $node_name =~ s/[^a-zA-Z0-9_]//g;
        $node_name = uc($node_name);

        if (defined $nodes{$node_name}) {
            my $msg = "Multiple endpoints have the name \"$node_name\"";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
        }

        my %tmp = ();
        my $new_node = \%tmp;

        $new_node->{"id"} = $node_id if (defined $node_id and $node_id ne q{});
        $new_node->{"name"} = $node_name if (defined $node_name and $node_name ne q{});
        $new_node->{"city"} = $city if (defined $city and $city ne q{});
        $new_node->{"country"} = $country if (defined $country and $country ne q{});
        $new_node->{"longitude"} = $longitude if (defined $longitude and $longitude ne q{});
        $new_node->{"latitude"} = $latitude if (defined $latitude and $latitude ne q{});
        $new_node->{"institution"} = $institution if (defined $institution and $institution ne q{});

        if (defined $node_id and
            (not defined $city or not defined $country or not defined $longitude or not defined $latitude or not defined $institution)) {
            $incomplete_nodes{$node_id} = $new_node;
        }

        $nodes{$node_name} = $new_node;
    }
    }

    $find_res = find($conf, "./*[local-name()='circuit']", 0);
    if ($find_res) {
    foreach my $circuit ($find_res->get_nodelist) {
        my $global_name = findvalue($circuit, "globalName");
        my $local_name = findvalue($circuit, "localName");
        my $knowledge = $circuit->getAttribute("knowledge");
        my $circuit_type;

        if (not defined $global_name or $global_name eq q{}) {
            my $msg = "Circuit has no global name";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
        }

        if (not defined $knowledge or $knowledge eq q{}) {
            $self->{LOGGER}->warn("Don't know the knowledge level of circuit \"$global_name\". Assuming full");
            $knowledge = "full";
        } else {
            $knowledge = lc($knowledge);
        }

        if (not defined $local_name or $local_name eq q{}) {
            $local_name = $global_name;
        }

        my %sublinks = ();

        $find_res = find($circuit, "./*[local-name()='linkID']", 0);
        if ($find_res) {
        foreach my $topo_id ($find_res->get_nodelist) {
            my $id = $topo_id->textContent;

            if (defined $sublinks{$id}) {
                my $msg = "Link $id appears multiple times in circuit $global_name";
                $self->{LOGGER}->error($msg);
                throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
            }

            $sublinks{$id} = q{};
            $topology_links{$id} = q{};
        }
        }

        my @endpoints = ();

        my $num_endpoints = 0;

        my $prev_domain;

        $find_res = find($circuit, "./*[local-name()='endpoint']", 0);
        if ($find_res) {
        foreach my $endpoint ($find_res->get_nodelist) {
            my $node_type = $endpoint->getAttribute("type");
            my $node_name = $endpoint->getAttribute("name");

            if (not defined $node_type or $node_type eq q{}) {
                my $msg = "Node with unspecified type found";
                $self->{LOGGER}->error($msg);
                throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
            }

            if (not defined $node_name or $node_name eq q{}) {
                my $msg = "Endpint needs to specify a node name";
                $self->{LOGGER}->error($msg);
                throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
            }

            $node_name =~ s/[^a-zA-Z0-9_]//g;
            $node_name = uc($node_name);

            if (lc($node_type) ne "demarcpoint" and lc($node_type) ne "endpoint") {
                my $msg = "Node found with invalid type $node_type. Must be \"DemarcPoint\" or \"EndPoint\"";
                $self->{LOGGER}->error($msg);
                throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
            }

            my ($domain, @junk) = split(/-/, $node_name);
            if (not defined $prev_domain) {
                $prev_domain = $domain;
            } elsif ($domain eq $prev_domain) {
                    $circuit_type = "DOMAIN_Link";
            } else {
                if ($knowledge eq "full") {
                    $circuit_type = "ID_Link";
                } else {
                    $circuit_type = "ID_LinkPartialInfo";
                }
            }

            my %new_endpoint = ();

            $new_endpoint{"type"} = $node_type;
            $new_endpoint{"name"} = $node_name;

            push @endpoints, \%new_endpoint;

            $num_endpoints++;
        }
        }

        if ($num_endpoints != 2) {
            my $msg = "Invalid number of endpoints, $num_endpoints, must be 2";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
        }

        my @sublinks = keys %sublinks;

        my %new_circuit = ();

        $new_circuit{"globalName"} = $global_name;
        $new_circuit{"name"} = $local_name;
        $new_circuit{"sublinks"} = \@sublinks;
        $new_circuit{"endpoints"} = \@endpoints;
        $new_circuit{"type"} = $circuit_type;

        if (defined $circuits{$local_name}) {
            my $msg = "Error: existing circuit of name $local_name";
            $self->{LOGGER}->error($msg);
            throw perfSONAR_PS::Error_compat ("error.configuration", $msg);
        } else {
            $circuits{$local_name} = \%new_circuit;
        }
    }
    }

    return ($domain, \%circuits, \%incomplete_nodes, \%topology_links, \%nodes);
}

sub parseTopology {
    my ($self, $topology, $incomplete_nodes, $domain_name) = @_;
    my %ids = ();

    foreach my $node ($topology->getElementsByLocalName("node")) {
        my $id = $node->getAttribute("id");
        $self->{LOGGER}->debug("node: ".$id);

        next if not defined $incomplete_nodes->{$id};

        $self->{LOGGER}->debug("found node ".$id." in here");

        my $longitude = findvalue($node, "./*[local-name()='longitude']");
        $self->{LOGGER}->debug("searched for longitude");
        my $institution = findvalue($node, "./*[local-name()='institution']");
        $self->{LOGGER}->debug("searched for institution");
        my $latitude = findvalue($node, "./*[local-name()='latitude']");
        $self->{LOGGER}->debug("searched for latitude");
        my $city = findvalue($node, "./*[local-name()='city']");
        $self->{LOGGER}->debug("searched for city");
        my $country = findvalue($node, "./*[local-name()='country']");
        $self->{LOGGER}->debug("searched for country");

        $incomplete_nodes->{$id}->{"type"} = "TopologyPoint";

        if (not defined $incomplete_nodes->{$id}->{"longitude"} and defined $longitude and $longitude ne q{}) {
            # conversions may need to be made
            $incomplete_nodes->{$id}->{"longitude"} = $longitude;
        }

        if (not defined $incomplete_nodes->{$id}->{"latitude"} and defined $latitude and $latitude ne q{}) {
            # conversions may need to be made
            $incomplete_nodes->{$id}->{"latitude"} = $latitude;
        }

        if (not defined $incomplete_nodes->{$id}->{"institution"}) {
            if ( defined $institution and $institution ne q{}) {
                # conversions may need to be made
                $incomplete_nodes->{$id}->{"institution"} = $institution;
            } else {
                $incomplete_nodes->{$id}->{"institution"} = $domain_name;
            }
        }

        if (not defined $incomplete_nodes->{$id}->{"city"} and defined $city and $city ne q{}) {
            $incomplete_nodes->{$id}->{"city"} = $city;
        }

        if (not defined $incomplete_nodes->{$id}->{"country"} and defined $country and $country ne q{}) {
            $incomplete_nodes->{$id}->{"country"} = $country;
        }
    }

    return ("", undef);
}

1;

__END__
=head1 NAME

perfSONAR_PS::Services::MA::CircuitStatus - A module that provides methods for an E2EMon Compatible MP.

=head1 DESCRIPTION

This module aims to offer simple methods for dealing with requests for information, and the
related tasks of interacting with backend storage.

=head1 SYNOPSIS

use perfSONAR_PS::Services::MA::CircuitStatus;

my %conf = readConfiguration();

my %ns = (
        nmwg => "http://ggf.org/ns/nmwg/base/2.0/",
        ifevt => "http://ggf.org/ns/nmwg/event/status/base/2.0/",
        nmtm => "http://ggf.org/ns/nmwg/time/2.0/",
        nmwgtopo3 => "http://ggf.org/ns/nmwg/topology/base/3.0/",
        nmtl2 => "http://ggf.org/ns/nmwg/topology/l2/3.0/",
        nmtl3 => "http://ggf.org/ns/nmwg/topology/l3/3.0/",
     );

my $ma = perfSONAR_PS::Services::MA::CircuitStatus->new(\%conf, \%ns);

# or
# $ma = perfSONAR_PS::Services::MA::CircuitStatus->new;
# $ma->setConf(\%conf);
# $ma->setNamespaces(\%ns);

if ($ma->init != 0) {
    print "Error: couldn't initialize measurement archive\n";
    exit(-1);
}

while(1) {
    my $request = $ma->receive;
    $ma->handleRequest($request);
}

=head1 API

The offered API is simple, but offers the key functions we need in a measurement archive.

=head2 init 

       Initializes the MP and validates or fills in entries in the
    configuration file. Returns 0 on success and -1 on failure.

=head2 receive($self)

    Grabs an incoming message from transport object to begin processing. It
    completes the processing if the message was handled by a lower layer.
    If not, it returns the Request structure.

=head2 handleRequest($self, $request)

    Handles the specified request returned from receive()

=head2 __handleRequest($self)

    Validates that the message is one that we can handle, calls the
    appropriate function for the message type and builds the response
    message. 

=head2 parseRequest($self, $request)

    Goes through each metadata/data pair, extracting the eventType and
    calling the function associated with that eventType.

=head2 handlePathStatusRequest($self, $time) 

    Performs the required steps to handle a path status message: contacts
    the topology service to resolve node information, contacts the LS if
    needed to find the link status service, contacts the link status
    service and munges the results.

=head2 outputNodes($nodes) 

    Takes the set of nodes and outputs them in an E2EMon compatiable
    format.

=head2 outputCircuits($circuits) 

    Takes the set of links and outputs them in an E2EMon compatiable
    format.

=head2 parseCircuitsFile($file) 

    Parses the links configuration file. It returns an array containg up to
    five values. The first value is the status and can be one of 0 or -1.
    If it is -1, parsing the configuration file failed and the error
    message is in the next value. If the status is 0, the next 4 values are
    the domain name, a pointer to the set of links, a pointer to a hash
    containg the set of nodes to lookup in the topology service and a
    pointer to a hash containing the set of links to lookup in the status
    service.
    
=head2 parseTopology($topology, $nodes, $domain_name)

    Parses the output from the topology service and fills in the details
    for the nodes. The domain name is passed so that when a node has no
    name specified in the configuration file, it can be constructd based on
    the domain name and the node's name in the topology service.

=head1 SEE ALSO

L<perfSONAR_PS::Services::Base>, L<perfSONAR_PS::Services::MA::General>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Transport>,
L<perfSONAR_PS::Client::Status::MA>, L<perfSONAR_PS::Client::Topology::MA>


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
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
