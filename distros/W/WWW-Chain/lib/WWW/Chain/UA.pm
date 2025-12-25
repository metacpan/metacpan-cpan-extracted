package WWW::Chain::UA;
our $VERSION = '0.101';
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for classes which have a request_chain function for a WWW::Chain object

use Moo::Role;

requires qw( request_chain );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Chain::UA - Role for classes which have a request_chain function for a WWW::Chain object

=head1 VERSION

version 0.101

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-chain>

  git clone https://github.com/Getty/p5-www-chain.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
