package perfSONAR_PS::Collectors::LinkStatus::Link;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);

use perfSONAR_PS::Collectors::LinkStatus::Status;

our $VERSION = 0.09;

use fields 'IDS', 'KNOWLEDGE', 'AGENTS', 'TIME_PRIORITIES', 'TIME_SOURCE';

sub new {
    my ($class, $link_ids, $knowledge, $agents) = @_;

    my $self = fields::new($class);

    if (defined $link_ids and $link_ids ne "") {
        $self->{IDS} = $link_ids;
    }

    if (defined $knowledge and $knowledge ne "") {
        $self->{KNOWLEDGE} = $knowledge;
    }

    if (defined $agents and $agents ne "") {
        $self->{AGENTS} = $agents;
    }

    return $self;
}

sub setIDs {
    my ($self, $ids) = @_;

    $self->{IDS} = $ids;

    return;
}

sub setKnowledge {
    my ($self, $knowledge) = @_;

    $self->{KNOWLEDGE} = $knowledge;

    return;
}

sub setPrimaryTimeSource {
    my ($self, $time_source) = @_;

    $self->{TIME_SOURCE} = $time_source;

    return;
}

sub addID {
    my ($self, $id) = @_;

    push @{ $self->{IDS} }, $id;

    return;
}

sub addAgent {
    my ($self, $agent) = @_;

    push @{ $self->{AGENTS} }, $agent;

    return;
}

sub setAgents {
    my ($self, $agents) = @_;

    $self->{AGENTS} = $agents;

    return;
}

sub setStatus {
    my ($self, $status) = @_;

    $self->{STATUS} = $status;

    return;
}

sub getIDs {
    my ($self) = @_;

    return $self->{IDS};
}

sub getKnowledge {
    my ($self) = @_;

    return $self->{KNOWLEDGE};
}

sub getAgents {
    my ($self) = @_;

    return $self->{AGENTS};
}

sub getStatus {
    my ($self) = @_;

    return $self->{STATUS};
}

# XXX this needs to be able to handle an agent returning something other than the "current" link status
sub measure {
    my($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::Link");

    my @link_statuses = ();

    my $link_status = new perfSONAR_PS::Collectors::LinkStatus::Status("", "", "");

    my $link_status_time;

    foreach my $agent (@{ $self->{AGENTS} }) {
        my ($status, $res1, $res2) = $agent->run();
        if ($status != 0) {
            $logger->error("Agent failed: $res1");
            return (-1, $res1);
        }

        my $time = $res1;
        my $value = $res2;

        $logger->debug($agent->getType()." agent returned ".$time.", ".$value);

        if (defined $self->{TIME_SOURCE} and $self->{TIME_SOURCE} eq $agent) {
            $logger->debug("Setting time from an agent");
            $link_status_time = $time;
        }

        if ($agent->getType() eq "admin") {
            $link_status->updateAdminState($value);
        } else {
            $link_status->updateOperState($value);
        }
    }

    if (not defined $link_status_time or $link_status_time eq "") {
        $link_status_time = time; # substitute the MPs time since we don't know the agent's time
    }

    $link_status->setTime($link_status_time);

    push @link_statuses, $link_status;

    return (0, \@link_statuses);
}

1;

__END__
=head1 NAME

perfSONAR_PS::Status::Link - A module that provides an object with an interface
for link status information.

=head1 DESCRIPTION

This module is to be treated as an object representing the status of a link for
a certain range of time.

=head1 SYNOPSIS

=head1 DETAILS

=head1 API

=head2 new ($package, $link_id, $knowledge, $start_time, $end_time, $oper_status, $admin_status)

    Creates a new instance of a link object with the specified values (None of
            which is required, they can all be set later).

=head2 setID ($self, $id)

    Sets the identifier for this link.

=head2 setKnowledge ($self, $knowledge)

    Sets the knowledge level for the information about this link.

=head2 setStartTime ($self, $starttime)

    Sets the start time of the range over which this link had the specified status

=head2 setEndTime ($self, $endtime)

    Sets the end time of the range over which this link had the specified status

=head2 setOperStatus ($self, $oper_status)

    Sets the operational status of this link over the range of time specified

=head2 setAdminStatus ($self, $admin_status)

    Sets the administrative status of this link over the range of time specified

=head2 getID ($self)

    Gets the identifier for this link

=head2 getKnowledge ($self)

    Gets the knowledge level for the information about this link.

=head2 getStartTime ($self)

    Gets the start time of the range over which this link had the specified status

=head2 getEndTime ($self)

    Gets the end time of the range over which this link had the specified status

=head2 getOperStatus ($self)

    Gets the operational status of this link

=head2 getAdminStatus ($self)

    Gets the administrative status of this link

    =head1 LICENSE

    You should have received a copy of the Internet2 Intellectual Property Framework along
    with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

    =head1 COPYRIGHT

    Copyright (c) 2004-2007, Internet2 and the University of Delaware

    All rights reserved.

    =cut

# vim: expandtab shiftwidth=4 tabstop=4
