package XUL::Node::Server::EventManager;

#
#       how do you let server code listen to client events?
#
#  * one per session
#  * used by session as an event factory- translates client requests into
#    server event objects
#  * the change manager is responsible for registering new nodes with me
#  * keeps a weak hash of nodes so when an event comes in from the server we
#    can find its source
#

use strict;
use warnings;
use Carp;
use Scalar::Util qw(weaken);
use XUL::Node::Server::Event;

sub new { bless {nodes => {}}, shift }

sub make_event {
	my ($self, $request) = @_;
	my $id = $request->{source};
	croak "cannot make event with no source" unless $id;
	$request->{source} = $self->get_node($id);
	croak "node with id [$id] not found" unless $request->{source};
	return XUL::Node::Server::Event->new($request);
}

sub register_node {
	my ($self, $id, $node) = @_;
	my $nodes = $self->{nodes};
	croak "cannot register node on an ID already taken by another node [$id]"
		if exists $nodes->{$id};
	$nodes->{$id} = $node;
	weaken $nodes->{$id};
}

# TODO: cleanup dangling weak ref now and then
sub get_node  { shift->{nodes}->{pop()} }
sub drop_node { delete shift->{nodes}->{pop()} }

1;

