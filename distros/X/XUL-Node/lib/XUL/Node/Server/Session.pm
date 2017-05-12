package XUL::Node::Server::Session;

use strict;
use warnings;
use Carp;
use XUL::Node::Application;
use XUL::Node::Server::ChangeManager;
use XUL::Node::Server::EventManager;

# public ----------------------------------------------------------------------

sub new {
	my $class = shift;
	my $self = bless {
		change_manager => XUL::Node::Server::ChangeManager->new,
		event_manager  => XUL::Node::Server::EventManager->new,
		start_time     => time,
		application    => undef,
	}, $class;
	$self->change_manager->event_manager($self->event_manager);
	return $self;
}

sub handle_boot {
	my ($self, $request) = @_;
	$self->{application} = XUL::Node::Application->create($request->{name});
	return $self->run_and_flush(sub { $self->{application}->start });
}

sub handle_event {
	my ($self, $request) = @_;
	my $event = $self->make_event($request);
	return $self->run_and_flush(sub { $event->fire });
}

sub destroy {
	my $self = shift;
	$self->{change_manager}->destroy;
}

# private ---------------------------------------------------------------------

sub run_and_flush  { shift->change_manager->run_and_flush(pop) }
sub make_event     { shift->event_manager->make_event(pop) }
sub change_manager { shift->{change_manager} }
sub event_manager  { shift->{event_manager} }

# testing ---------------------------------------------------------------------

sub get_node { shift->{event_manager}->get_node(pop) }

1;