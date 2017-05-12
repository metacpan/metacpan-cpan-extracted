package Text::Keywords::List;
BEGIN {
  $Text::Keywords::List::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Text::Keywords::List::VERSION = '0.900';
}
# ABSTRACT: Primitive keywords List class

use Moo;

has keywords => (
	is => 'ro',
	default => sub {[]},
);

sub count {
	scalar @{shift->keywords};
}

1;
__END__
=pod

=head1 NAME

Text::Keywords::List - Primitive keywords List class

=head1 VERSION

version 0.900

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

