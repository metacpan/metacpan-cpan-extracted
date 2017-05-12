package WWW::Asana::Task;
BEGIN {
  $WWW::Asana::Task::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Task::VERSION = '0.003';
}
# ABSTRACT: Asana Task Class

use MooX;

with 'WWW::Asana::Role::HasClient';
with 'WWW::Asana::Role::HasResponse';
with 'WWW::Asana::Role::NewFromResponse';

with 'WWW::Asana::Role::HasFollowers';
with 'WWW::Asana::Role::HasStories';

with 'WWW::Asana::Role::CanReload';
with 'WWW::Asana::Role::CanUpdate';
with 'WWW::Asana::Role::CanCreate';

use DateTime::Format::ISO8601;

sub own_base_args { 'tasks', shift->id }
sub reload_base_args { 'Task', 'GET' }
sub update_args {
	my ( $self ) = @_;
	'Task', 'PUT', $self->own_base_args, $self->value_args, sub { workspace => $self->workspace };
}
sub create_args {
	my ( $self ) = @_;
	'Task', 'POST', 'tasks', $self->value_args, sub { workspace => $self->workspace };
}

sub value_args {
	my ( $self ) = @_;
	return {
		workspace => $self->workspace->id,
		assignee => $self->has_assignee ? $self->assignee->id : undef,
		$self->has_name ? ( name => $self->name ) : (),
		$self->has_notes ? ( notes => $self->notes ) : (),
		$self->has_completed ? ( completed => $self->completed_value ) : (),
		$self->has_due_on ? ( due_on => $self->due_on_value ) : (),
	};
}

has id => (
	is => 'ro',
	predicate => 1,
);

has assignee => (
	is => 'rw',
	isa => sub {
		die "assignee must be a WWW::Asana::User" unless ref $_[0] eq 'WWW::Asana::User';
	},
	predicate => 1,
	clearer => 'clear_assignee',
);

has assignee_status => (
	is => 'ro',
	isa => sub {
		die "assignee_status must be inbox, later, today or upcoming"
			unless grep { $_[0] eq $_ } qw( inbox later today upcoming );
	},
);

has created_at => (
	is => 'ro',
	isa => sub {
		die "created_at must be a DateTime" unless ref $_[0] eq 'DateTime';
	},
	predicate => 1,
);

has completed => (
	is => 'rw',
	predicate => 1,
);
sub completed_value { shift->completed ? 'true' : 'false' }

has completed_at => (
	is => 'ro',
	isa => sub {
		die "completed_at must be a DateTime" unless ref $_[0] eq 'DateTime';
	},
	predicate => 1,
);

has due_on => (
	is => 'rw',
	isa => sub {
		die "due_on must be a DateTime" unless ref $_[0] eq 'DateTime';
	},
	predicate => 1,
	clearer => 'clear_due_on',
);
sub due_on_value { shift->due_on->ymd('-') }

has name => (
	is => 'rw',
	predicate => 1,
);

has notes => (
	is => 'rw',
	predicate => 1,
);

has workspace => (
	is => 'rw',
	isa => sub {
		die "workspace must be a WWW::Asana::Workspace" unless ref $_[0] eq 'WWW::Asana::Workspace';
	},
	required => 1,
);

sub projects {
	my ( $self ) = @_;
	$self->do('[Project]', 'GET', $self->own_base_args, 'projects', sub { workspace => $self->workspace });
}

sub add_project {
	my ( $self, $project ) = @_;
	return $self->do('', 'POST', $self->own_base_args, 'addProject', { project => $project->id } ) eq 1 ? 1 : 0;
}

sub remove_project {
	my ( $self, $project ) = @_;
	return $self->do('', 'POST', $self->own_base_args, 'removeProject', { project => $project->id } ) eq 1 ? 1 : 0;
}

sub tags {
	my ( $self ) = @_;
	$self->do('[Tag]', 'GET', $self->own_base_args, 'tags', sub { workspace => $self->workspace });
}

sub add_tag {
	my ( $self, $tag ) = @_;
	return $self->do('', 'POST', $self->own_base_args, 'addTag', { tag => $tag->id } ) eq 1 ? 1 : 0;
}

sub remove_tag {
	my ( $self, $tag ) = @_;
	return $self->do('', 'POST', $self->own_base_args, 'removeTag', { tag => $tag->id } ) eq 1 ? 1 : 0;
}

1;

__END__
=pod

=head1 NAME

WWW::Asana::Task - Asana Task Class

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

