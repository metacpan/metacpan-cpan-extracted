package Text::Treesitter::Bash::Security::Rule;
# ABSTRACT: Base class for security rules
our $VERSION = '0.001';
use strict;
use warnings;

sub check {
  my ( $class, $command ) = @_;
  die 'Abstract method check() must be implemented by subclass';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash::Security::Rule - Base class for security rules

=head1 VERSION

version 0.001

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-text-treesitter-bash/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
