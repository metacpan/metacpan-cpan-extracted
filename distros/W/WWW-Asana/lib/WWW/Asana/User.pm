package WWW::Asana::User;
BEGIN {
  $WWW::Asana::User::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::User::VERSION = '0.003';
}
# ABSTRACT: Asana User Class

use MooX;

with 'WWW::Asana::Role::HasClient';
with 'WWW::Asana::Role::HasResponse';
with 'WWW::Asana::Role::NewFromResponse';

with 'WWW::Asana::Role::CanReload';
# CanNotUpdate
# CanNotCreate
# CanNotDelete

sub own_base_args { 'users', shift->id }
sub reload_base_args { 'User', 'GET' }

has id => (
	is => 'ro',
	required => 1,
);

has name => (
	is => 'ro',
	predicate => 1,
);

has email => (
	is => 'ro',
	predicate => 1,
);

has workspaces => (
	is => 'ro',
	isa => sub {
		die "workspaces must be an ArrayRef" unless ref $_[0] eq 'ARRAY';
		die "workspaces must be an ArrayRef of WWW::Asana::Workspace" if grep { ref $_ ne 'WWW::Asana::Workspace' } @{$_[0]};
	},
	predicate => 1,
);

1;

__END__
=pod

=head1 NAME

WWW::Asana::User - Asana User Class

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

