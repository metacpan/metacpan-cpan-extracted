###########################################################################
# Copyright 2000, 2001, 2004 Toby Ovod-Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at toby@ovod-everett.org
##########################################################################

package Win32::CtrlGUI::State::bookkeeper;

use strict;
use 5.006;

use Win32::CtrlGUI;
use Win32::CtrlGUI::State;

our $VERSION = '0.32'; # VERSION from OurPkgVersion

sub new {
	my $class = shift;
	my($state) = @_;

	my $self = {
		state => $state,
		status => 'pfs',
		executed => 0,
	};

	bless $self, $class;
	return $self;
}

sub bk_status {
	my $self = shift;

	return $self->{status};
}

sub bk_set_status {
	my $self = shift;
	my($status) = @_;

	$status =~ /^comp|active|pcs|pfs|never$/ or die "Win32::CtrlGUI::State::bookkeeper::bk_set_status error: attempt to set illegal status of $status.";
	$self->{status} = $status;
}

sub bk_status_given {
	my $self = shift;
	my($pstatus) = @_;

	$pstatus =~ /^active|pcs|pfs|never$/ or die "Win32::CtrlGUI::State::bookkeeper::bk_status_given error: illegal status passed: $pstatus.";

	($self->bk_status eq 'active' && $pstatus !~ /^active|pfs$/) and die "Win32::CtrlGUI::State::bookkeeper::bk_status_given error: A child state is not allowed to be active if the parent is not.";
	$self->bk_status eq 'active' and return 'active';
	foreach my $i (qw(never pfs pcs active)) {
		($self->bk_status eq $i || $pstatus eq $i) and return $i;
	}
	die "Win32::CtrlGUI::State::bookkeeper::bk_status_given error: Should never get here.";
}

sub is_recognized {
	my $self = shift;

	$self->bk_status =~ /^active|pcs$/ or die "Win32::CtrlGUI::State::bookkeeper::is_recognized error: Cannot call in state ".$self->bk_status.".";
	return $self->{state}->is_recognized;
}

sub wait_recognized {
	my $self = shift;

	$self->bk_status =~ /^active|pcs$/ or die "Win32::CtrlGUI::State::bookkeeper::wait_recognized error: Cannot call in state ".$self->bk_status.".";
	return $self->{state}->wait_recognized;
}

sub do_action_step {
	my $self = shift;

	$self->bk_status eq 'active' or die "Win32::CtrlGUI::State::bookkeeper::do_action_step error: Cannot call in state ".$self->bk_status.".";
	$self->{state}->do_action_step;
}

sub wait_action {
	my $self = shift;

	$self->bk_status eq 'active' or die "Win32::CtrlGUI::State::bookkeeper::wait_action error: Cannot call in state ".$self->bk_status.".";
	return $self->{state}->wait_action;
}

sub do_state {
	my $self = shift;

	$self->bk_status =~ /^active|pcs$/ or die "Win32::CtrlGUI::State::bookkeeper::do_state error: Cannot call in state ".$self->bk_status.".";
	return $self->{state}->do_state;
}

sub reset {
	my $self = shift;

	return $self->{state}->reset;
}

sub AUTOLOAD {
	(my $func = our $AUTOLOAD) =~ s/^.*:://;

	no strict;
	*{$func} = $method = sub {
		my $self = shift;
		return $self->{state}->$func(@_);
	};
	goto &$method;
}

1;

# No documentation:

=for Pod::Coverage
.+

=cut
