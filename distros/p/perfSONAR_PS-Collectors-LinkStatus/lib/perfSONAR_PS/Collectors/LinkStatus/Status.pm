package perfSONAR_PS::Collectors::LinkStatus::Status;

=head1 NAME

perfSONAR_PS::Collectors::LinkStatus::Status - A module that provides an object
describing the current status of a circuit.

=head1 DESCRIPTION

This module is to be treated as an object representing the status of a circuit
at a certain point in time.
=cut

use strict;
use warnings;

use fields 'TIME', 'OPER_STATE', 'ADMIN_STATE';

use perfSONAR_PS::Status::Common;

our $VERSION = 0.09;

sub new {
    my ($class, $time, $oper_state, $admin_state) = @_;

    my $self = fields::new($class);

    if (defined $time and $time ne "") {
        $self->{"TIME"} = $time;
    }

    if (defined $oper_state and $oper_state ne "") {
        if (isValidOperState($oper_state) == 0) {
            return;
        }

        $self->{"OPER_STATE"} = $oper_state;
    }

    if (defined $admin_state and $admin_state ne "" and isValidAdminState($admin_state) == 0) {
        if (isValidAdminState($admin_state) == 0) {
            return;
        }

        $self->{"ADMIN_STATE"} = $admin_state;
    }

    return $self;
}

=head2 getTime ($self)
    Returns the time during which the circuit had this status
=cut
sub getTime {
    my ($self) = @_;

    return $self->{TIME};
}

=head2 getOperState ($self)
    Returns the operational state
=cut
sub getOperState {
    my ($self) = @_;

    return $self->{OPER_STATE};
}

=head2 getAdminState ($self)
    Returns the administrative state
=cut
sub getAdminState {
    my ($self) = @_;

    return $self->{ADMIN_STATE};
}

=head2 setTime ($self, $time)
    Sets the time that the status was seen
=cut
sub setTime {
    my ($self, $time) = @_;

    $self->{TIME} = $time;

    return;
}

=head2 setOperStatus ($self, $operState)
    Sets the operation state. Returns 0 if successful. Returns -1 if the
    operState is not valid.
=cut
sub setOperState {
    my ($self, $oper_state) = @_;

    if (isValidOperState($oper_state) == 0) {
        return -1;
    }

    $self->{OPER_STATE} = $oper_state;

    return 0;
}

=head2 setAdminStatus ($self, $adminState)
    Sets the administrative state. Returns 0 if successful. Returns -1 if the
    adminState is not valid.
=cut
sub setAdminState {
    my ($self, $admin_state) = @_;

    if (isValidAdminState($admin_state) == 0) {
        return -1;
    }

    $self->{ADMIN_STATE} = $admin_state;

    return 0;
}

=head2 updateOperState ($self, $operState)
    This function updates the operational state with new information. This is
    used to aggregate the state of a circuit based on the state of its links.
    So, if for example, an up and a down are seen, the new status will be down.
=cut
sub updateOperState {
    my ($self, $oper_state) = @_;

    if (isValidOperState($oper_state) == 0) {
        return -1;
    }

    if (not defined $self->{OPER_STATE}) {
        $self->{OPER_STATE} = $oper_state;
    } elsif ($self->{OPER_STATE} eq "unknown" or $oper_state eq "unknown") {
        $self->{OPER_STATE} = "unknown";
    } elsif ($self->{OPER_STATE} eq "down" or $oper_state eq "down")  {
        $self->{OPER_STATE} = "down";
    } elsif ($self->{OPER_STATE} eq "degraded" or $oper_state eq "degraded")  {
        $self->{OPER_STATE} = "degraded";
    } elsif ($self->{OPER_STATE} eq "up" or $oper_state eq "up")  {
        $self->{OPER_STATE} = "up";
    }

    return 0;
}

=head2 updateAdminState ($self, $adminState)
    This function updates the administrative state with new information. This is
    used to aggregate the state of a circuit based on the state of its links.
    So, if for example, an normal and a troubleshooting are seen, the new
    status will be troubleshooting.
=cut
sub updateAdminState {
    my ($self, $admin_state) = @_;

    if (isValidAdminState($admin_state) == 0) {
        return -1;
    }

    if (not defined $self->{ADMIN_STATE}) {
        $self->{ADMIN_STATE} = $admin_state;
    } elsif ($self->{ADMIN_STATE} eq "unknown" or $admin_state eq "unknown") {
        $self->{ADMIN_STATE} = "unknown";
    } elsif ($self->{ADMIN_STATE} eq "maintenance" or $admin_state eq "maintenance") {
        $self->{ADMIN_STATE} = "maintenance";
    } elsif ($self->{ADMIN_STATE} eq "troubleshooting" or $admin_state eq "troubleshooting") {
        $self->{ADMIN_STATE} = "troubleshooting";
    } elsif ($self->{ADMIN_STATE} eq "underrepair" or $admin_state eq "underrepair") {
        $self->{ADMIN_STATE} = "underrepair";
    } elsif ($self->{ADMIN_STATE} eq "normaloperation" or $admin_state eq "normaloperation") {
        $self->{ADMIN_STATE} = "normaloperation";
    }

    return 0;
}

1;

__END__
=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
