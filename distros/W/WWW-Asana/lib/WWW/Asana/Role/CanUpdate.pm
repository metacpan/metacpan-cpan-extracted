package WWW::Asana::Role::CanUpdate;
BEGIN {
  $WWW::Asana::Role::CanUpdate::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::CanUpdate::VERSION = '0.003';
}
# ABSTRACT: Role for Asana classes which can be updated

use MooX::Role;

requires qw(
	update_args
);

sub update {
	my $self = shift;
	$self->do($self->update_args(@_));
}

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::CanUpdate - Role for Asana classes which can be updated

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

