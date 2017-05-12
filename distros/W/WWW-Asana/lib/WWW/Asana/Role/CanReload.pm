package WWW::Asana::Role::CanReload;
BEGIN {
  $WWW::Asana::Role::CanReload::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::CanReload::VERSION = '0.003';
}
# ABSTRACT: Role for Asana classes which can be reloaded

use MooX::Role;

requires qw(
	own_base_args
	reload_base_args
);

sub reload_args {
	my ( $self ) = @_;
	$self->reload_base_args, $self->own_base_args;
}

sub reload {
	my $self = shift;
	$self->do($self->reload_args(@_));
}

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::CanReload - Role for Asana classes which can be reloaded

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

