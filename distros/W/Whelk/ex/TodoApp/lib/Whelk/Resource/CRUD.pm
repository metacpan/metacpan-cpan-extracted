package Whelk::Resource::CRUD;

use Kelp::Base 'Whelk::Resource';
use Whelk::Schema;
use Whelk::Exception;
use Time::Piece;
use TodoStorage;

attr 'storage' => sub { TodoStorage->new };

sub build_schemas
{
	Whelk::Schema->build(
		todo_id => {
			type => 'integer',
			example => 13,
		}
	);

	Whelk::Schema->build(
		todo_data => {
			type => 'object',
			properties => {
				name => {
					type => 'string',
					example => 'weekly chores',
				},
				content => {
					type => 'string',
					example => 'take out the trash, feed the dog',
				},
				date => {
					type => 'string',
					example => 'friday',
				},
			},
		}
	);
}

sub api
{
	my ($self) = @_;
	$self->build_schemas;

	$self->add_endpoint(
		[GET => '/'] => 'action_list',
		description => 'Returns a list of all todo instances',
		response => {
			type => 'array',
			items => {
				type => 'object',
				properties => {
					id => \'todo_id',
					data => \'todo_data',
				}
			},
		},
	);

	$self->add_endpoint(
		[GET => '/:id'] => 'action_read',
		description => 'Returns a single instance of todo',
		parameters => {
			path => {
				id => \'todo_id',
			},
		},
		response => \'todo_data',
	);

	$self->add_endpoint(
		[PUT => '/'] => 'action_create',
		description => 'Create a new instance of todo',
		request => [
			\'todo_data',
			properties => {
				date => {
					required => !!0,
				}
			}
		],
		response => {
			type => 'object',
			properties => {
				id => \'todo_id',
			},
		},
	);

	$self->add_endpoint(
		[POST => '/:id'] => 'action_update',
		description => 'Update an instance of todo',
		parameters => {
			path => {
				id => \'todo_id',
			},
		},
		request => [
			\'todo_data',
			properties => {
				name => {
					required => !!0,
				},
				content => {
					required => !!0,
				},
				date => {
					required => !!0,
				},
			}
		],
		response => {
			type => 'empty',
			description => 'todo updated successfully',
		},
	);

	$self->add_endpoint(
		[DELETE => '/:id'] => 'action_delete',
		description => 'Delete an instance of todo',
		parameters => {
			path => {
				id => \'todo_id',
			},
		},
		response => {
			type => 'empty',
			description => 'todo deleted successfully',
		},
	);
}

sub action_list
{
	my ($self) = @_;

	my @result;
	foreach my $id (@{$self->storage->stored}) {
		push @result, {
			id => $id,
			data => $self->storage->get($id),
		};
	}

	return \@result;
}

sub action_read
{
	my ($self, $id) = @_;

	my $stored = $self->storage->get($id);
	Whelk::Exception->throw(404, hint => 'No such todo')
		if !defined $stored;

	return $stored;
}

sub action_create
{
	my ($self) = @_;
	my $data = $self->request_body;
	$data->{date} //= localtime->strftime;

	my $id = $self->storage->set(undef, $data);
	return {id => $id};
}

sub action_update
{
	my ($self, $id) = @_;
	my $data = $self->request_body;
	my $stored = $self->storage->get($id);

	Whelk::Exception->throw(404, hint => 'No such todo')
		if !defined $stored;

	foreach my $key (keys %$stored) {
		$data->{$key} = $stored->{$key}
			if !exists $data->{$key};
	}

	$self->storage->set($id, $data);
	return undef;
}

sub action_delete
{
	my ($self, $id) = @_;

	Whelk::Exception->throw(404, hint => 'No such todo')
		if !$self->storage->unset($id);

	return undef;
}

1;

