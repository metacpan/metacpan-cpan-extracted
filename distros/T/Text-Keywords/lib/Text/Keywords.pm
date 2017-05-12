package Text::Keywords;
BEGIN {
  $Text::Keywords::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Text::Keywords::VERSION = '0.900';
}
# ABSTRACT: Setup Text::Keywords::Container for analyzing some text

use Moo;

has containers => (
	is => 'rw',
	default => sub {[]},
);

sub from {
	my ( $self, $primary, $secondary ) = @_;
	
	my @founds;

	for (@{$self->containers}) {
		push @founds, $_->find_keywords($primary, $secondary);
	}
	
	@founds = $self->modify_founds(@founds);

	return @founds;
}

sub modify_founds {
	my ( $self, @founds ) = @_;
	return @founds;
}

1;

__END__
=pod

=head1 NAME

Text::Keywords - Setup Text::Keywords::Container for analyzing some text

=head1 VERSION

version 0.900

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

