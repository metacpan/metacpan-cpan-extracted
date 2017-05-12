package WWW::Asana::Role::CanCreate;
BEGIN {
  $WWW::Asana::Role::CanCreate::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::CanCreate::VERSION = '0.003';
}
# ABSTRACT: Role for Asana classes which can be created

use MooX::Role;

requires qw(
	create_args
);

sub create {
	my $self = shift;
	die "The object already has an id, and so cant be created" if $self->has_id;
	$self->do($self->create_args(@_));
}

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::CanCreate - Role for Asana classes which can be created

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

