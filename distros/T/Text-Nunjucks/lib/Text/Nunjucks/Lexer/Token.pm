package Text::Nunjucks::Lexer::Token;
# ABSTRACT: One lexer token -- type, value, line and column (lexer.js token())

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

# upstream: function token(type, value, lineno, colno) -- the
# { type, value, lineno, colno } record the Tokenizer hands out.

has type   => ( is => 'ro' );
has value  => ( is => 'ro' );
has lineno => ( is => 'ro' );
has colno  => ( is => 'ro' );

# token(type, value, lineno, colno) is positional upstream. `value` is a plain
# string for every token except a regex, whose value is the { body, flags }
# hashref upstream builds (its runtime representation is decided in k7).
sub BUILDARGS {
  my ( $class, $type, $value, $lineno, $colno ) = @_;
  return {
    type   => $type,
    value  => $value,
    lineno => $lineno,
    colno  => $colno
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Lexer::Token - One lexer token -- type, value, line and column (lexer.js token())

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: a token as L<Text::Nunjucks::Lexer::Tokenizer> yields it, with
C<type>, C<value>, C<lineno> and C<colno> (0-based, as in the JavaScript
original). See L<Text::Nunjucks::Lexer>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-text-nunjucks/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
