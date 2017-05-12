package WWW::Asana::Role::HasFollowers;
BEGIN {
  $WWW::Asana::Role::HasFollowers::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::HasFollowers::VERSION = '0.003';
}
# ABSTRACT: Role for a class which has followers

use MooX::Role;

has followers => (
	is => 'ro',
	isa => sub {
		die "followers must be an ArrayRef" unless ref $_[0] eq 'ARRAY';
		die "followers must be an ArrayRef of WWW::Asana::User" if grep { ref $_ ne 'WWW::Asana::User' } @{$_[0]};
	},
	predicate => 'has_followers',
);

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::HasFollowers - Role for a class which has followers

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

