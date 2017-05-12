package perfSONAR_PS::Status::Link;

use strict;
use warnings;

our $VERSION = 0.09;

use fields 'ID', 'KNOWLEDGE', 'START_TIME', 'END_TIME', 'OPER_STATUS', 'ADMIN_STATUS';

sub new {
    my ($package, $link_id, $knowledge, $start_time, $end_time, $oper_status, $admin_status) = @_;

    my $self = fields::new($package);

    if (defined $link_id and $link_id ne "") {
        $self->{ID} = $link_id;
    }

    if (defined $knowledge and $knowledge ne "") {
        $self->{KNOWLEDGE} = $knowledge;
    }
    if (defined $start_time and $start_time ne "") {
        $self->{START_TIME} = $start_time;
    }
    if (defined $end_time and $end_time ne "") {
        $self->{END_TIME} = $end_time;
    }
    if (defined $oper_status and $oper_status ne "") {
        $self->{OPER_STATUS} = $oper_status;
    }
    if (defined $admin_status and $admin_status ne "") {
        $self->{ADMIN_STATUS} = $admin_status;
    }

    return $self;
}

sub setID {
    my ($self, $id) = @_;

    $self->{ID} = $id;

    return;
}

sub setKnowledge {
    my ($self, $knowledge) = @_;

    $self->{KNOWLEDGE} = $knowledge;

    return;
}

sub setStartTime {
    my ($self, $starttime) = @_;

    $self->{START_TIME} = $starttime;

    return;
}

sub setEndTime {
    my ($self, $endtime) = @_;

    $self->{END_TIME} = $endtime;

    return;
}

sub setOperStatus {
    my ($self, $oper_status) = @_;

    $self->{OPER_STATUS} = $oper_status;

    return;
}

sub setAdminStatus {
    my ($self, $admin_status) = @_;

    $self->{ADMIN_STATUS} = $admin_status;

    return;
}

sub getID {
    my ($self) = @_;

    return $self->{ID};
}

sub getKnowledge {
    my ($self) = @_;

    return $self->{KNOWLEDGE};
}

sub getStartTime {
    my ($self) = @_;

    return $self->{START_TIME};
}

sub getEndTime {
    my ($self) = @_;

    return $self->{END_TIME};
}

sub getOperStatus {
    my ($self) = @_;

    return $self->{OPER_STATUS};
}

sub getAdminStatus {
    my ($self) = @_;

    return $self->{ADMIN_STATUS};
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
 
Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
