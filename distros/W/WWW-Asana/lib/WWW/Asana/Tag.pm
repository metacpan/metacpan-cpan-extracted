package WWW::Asana::Tag;
BEGIN {
  $WWW::Asana::Tag::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Tag::VERSION = '0.003';
}
# ABSTRACT: Asana Tag Class

use MooX;

with 'WWW::Asana::Role::HasClient';
with 'WWW::Asana::Role::HasResponse';
with 'WWW::Asana::Role::NewFromResponse';

with 'WWW::Asana::Role::HasFollowers';

with 'WWW::Asana::Role::CanReload';
with 'WWW::Asana::Role::CanUpdate';

sub own_base_args { 'tags', shift->id }

sub reload_base_args { 'Tag', 'GET' }
sub update_args {
	my ( $self ) = @_;
	'Tag', 'PUT', $self->own_base_args, $self->value_args;
}
sub create_args {
	my ( $self ) = @_;
	'Tag', 'POST', 'tags', $self->value_args;
}
sub value_args {
	my ( $self ) = @_;
	return {
		workspace => $self->workspace->id,
		$self->has_name ? ( name => $self->name ) : (),
		$self->has_notes ? ( notes => $self->notes ) : (),
	};
}

has id => (
	is => 'ro',
	predicate => 1,
);

has name => (
	is => 'rw',
	predicate => 1,
);

has notes => (
	is => 'rw',
	predicate => 1,
);

has created_at => (
	is => 'ro',
	isa => sub {
		die "created_at must be a DateTime" unless ref $_[0] eq 'DateTime';
	},
	predicate => 1,
);

has workspace => (
	is => 'ro',
	isa => sub {
		die "workspace must be a WWW::Asana::Workspace" unless ref $_[0] eq 'WWW::Asana::Workspace';
	},
	required => 1,
);

1;

__END__
=pod

=head1 NAME

WWW::Asana::Tag - Asana Tag Class

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

