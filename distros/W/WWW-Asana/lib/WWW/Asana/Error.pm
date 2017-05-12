package WWW::Asana::Error;
BEGIN {
  $WWW::Asana::Error::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Error::VERSION = '0.003';
}
# ABSTRACT: Asana Error Class

use MooX;

has message => (
	is => 'ro',
	required => 1,
);

has phrase => (
	is => 'ro',
	predicate => 'has_phrase',
);

1;
__END__
=pod

=head1 NAME

WWW::Asana::Error - Asana Error Class

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

