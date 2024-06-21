package WWW::Chain::UA;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for classes which have a request_chain function for a WWW::Chain object
$WWW::Chain::UA::VERSION = '0.007';
use Moo::Role;

requires qw( request_chain );

1;

__END__

=pod

=head1 NAME

WWW::Chain::UA - Role for classes which have a request_chain function for a WWW::Chain object

=head1 VERSION

version 0.007

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
