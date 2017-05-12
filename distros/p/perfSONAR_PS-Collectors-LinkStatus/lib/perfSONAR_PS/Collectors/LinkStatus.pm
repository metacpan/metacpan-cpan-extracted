package perfSONAR_PS::Collectors::LinkStatus;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Time::HiRes qw( gettimeofday );
use Module::Load;

use perfSONAR_PS::Common;
use perfSONAR_PS::DB::File;
use perfSONAR_PS::Client::Status::MA;
use perfSONAR_PS::Status::Common;
use perfSONAR_PS::Collectors::LinkStatus::Link;
use perfSONAR_PS::Collectors::LinkStatus::Agent::SNMP;
use perfSONAR_PS::Collectors::LinkStatus::Agent::Script;
use perfSONAR_PS::Collectors::LinkStatus::Agent::Constant;

use perfSONAR_PS::SNMPWalk;

use base 'perfSONAR_PS::Collectors::Base';

use fields 'CLIENT', 'LINKS', 'LINKSBYID', 'SNMPAGENTS', 'TL1AGENTS';

our $VERSION = 0.09;

my %link_prev_update_status = ();

sub new {
    my ($self, $conf, $directory) = @_;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new($conf, $directory);
    return $self;
}

sub init {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus");

    $logger->debug("init()");

    if (not defined $self->{CONF}->{"link_file_type"} or $self->{CONF}->{"link_file_type"} eq "") {
        $logger->error("no link file type specified");
        return -1;
    }

    if($self->{CONF}->{"link_file_type"} ne "file") {
        $logger->error("invalid link file type specified: " . $self->{CONF}->{"link_file_type"});
        return -1;
    }

    if ($self->parseLinkFile($self->{CONF}->{"link_file"}, $self->{CONF}->{"link_file_type"}) != 0) {
        $logger->error("couldn't load links to measure");
        return -1;
    }

    if (defined $self->{CONF}->{"ma_type"}) {
        if (lc($self->{CONF}->{"ma_type"}) eq "sqlite") {
            load perfSONAR_PS::Client::Status::SQL;

            if (not defined $self->{CONF}->{"ma_file"} or $self->{CONF}->{"ma_file"} eq "") {
                $logger->error("You specified a SQLite Database, but then did not specify a database file(ma_file)");
                return -1;
            }

            my $file = $self->{CONF}->{"ma_file"};
            if (defined $self->{DIRECTORY}) {
                if (!($file =~ "^/")) {
                    $file = $self->{DIRECTORY}."/".$file;
                }
            }

            $self->{CLIENT} = perfSONAR_PS::Client::Status::SQL->new("DBI:SQLite:dbname=".$file, $self->{CONF}->{"ma_table"});
        } elsif (lc($self->{CONF}->{"ma_type"}) eq "ma") {
            if (not defined $self->{CONF}->{"ma_uri"} or $self->{CONF}->{"ma_uri"} eq "") {
                $logger->error("You specified to use an MA, but did not specify which one(ma_uri)");
                return -1;
            }

            $self->{CLIENT} = perfSONAR_PS::Client::Status::MA->new($self->{CONF}->{"ma_uri"});
        } elsif (lc($self->{CONF}->{"ma_type"}) eq "mysql") {
            load perfSONAR_PS::Client::Status::SQL;

            my $dbi_string = "dbi:mysql";

            if (not defined $self->{CONF}->{"ma_name"} or $self->{CONF}->{"ma_name"} eq "") {
                $logger->error("You specified a MySQL Database, but did not specify the database (ma_name)");
                return -1;
            }

            $dbi_string .= ":".$self->{CONF}->{"ma_name"};

            if (not defined $self->{CONF}->{"ma_host"} or $self->{CONF}->{"ma_host"} eq "") {
                $logger->error("You specified a MySQL Database, but did not specify the database host (ma_host)");
                return -1;
            }

            $dbi_string .= ":".$self->{CONF}->{"ma_host"};

            if (defined $self->{CONF}->{"ma_port"} and $self->{CONF}->{"ma_port"} ne "") {
                $dbi_string .= ":".$self->{CONF}->{"ma_port"};
            }

            $self->{CLIENT} = perfSONAR_PS::Client::Status::SQL->new($dbi_string, $self->{CONF}->{"ma_username"}, $self->{CONF}->{"ma_password"});
            if (not defined $self->{CLIENT}) {
                my $msg = "Couldn't create SQL client";
                $logger->error($msg);
                return (-1, $msg);
            }
        }
    } else {
        $logger->error("Need to specify a location to store the status reports");
        return -1;
    }

    my ($status, $res) = $self->{CLIENT}->open;
    if ($status != 0) {
        my $msg = "Couldn't open newly created client: $res";
        $logger->error($msg);
        return -1;
    }

    $self->{CLIENT}->close;

    return 0;
}

sub parseLinkFile {
    my($self, $file, $type) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus");
    my $links_config;

    if (defined $self->{DIRECTORY}) {
        if (!($file =~ "^/")) {
            $file = $self->{DIRECTORY}."/".$file;
        }
    }

    my $filedb = perfSONAR_PS::DB::File->new( { file => $file } );
    $filedb->openDB;
    $links_config = $filedb->getDOM();

    $self->{LINKSBYID} = ();

    foreach my $link ($links_config->getElementsByTagName("link")) {
        my ($status, $res) = $self->parseLinkElement($link);
        if ($status != 0) {
            my $msg = "Failure parsing link element: $res";
            $logger->error($msg);
            return -1;
        }

        my $parsed_link = $res;

        push @{ $self->{LINKS} }, $parsed_link;

        foreach my $id ($parsed_link->getIDs()) {
            if (defined $self->{LINKSBYID}->{$id}) {
                $logger->error("Tried to redefine link $id");
                return -1;
            }

            $self->{LINKSBYID}->{$id} = $parsed_link;
        }
    }

    return 0;
}

sub parseLinkElement {
    my ($self, $link_desc) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus");

    my $link = perfSONAR_PS::Collectors::LinkStatus::Link->new();

    my $knowledge = $link_desc->getAttribute("knowledge");
    if (not defined $knowledge) {
        my $msg = "It is not stated whether or knowledge is full or partial";
        $logger->error($msg);
        return -1;
    }

    $link->setKnowledge($knowledge);

    foreach my $id_elm ($link_desc->getElementsByTagName("id")) {
        my $id = $id_elm->textContent;

        $link->addID($id);
    }

    if (scalar($link->getIDs()) == 0) {
        my $msg = "No ids associated with specified link";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $primary_time_source;

    foreach my $agent ($link_desc->getElementsByTagName("agent")) {
        my ($status, $res);

        # The following sections for grabbing 'operStatus' and
        # 'adminStatus' subfields in the 'agent' are in there for
        # backwards compatibility reasons and are deprecated.
        my $oper_info = $agent->find('operStatus')->shift;
        if (defined $oper_info) {
            my $oper_agent_ref;

            ($status, $oper_agent_ref) = $self->parseAgentElement($oper_info, "oper");
            if ($status != 0) {
                $logger->error("Problem parsing operational status agent for link");
                return -1;
            }

            my $is_time_source = $oper_info->getAttribute("primary_time_source");
            if (defined $is_time_source and $is_time_source eq "1") {
                if (defined $primary_time_source) {
                    my $msg = "Link has multiple primary time sources";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                $logger->debug("Setting primary time source");

                $primary_time_source = $oper_agent_ref;
            }

            $link->addAgent($oper_agent_ref);
        }

        my $admin_info = $agent->find('adminStatus')->shift;
        if (defined $admin_info) {
            my $admin_agent_ref;

            ($status, $admin_agent_ref) = $self->parseAgentElement($admin_info, "admin");
            if ($status != 0) {
                $logger->error("Problem parsing adminstrative status agent for link");
                return -1;
            }

            my $is_time_source = $admin_info->getAttribute("primary_time_source");
            if (defined $is_time_source and $is_time_source eq "1") {
                if (defined $primary_time_source) {
                    my $msg = "Link has multiple primary time sources";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                $logger->debug("Setting primary time source");

                $primary_time_source = $admin_agent_ref;
            }

            $link->addAgent($admin_agent_ref);
        }

        if (defined $oper_info or defined $admin_info) {
            next;
        }

        ($status, $res) = $self->parseAgentElement($agent, "");
        if ($status != 0) {
            my $msg = "Problem parsing operational status agent for link: $res";
            $logger->error($msg);
            return (-1, $msg);
        }

        my $is_time_source = $agent->getAttribute("primary_time_source");
        if (defined $is_time_source and $is_time_source eq "1") {
            if (defined $primary_time_source) {
                my $msg = "Link has multiple primary time sources";
                $logger->error($msg);
                return (-1, $msg);
            }

            $logger->debug("Setting primary time source");

            $primary_time_source = $res;
        }

        $link->addAgent($res);
    }

    $link->setPrimaryTimeSource($primary_time_source);

    if (scalar($link->getAgents()) == 0) {
        my $msg = "Didn't specify any agents for link";
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, $link);
}

sub parseAgentElement {
    my ($self, $agent, $status_type) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus");

    my $new_agent;

    if ($status_type eq "") {
        $status_type = $agent->getAttribute("status_type");
        if (not defined $status_type) {
            my $msg = "Agent does not contain a status_type attribute stating which status (operational or administrative) it returns";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    if ($status_type ne "oper" and $status_type ne "operational" and $status_type ne "admin" and $status_type ne "administrative") {
        my $msg = "Agent's stated status_type is neither 'oper' nor 'admin'";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $type = $agent->getAttribute("type");
    if (not defined $type or $type eq "") {
        my $msg = "Agent has no type information";
        $logger->debug($msg);
        return (-1, $msg);
    }

    if ($type eq "script") {
        my $script_name = $agent->findvalue("script_name");
        if (not defined $script_name or $script_name eq "") {
            my $msg = "Agent of type 'script' has no script name defined";
            $logger->debug($msg);
            return (-1, $msg);
        }

        if (defined $self->{DIRECTORY}) {
            if (!($script_name =~ "^/")) {
                $script_name = $self->{DIRECTORY}."/".$script_name;
            }
        }

        if (!-x $script_name) {
            my $msg = "Agent of type 'script' has non-executable script: \"$script_name\"";
            $logger->debug($msg);
            return (-1, $msg);
        }

        my $script_params = $agent->findvalue("script_parameters");

        $new_agent = perfSONAR_PS::Collectors::LinkStatus::Agent::Script->new($status_type, $script_name, $script_params);
    } elsif ($type eq "constant") {
        my $value = $agent->findvalue("constant");
        if (not defined $value or $value eq "") {
            my $msg = "Agent of type 'constant' has no value defined";
            $logger->debug($msg);
            return (-1, $msg);
        }

        $new_agent = perfSONAR_PS::Collectors::LinkStatus::Agent::Constant->new($status_type, $value);
    } elsif ($type eq "snmp") {
        my $oid = $agent->findvalue("oid");
        if (not defined $oid or $oid eq "") {
            if ($status_type eq "oper") {
                $oid = "1.3.6.1.2.1.2.2.1.8";
            } elsif ($status_type eq "admin") {
                $oid = "1.3.6.1.2.1.2.2.1.7";
            }
        }

        my $hostname = $agent->findvalue('hostname');
        if (not defined $hostname or $hostname eq "") {
            my $msg = "Agent of type 'SNMP' has no hostname";
            $logger->error($msg);
            return (-1, $msg);
        }

        my $ifName = $agent->findvalue('ifName');
        my $ifIndex = $agent->findvalue('ifIndex');

        if ((not defined $ifIndex or $ifIndex eq "") and (not defined $ifName or $ifName eq "")) {
            my $msg = "Agent of type 'SNMP' has no name or index specified";
            $logger->error($msg);
            return (-1, $msg);
        }

        my $version = $agent->findvalue("version");
        if (not defined $version or $version eq "") {
            my $msg = "Agent of type 'SNMP' has no snmp version";
            $logger->error($msg);
            return (-1, $msg);
        }

        my $community = $agent->findvalue("community");
        if (not defined $community or $community eq "") {
            my $msg = "Agent of type 'SNMP' has no community string";
            $logger->error($msg);
            return (-1, $msg);
        }

        if (not defined $self->{SNMPAGENTS}->{$hostname}) {
            $self->{SNMPAGENTS}->{$hostname} = perfSONAR_PS::Collectors::LinkStatus::Agent::SNMP::Host->new( $hostname, "" , $version, $community, "");
        }

        if (not defined $ifIndex or $ifIndex eq "") {
            $logger->debug("Looking up $ifName from $hostname");

            my ($status, $res) = snmpwalk($hostname, undef, "1.3.6.1.2.1.31.1.1.1.1", $community, $version);
            if ($status != 0) {
                my $msg = "Error occurred while looking up ifIndex for specified ifName $ifName: $res";
                $logger->error($msg);
                return (-1, $msg);
            }

            foreach my $oid_ref ( @{ $res } ) {
                my $oid = $oid_ref->[0];
                my $type = $oid_ref->[1];
                my $value = $oid_ref->[2];

                $logger->debug("$oid = $type: $value($ifName)");
                if ($value eq $ifName) {
                    if ($oid =~ /1\.3\.6\.1\.2\.1\.31\.1\.1\.1\.1\.(\d+)/x) {
                        $ifIndex = $1;
                    }
                }
            }

            if (not defined $ifIndex or $ifIndex eq "") {
                my $msg = "Didn't find ifName $ifName in host $hostname";
                $logger->error($msg);
                return (-1, $msg);
            }
        }

        my $host_agent;

        if (defined $self->{SNMPAGENTS}->{$hostname}) {
            $host_agent = $self->{SNMPAGENTS}->{$hostname};
        }

        $new_agent = perfSONAR_PS::Collectors::LinkStatus::Agent::SNMP->new($status_type, $hostname, $ifIndex, $version, $community, $oid, $host_agent);

        if (not defined $host_agent) {
            $self->{SNMPAGENTS}->{$hostname} = $new_agent->getAgent();
        }
    } elsif ($type eq "tl1") {
        load perfSONAR_PS::Collectors::LinkStatus::Agent::TL1;

        my $type = $agent->findvalue("type");
        my $address = $agent->findvalue('address');
        my $port = $agent->findvalue('port');
        my $physPort = $agent->findvalue('physPort');
        my $username = $agent->findvalue('username');
        my $password = $agent->findvalue('password');
        my $check_sonet = $agent->findvalue('check_sonet');
        my $check_opticals = $agent->findvalue('check_optical');
        my $check_ethernet = $agent->findvalue('check_ethernet');

        if (not $address or not $port or not $type or not $username or not $password) {
            my $msg = "Agent of type 'TL1' is missing elements to access the host. Required: type, address, port, username, password";
            $logger->error($msg);
            return (-1, $msg);
        }

        if (not $physPort) {
            my $msg = "Agent of type 'TL1' is missing element physPort to specify which port to check the status of.";
            $logger->error($msg);
            return (-1, $msg);
        }

        if (not defined $check_sonet) {
            $check_sonet = 1;
        }

        if (not defined $check_sonet) {
            $check_opticals = 1;
        }

        if (not defined $check_sonet) {
            $check_ethernet = 1;
        }

        my $tl1agent;

        my $key = $address."|".$port."|".$username."|".$password;

        if (defined $self->{TL1AGENTS}->{$key}) {
            $tl1agent = $self->{TL1AGENTS}->{$key};
        }

        $new_agent = perfSONAR_PS::Collectors::LinkStatus::Agent::TL1->new(
                        type => $status_type,
                        hostType => $type,
                        address => $address,
                        port => $port,
                        username => $username,
                        password => $password,
                        agent => $tl1agent,
                        check_sonet => $check_sonet,
                        check_ethernet => $check_ethernet,
                        check_optical => $check_opticals,
                        physPort => $physPort,
                     );

        if (not defined $tl1agent) {
            $self->{TL1AGENTS}->{$key} = $new_agent->getAgent;
        }
    } else {
        my $msg = "Unknown agent type: \"$type\"";
        $logger->error($msg);
        return (-1, $msg);
    }

    # here is where we could pull in the possibility of a mapping from the
    # output of the SNMP/script/whatever to "up, down, degraded, unknown"

    return (0, $new_agent);
}

sub collectMeasurements {
    my($self, $sleeptime) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus");
    my ($status, $res);

    $logger->debug("collectMeasurements()");

    ($status, $res) = $self->{CLIENT}->open;
    if ($status != 0) {
        my $msg = "Couldn't open connection to database: $res";
        $logger->error($msg);
        return (-1, $msg);
    }

    foreach my $link (@{$self->{LINKS}}) {
        my ($status, $res);

        $logger->debug("Getting information on link: ".(@{$link->getIDs()}[0]));

        ($status, $res) = $link->measure();
        if ($status != 0) {
            $logger->warn("Couldn't get information on link: ".(@{$link->getIDs()}[0]));
            next;
        }

        my @link_statuses = @{ $res };

        foreach my $link_id (@{ $link->getIDs() }) {
            my $do_update = 0;

            foreach my $link_status (@link_statuses) {
                $logger->debug("Updating $link_id: ".$link_status->getTime()." - ".$link_status->getOperState().", ".$link_status->getAdminState());

                if (defined $link_prev_update_status{$link_id} and $link_prev_update_status{$link_id} == 0) {
                    $do_update = 1;
                }

                ($status, $res) = $self->{CLIENT}->updateLinkStatus($link_status->getTime(),
                                                                    $link_id,
                                                                    $link->getKnowledge(),
                                                                    $link_status->getOperState(),
                                                                    $link_status->getAdminState(),
                                                                    $do_update);
                if ($status != 0) {
                    $logger->error("Couldn't store link status for link $link_id: $res");
                }

                $link_prev_update_status{$link_id} = $status;
            }
        }
    }

    if ($sleeptime) {
        $sleeptime = $self->{CONF}->{"collection_interval"};
    }

    return;
}

1;

__END__

=head1 NAME

perfSONAR_PS::Collectors::LinkStatus - A module that will collect link status
information and store the results into a Link Status MA.

=head1 DESCRIPTION

This module loads a set of links and can be used to collect status information
on those links and store the results into a Link Status MA.

=head1 SYNOPSIS

=head1 DETAILS

This module is meant to be used to periodically collect information about Link
Status. It can do this by running scripts or consulting SNMP servers directly.
It reads a configuration file that contains the set of links to track. It can
then be used to periodically obtain the status and then store the results into
a measurement archive. 

It includes a submodule SNMPAgent that provides a caching SNMP poller allowing
easier interaction with SNMP servers.

=head1 API

=head2 init($self)
    This function initializes the collector. It returns 0 on success and -1
    on failure.

=head2 collectMeasurements($self)
    This function is called by external users to collect and store the
    status for all links.

=head1 SEE ALSO

To join the 'perfSONAR-PS' mailing list, please visit:

https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, E<lt>aaron@internet2.eduE<gt>, Jason Zurawski, E<lt>zurawski@internet2.eduE<gt>

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
