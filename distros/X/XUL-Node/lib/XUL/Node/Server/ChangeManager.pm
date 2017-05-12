package XUL::Node::Server::ChangeManager;

#
#              how do you sync changes to the server node tree
#                     with the client user interface?
#
#  * one per session
#  * run_and_flush lets you run application code, and capture any changes
#    to the node tree, so they can be sent to the client side
#  * any code that runs through run_and_flush (it takes a block as its
#    parameter), will have side effects sent to the client (e.g. change
#    in the value attribute of a textfield)
#  * messages to the client are returned as a string
#  * we get them from the node state objects, which we create for each node
#  * the node state objects know what messsages need to be sent to the
#    client, because we intercept attributes changes, and node
#    creation/removal
#  * our intercept code passes node changes to the relevant node state
#    objects
#  * we keep a list of top level nodes (windows), so we can flush their node
#    state objects for any changes, recursively, on every call to
#    run_and_flush
#  * we keep the next node ID, because we are also the ID factory, and the
#    object that provides an ID to the node state
#  * the ID is used as a key, for identifying a XUL object on the client
#  * it is also used to find the server node that should handle an event
#    we receive from the client
#

use strict;
use warnings;
use Carp;
use Aspect;
use XUL::Node;
use XUL::Node::Server::NodeState;

# creating --------------------------------------------------------------------

# windows is list of all top level nodes
# destroyed is buffer of all states scheduled for destruction on next flush
# next_node_id is next available node ID minus 1
sub new { bless {windows => [], destroyed => [], next_node_id => 0}, shift }

# public interface for sessions -----------------------------------------------

# run some code ref and capture messages to client created by code
# then return these messages so they can be sent to the client
sub run_and_flush {
	my ($self, $code) = @_;
	local $_;
	$code->();
	my $out =
		(join '', map { $self->flush_node($_) } @{$self->windows}).
		(join '', map { $_->flush } @{$self->{destroyed}});
	$self->{destroyed} = [];
	return $out;
}

sub destroy {
	my $self = shift;
	$_->destroy for @{$self->{windows}};
	delete $self->{windows};
}

# advice ----------------------------------------------------------------------

my $Self_Flow = cflow source => __PACKAGE__.'::run_and_flush';

# when node attributes changes, let the node state object know about it
# if node has no state object, give it one
before {
	my $context = shift;
	my $self    = $context->source->self;
	my $node    = $context->self;
	my $key     = $context->params->[1];
	my $value   = $context->params->[2];
	my $state   = $self->get_or_make_node_state($node);

	if ($key eq 'tag') {

		croak "cannot change node tag" if $node->tag;
		$state->set_tag($value);
		# for each new node we register it as a window, if it is one
		push @{$self->windows}, $node if $value eq 'Window';

	} else {

		my $old = $node->get_attribute($key);
		if (defined $old && $old eq $value)
			{ $context->return_value($node) }
		else
			{ $state->set_attribute($key, $value) }

	}

} call 'XUL::Node::_set_attribute' & $Self_Flow;

# when node added, set parent node ID and child index on child node state
# if node has no state object, give it one
before {
	my $context      = shift;
	my $self         = $context->source->self;
	my $parent       = $context->self;
	my $parent_state = $self->get_or_make_node_state($parent);
	my $child        = $context->params->[1];
	my $index        = $context->params->[2];
	my $child_state  = $self->node_state($child);
    my $parent_id    = $parent_state->get_id;
	$child_state->set_parent_id($parent_id);
	$child_state->set_index($index);

} call 'XUL::Node::_add_child_at_index' & $Self_Flow;

# when node destroyed, update state using set_destoyed
before {
	my $context     = shift;
	my $self        = $context->source->self;
	my $parent      = $context->self;
	my $child       = $parent->_compute_child_and_index($context->params->[1]);
	my $child_state = $self->node_state($child);

	$child_state->set_destroyed;
	push @{$self->{destroyed}}, $child_state;
	# could run with no event manager
	$self->event_manager->drop_node($child) if $self->event_manager;
	# TODO: support removing windows

} call 'XUL::Node::remove_child' & $Self_Flow;

# private ---------------------------------------------------------------------

sub flush_node {
	my ($self, $node) = @_;
	my $out = $self->node_state($node)->flush;
	$out .= $self->flush_node($_) for $node->children;
	return $out;
}

sub get_or_make_node_state {
	my ($self, $node) = @_;
	my $state = $self->node_state($node);
	return $state if $state;

	# we give the node state a new ID
	# we give it the node state object
	# we register the node for receiving events from its client half
	my $id = 'E'. ++$self->{next_node_id};
	$state = XUL::Node::Server::NodeState->new(id => $id);
	$self->node_state($node, $state);
	# could run with no event manager
	$self->event_manager->register_node($id, $node) if $self->event_manager;
	return $state;
}

sub node_state {
	my ($self, $node, $state) = @_;
	croak "not a node: [$node]" unless UNIVERSAL::isa($node, 'XUL::Node');
	return $node->{state} unless $state;
	$node->{state} = $state;
}

sub event_manager {
	my ($self, $event_manager) = @_;
	return $self->{event_manager} unless $event_manager;
	$self->{event_manager} = $event_manager;
}

# testing ---------------------------------------------------------------------

sub windows { shift->{windows} }

1;

