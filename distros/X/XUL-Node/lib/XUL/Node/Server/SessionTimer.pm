package XUL::Node::Server::SessionTimer;

use strict;
use warnings;
use Carp;
use POE;

use constant {
	POE_SESSION_KEEP_ALIVE => 60 * 60 * 24,
	USER_SESSION_TIMEOUT   => 60 * 10,
};

sub new {
	my ($class, $timeout_callback) = @_;
	local $_;
	
	my $self = bless {
		timeout_callback => $timeout_callback,
		session_timers   => {},
	};
	$self->{poe_session} = POE::Session->create(object_states => [$self => [qw(
		_start
		internal_keep_alive
		user_session_keep_alive_event
		user_session_timeout
	)]]);
	return $self;
}

sub user_session_keep_alive {
	my ($self, $session_id) = @_;
	$poe_kernel->post
		($self->{poe_session}, 'user_session_keep_alive_event', $session_id);
}

# private event handlers ------------------------------------------------------

sub _start { shift->internal_keep_alive }

sub internal_keep_alive
	{ $poe_kernel->delay_set(internal_keep_alive => POE_SESSION_KEEP_ALIVE) }

sub user_session_timeout {
	my $self = shift;
	my $session_id = pop;
	delete $self->{session_timers}->{$session_id};
	$self->{timeout_callback}->($session_id);
}

sub user_session_keep_alive_event {
	my $self = shift;
	my $session_id = pop;
	my $timers = $self->{session_timers};
	$poe_kernel->alarm_remove($timers->{session_id}) if $timers->{session_id};
	$timers->{session_id} = $poe_kernel->delay_set
		(user_session_timeout => USER_SESSION_TIMEOUT, $session_id);
}

1;

