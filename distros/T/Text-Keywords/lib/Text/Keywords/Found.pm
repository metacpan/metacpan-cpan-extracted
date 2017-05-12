package Text::Keywords::Found;
BEGIN {
  $Text::Keywords::Found::AUTHORITY = 'cpan:GETTY';
}
BEGIN {
  $Text::Keywords::Found::VERSION = '0.900';
}
# ABSTRACT: Class for a keyword found over a specific Text::Keywords::Container

use Moo;

has keyword => (
	is => 'ro',
	required => 1,
);

has found => (
	is => 'ro',
	required => 1,
);

has matches => (
	is => 'ro',
	default => sub {[]},
);

has in_primary => (
	is => 'ro',
	required => 1,
);

has in_secondary => (
	is => 'ro',
	required => 1,
);

has container => (
	is => 'ro',
	required => 1,
);

has list => (
	is => 'ro',
	required => 1,
);

1;
__END__
=pod

=head1 NAME

Text::Keywords::Found - Class for a keyword found over a specific Text::Keywords::Container

=head1 VERSION

version 0.900

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by L<Raudssus Social Software|http://www.raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

