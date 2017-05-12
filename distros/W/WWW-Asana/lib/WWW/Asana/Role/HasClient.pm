package WWW::Asana::Role::HasClient;
BEGIN {
  $WWW::Asana::Role::HasClient::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::HasClient::VERSION = '0.003';
}
# ABSTRACT: Role for a class which has a WWW::Asana client

use MooX::Role;

has client => (
	is => 'ro',
	isa => sub {
		die "client must be a WWW::Asana" unless ref $_[0] eq 'WWW::Asana';
	},
	predicate => 'has_client',
	handles => [qw(
		do
	)],
);

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::HasClient - Role for a class which has a WWW::Asana client

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

