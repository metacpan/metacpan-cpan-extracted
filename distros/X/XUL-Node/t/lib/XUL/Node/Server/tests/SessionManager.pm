package XUL::Node::Server::tests::SessionManager;

use strict;
use warnings;
use Carp;
use Test::More;
use Test::Exception;
use XUL::tests::Assert;
use XUL::Node::Server::SessionManager;

use base 'Test::Class';

sub subject_class { 'XUL::Node::Server::SessionManager' }

sub create: Test { is ref pop, shift->subject_class }

sub make_session_id: Test {
	my ($self, $subject) = @_;
	my $id1 = $subject->make_session_id;
	my $id2 = $subject->make_session_id;
	isnt $id1, $id2;
}

sub boot: Test(2) {
	my ($self, $subject) = @_;
	my ($session_id, $result) = $self->boot_application($subject, 'HelloWorld');
	ok $session_id, 'session ID';
	is_xul
		$result,
		[qw(
			E2.new.window.0
			E2.set.sizeToContent.1
			E1.new.label.E2.0
			E1.set.value.Hello_World!
		)],
		'xul message';
}

sub event: Test {
	my ($self, $subject) = @_;
	my $session_id = $self->boot_application($subject, 'ButtonExample');
	is_xul
		$self->fire_click_from_e2($subject, $session_id),
		['E2.set.label.1'];
}

sub events_from_2_sessions: Test {
	my ($self, $subject) = @_;
	my $session_id1 = $self->boot_application($subject, 'ButtonExample');
	my $session_id2 = $self->boot_application($subject, 'ButtonExample');
	$self->fire_click_from_e2($subject, $session_id1);
	is_xul
		$self->fire_click_from_e2($subject, $session_id2),
		['E2.set.label.1'];
}

sub event_with_no_session_id_before_boot: Test {
	my ($self, $subject) = @_;
	throws_ok { $self->fire_click_from_e2($subject) }
		qr/no session ID/;
}

sub event_with_none_existing_session: Test {
	my ($self, $subject) = @_;
	throws_ok
		{ $self->fire_click_from_e2($subject, 'non-existing-session-id') }
		qr/session not found/;
}

sub boot_application {
	my ($self, $subject, $name) = @_;
	my ($session_id, $result) = split
		/\n/,
		$subject->handle_request({type => BOOT_REQUEST_TYPE, name => $name}),
		2;
	return wantarray? ($session_id, $result): $session_id;
}

sub fire_click_from_e2 {
	my ($self, $subject, $session_id) = @_;
	return $subject->handle_request({
		type    => EVENT_REQUEST_TYPE,
		name    => 'Click',
		source  => 'E2',
		session => $session_id,
	});
}

1;


