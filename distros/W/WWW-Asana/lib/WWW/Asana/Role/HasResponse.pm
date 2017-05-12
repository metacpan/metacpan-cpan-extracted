package WWW::Asana::Role::HasResponse;
BEGIN {
  $WWW::Asana::Role::HasResponse::AUTHORITY = 'cpan:GETTY';
}
{
  $WWW::Asana::Role::HasResponse::VERSION = '0.003';
}
# ABSTRACT: 

use MooX::Role;

has response => (
	is => 'ro',
	predicate => 'has_response',
);

1;
__END__
=pod

=head1 NAME

WWW::Asana::Role::HasResponse -  

=head1 VERSION

version 0.003

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

