package perfSONAR_PS::Collectors::LinkStatus::Agent::SNMP;

=head1 NAME

perfSONAR_PS::Collectors::LinkStatus::Agent::SNMP - This module provides an
agent for the Link Status Collector that gets status information for a link by
asking an SNMP server.

=head1 DESCRIPTION

This agent will query the SNMP service and return the estimated time on the
SNMP server, along with the status of the given interface. The actual structure
of the agent is split into two pieces (stored in one file for clarity). There's
an element whose sole purpose is to grab all the SNMP stats from a given host
and cache them. This is described at the bottom of the file. Then, there is a
higher-level agent, whose sole purpose is to get a single data point for a
single ifIndex. The caching object is meant to be shared among all the agents
so that it does not clutter the SNMP server with numerous calls each time
status information is grabbed. While users can get the caching element for a
given agent, they should not interact with it directly.

=head1 API
=cut

use strict;
use warnings;

use fields 'TYPE', 'HOSTNAME', 'IFINDEX', 'COMMUNITY', 'VERSION', 'OID', 'AGENT';


our $VERSION = 0.09;

=head2 new ($package, $status_type, $hostname, $ifIndex, $version, $community, $oid, $agent)
    This function instantiates a new SNMP Agent for grabbing the ifIndex/oid
    off the specified host. The $agent element is an optional one that can be
    used to pass in an existing caching object. If unspecified, a new caching
    object will be created.
=cut
sub new {
    my ($class, $type, $hostname, $ifIndex, $version, $community, $oid, $agent) = @_;

    my $self = fields::new($class);

    if ($agent ne "") {
        $self->{"AGENT"} = $agent;
    } else {
        $self->{"AGENT"} = new perfSONAR_PS::Collectors::LinkStatus::SNMPAgent( $hostname, "" , $version, $community, "");
    }

    $self->{"TYPE"} = $type;
    $self->{"HOSTNAME"} = $hostname;
    $self->{"IFINDEX"} = $ifIndex;
    $self->{"COMMUNITY"} = $community;
    $self->{"VERSION"} = $version;
    $self->{"OID"} = $oid;

    return $self;
}

=head2 getType
    Returns the status type of this agent: admin or oper.
=cut
sub getType {
    my ($self) = @_;

    return $self->{TYPE};
}

=head2 setType ($self, $type)
    Sets the status type of this agent: admin or oper.
=cut
sub setType {
    my ($self, $type) = @_;

    $self->{TYPE} = $type;

    return;
}

=head2 setHostname ($self, $hostname)
    Sets the hostname for this agent to poll.
=cut
sub setHostname {
    my ($self, $hostname) = @_;

    $self->{HOSTNAME} = $hostname;

    return;
}

=head2 getHostname ($self)
    Returns the hostname that this agent is polling.
=cut
sub getHostname {
    my ($self) = @_;

    return $self->{HOSTNAME};
}

=head2 setifIndex ($self, $ifIndex)
    Sets the ifIndex that this agent returns the status of.
=cut
sub setifIndex {
    my ($self, $ifIndex) = @_;

    $self->{IFINDEX} = $ifIndex;

    return;
}

=head2 getifIndex ($self)
    Returns the ifIndex that this agent returns the status of.
=cut
sub getifIndex {
    my ($self) = @_;

    return $self->{IFINDEX};
}

=head2 setCommunity ($self, $community)
    Sets the community string that will be used by this agent.
=cut
sub setCommunity {
    my ($self, $community) = @_;

    $self->{COMMUNITY} = $community;

    return;
}

=head2 getCommunity ($self)
    Returns the community string that will be used by this agent.
=cut
sub getCommunity {
    my ($self) = @_;

    return $self->{COMMUNITY};
}

=head2 setVersion ($self, $version)
    Sets the snmp version string for this agent.
=cut
sub setVersion {
    my ($self, $version) = @_;

    $self->{VERSION} = $version;

    return;
}

=head2 getVersion ($self)
    Returns the snmp version string for this agent.
=cut
sub getVersion {
    my ($self) = @_;

    return $self->{VERSION};
}

=head2 setOID ($self, $oid)
    Sets the OID for this agent.
=cut
sub setOID {
    my ($self, $oid) = @_;

    $self->{OID} = $oid;

    return;
}

=head2 getOID ($self)
    Returns the OID for this agent.
=cut
sub getOID {
    my ($self) = @_;

    return $self->{OID};
}

=head2 setAgent ($self, $agent)
    Sets the caching snmp object used by this agent
=cut
sub setAgent {
    my ($self, $agent) = @_;

    $self->{AGENT} = $agent;

    return;
}

=head2 getAgent ($self)
    Returns the caching snmp object used by this agent
=cut
sub getAgent {
    my ($self) = @_;

    return $self->{AGENT};
}

=head2 run ($self)
    Queries the local caching object for the OID/ifIndex of interest and grabs
    the most recent time for the SNMP server. It then converts the result of
    the OID/ifIndex into a known status type and returns the time/status.
=cut
sub run {
    my ($self) = @_;

    $self->{AGENT}->setSession;
    my $measurement_value = $self->{AGENT}->getVar($self->{OID}.".".$self->{IFINDEX});
    my $measurement_time = $self->{AGENT}->getHostTime;
    $self->{AGENT}->closeSession;

    if (defined $measurement_value) {
        if ($self->{OID} eq "1.3.6.1.2.1.2.2.1.8") {
            if ($measurement_value eq "2") {
                $measurement_value = "down";
            } elsif ($measurement_value eq "1") {
                $measurement_value = "up";
            } else {
                $measurement_value = "unknown";
            }
        } elsif ($self->{OID} eq "1.3.6.1.2.1.2.2.1.7") {
            if ($measurement_value eq "2") {
                $measurement_value = "down";
            } elsif ($measurement_value eq "1") {
                $measurement_value = "normaloperation";
            } elsif ($measurement_value eq "3") {
                $measurement_value = "troubleshooting";
            } else {
                $measurement_value = "unknown";
            }
        }
    } else {
        return (-1, "No value for measurement");
    }

    return (0, $measurement_time, $measurement_value);
}

1;

# ================ Internal Package perfSONAR_PS::Collectors::LinkStatus::SNMPAgent ================

package perfSONAR_PS::Collectors::LinkStatus::Agent::SNMP::Host;

use Net::SNMP;
use Log::Log4perl qw(get_logger);

use perfSONAR_PS::Common;

use fields 'HOST', 'PORT','VERSION', 'COMMUNITY', 'VARIABLES', 'CACHED_TIME', 'CACHE_LENGTH', 'HOSTTICKS', 'SESSION', 'ERROR', 'REFTIME', 'CACHED';

sub new {
    my ($class, $host, $port, $ver, $comm, $vars, $cache_length) = @_;

    my $self = fields::new($class);

    if(defined $host and $host ne "") {
        $self->{"HOST"} = $host;
    }
    if(defined $port and $port ne "") {
        $self->{"PORT"} = $port;
    } else {
        $self->{"PORT"} = 161;
    }
    if(defined $ver and $ver ne "") {
        $self->{"VERSION"} = $ver;
    }
    if(defined $comm and $comm ne "") {
        $self->{"COMMUNITY"} = $comm;
    }
    if(defined $vars and $vars ne "") {
        $self->{"VARIABLES"} = \%{$vars};
    } else {
        $self->{"VARIABLES"} = ();
    }
    if (defined $cache_length and $cache_length ne "") {
        $self->{"CACHE_LENGTH"} = $cache_length;
    } else {
        $self->{"CACHE_LENGTH"} = 1;
    }

    $self->{"VARIABLES"}->{"1.3.6.1.2.1.1.3.0"} = ""; # add the host ticks so we can track it
        $self->{"HOSTTICKS"} = 0;

    return $self;
}

sub setHost {
    my ($self, $host) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $host and $host ne "") {
        $self->{HOST} = $host;
        $self->{HOSTTICKS} = 0;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}


sub setPort {
    my ($self, $port) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $port and $port ne "") {
        $self->{PORT} = $port;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}


sub setVersion {
    my ($self, $ver) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $ver and $ver ne "") {
        $self->{VERSION} = $ver;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}


sub setCommunity {
    my ($self, $comm) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $comm and $comm ne "") {
        $self->{COMMUNITY} = $comm;
    } else {
        $logger->error("Missing argument.");
    }
    return;
}


sub setVariables {
    my ($self, $vars) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $vars and $vars ne "") {
        $self->{"VARIABLES"} = \%{$vars};
    } else {
        $logger->error("Missing argument.");
    }
    return;
}

sub setCacheLength {
    my ($self, $cache_length) = @_;

    if (defined $cache_length and $cache_length ne "") {
        $self->{"CACHE_LENGTH"} = $cache_length;
    }
    return;
}

sub addVariable {
    my ($self, $var) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(not defined $var or $var eq "") {
        $logger->error("Missing argument.");
    } else {
        $self->{VARIABLES}->{$var} = "";
    }
    return;
}

sub getVar {
    my ($self, $var) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(not defined $var or $var eq "") {
        $logger->error("Missing argument.");
        return;
    } 

    if (not defined $self->{VARIABLES}->{$var} or not defined $self->{CACHED_TIME} or time() - $self->{CACHED_TIME} > $self->{CACHE_LENGTH}) {
        $self->{VARIABLES}->{$var} = "";

        my ($status, $res) = $self->collectVariables();
        if ($status != 0) {
            return;
        }

        my %results = %{ $res };

        $self->{CACHED} = \%results;
        $self->{CACHED_TIME} = time();
    }

    return $self->{CACHED}->{$var};
}

sub getHostTime {
    my ($self) = @_;
    return $self->{REFTIME};
}

sub refreshVariables {
    my ($self) = @_;
    my ($status, $res) = $self->collectVariables();

    if ($status != 0) {
        return;
    }

    my %results = %{ $res };

    $self->{CACHED} = \%results;
    $self->{CACHED_TIME} = time();

    return;
}

sub getVariableCount {
    my ($self) = @_;

    my $num = 0;
    foreach my $oid (keys %{$self->{VARIABLES}}) {
        $num++;
    }
    return $num;
}

sub removeVariables {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    undef $self->{VARIABLES};
    if(defined $self->{VARIABLES}) {
        $logger->error("Remove failure.");
    }
    return;
}

sub removeVariable {
    my ($self, $var) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $var and $var ne "") {
        delete $self->{VARIABLES}->{$var};
    } else {
        $logger->error("Missing argument.");
    }
    return;
}

sub setSession {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if((defined $self->{COMMUNITY} and $self->{COMMUNITY} ne "") and
            (defined $self->{VERSION} and $self->{VERSION} ne "") and
            (defined $self->{HOST} and $self->{HOST} ne "") and
            (defined $self->{PORT} and $self->{PORT} ne "")) {

        ($self->{SESSION}, $self->{ERROR}) = Net::SNMP->session(
                -community     => $self->{COMMUNITY},
                -version       => $self->{VERSION},
                -hostname      => $self->{HOST},
                -port          => $self->{PORT},
                -translate     => [
                -timeticks => 0x0
                ]) or $logger->error("Couldn't open SNMP session to \"".$self->{HOST}."\".");

        if(not defined($self->{SESSION})) {
            $logger->error("SNMP error: ".$self->{ERROR});
        }
    }
    else {
        $logger->error("Session requires arguments 'host', 'version', and 'community'.");
    }
    return;
}

sub closeSession {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $self->{SESSION}) {
        $self->{SESSION}->close;
    } else {
        $logger->error("Cannont close undefined session.");
    }
    return;
}

sub collectVariables {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $self->{SESSION}) {
        my @oids = ();

        foreach my $oid (keys %{$self->{VARIABLES}}) {
            push @oids, $oid;
        }

        my $res = $self->{SESSION}->get_request(-varbindlist => \@oids) or $logger->error("SNMP error.");

        if(not defined($res)) {
            my $msg = "SNMP error: ".$self->{SESSION}->error;
            $logger->error($msg);
            return (-1, $msg);
        } else {
            my %results;

            %results = %{ $res };

            if (not defined $results{"1.3.6.1.2.1.1.3.0"}) {
                $logger->warn("No time values, getTime may be screwy");
            } else {
                my $new_ticks = $results{"1.3.6.1.2.1.1.3.0"} / 100;

                if ($self->{HOSTTICKS} == 0) {
                    my($sec, $frac) = Time::HiRes::gettimeofday;
                    $self->{REFTIME} = $sec.".".$frac;
                } else {
                    $self->{REFTIME} += $new_ticks - $self->{HOSTTICKS};
                }

                $self->{HOSTTICKS} = $new_ticks;
            }

            return (0, $res);
        }
    } else {
        my $msg = "Session to \"".$self->{HOST}."\" not found.";
        $logger->error($msg);
        return (-1, $msg);
    }
}

sub collect {
    my ($self, $var) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::SNMPAgent");

    if(defined $var and $var ne "") {
        if(defined $self->{SESSION}) {
            my $results = $self->{SESSION}->get_request(-varbindlist => [$var]) or $logger->error("SNMP error: \"".$self->{ERROR}."\".");
            if(not defined($results)) {
                $logger->error("SNMP error: \"".$self->{ERROR}."\".");
                return -1;
            } else {
                return $results->{"$var"};
            }
        } else {
            $logger->error("Session to \"".$self->{HOST}."\" not found.");
            return -1;
        }
    } else {
        $logger->error("Missing argument.");
    }
    return;
}

1;

__END__

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

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
