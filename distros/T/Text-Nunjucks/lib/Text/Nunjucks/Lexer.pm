package Text::Nunjucks::Lexer;
# ABSTRACT: 1:1 port of Nunjucks src/lexer.js -- the template tokenizer

our $VERSION = '0.001';

use strict;
use warnings;
use Text::Nunjucks::Lexer::Token;
use Text::Nunjucks::Lexer::Tokenizer;

# 1:1 port of upstream src/lexer.js. lexer.js is one file that holds: the `let`
# constants (whitespace/delim/int char sets, the six default tag delimiters and
# the TOKEN_* type strings), a module-level `token()` factory, the `Tokenizer`
# class, and a `module.exports = { lex, TOKEN_* }`. The port splits it along
# its classes (ADR 0020):
#
#   * this module is lexer.js's module scope and exports: lex() plus the
#     TOKEN_* names as class methods, mirroring module.exports so a consumer
#     reads Text::Nunjucks::Lexer->lex and ->TOKEN_SYMBOL just as parser.js
#     reads lexer.lex / lexer.TOKEN_SYMBOL. The TOKEN_* strings are file
#     lexicals here, the single source the exported methods return;
#   * `Tokenizer` is Text::Nunjucks::Lexer::Tokenizer, which also holds the
#     char-set and default-tag constants only it reads, and reads the TOKEN_*
#     strings back through this module's exports;
#   * `token()` builds a Text::Nunjucks::Lexer::Token.

#### module constants (upstream: the TOKEN_* `let` bindings at the top of lexer.js)

my $TOKEN_STRING         = 'string';
my $TOKEN_WHITESPACE     = 'whitespace';
my $TOKEN_DATA           = 'data';
my $TOKEN_BLOCK_START    = 'block-start';
my $TOKEN_BLOCK_END      = 'block-end';
my $TOKEN_VARIABLE_START = 'variable-start';
my $TOKEN_VARIABLE_END   = 'variable-end';
my $TOKEN_COMMENT        = 'comment';
my $TOKEN_LEFT_PAREN     = 'left-paren';
my $TOKEN_RIGHT_PAREN    = 'right-paren';
my $TOKEN_LEFT_BRACKET   = 'left-bracket';
my $TOKEN_RIGHT_BRACKET  = 'right-bracket';
my $TOKEN_LEFT_CURLY     = 'left-curly';
my $TOKEN_RIGHT_CURLY    = 'right-curly';
my $TOKEN_OPERATOR       = 'operator';
my $TOKEN_COMMA          = 'comma';
my $TOKEN_COLON          = 'colon';
my $TOKEN_TILDE          = 'tilde';
my $TOKEN_PIPE           = 'pipe';
my $TOKEN_INT            = 'int';
my $TOKEN_FLOAT          = 'float';
my $TOKEN_BOOLEAN        = 'boolean';
my $TOKEN_NONE           = 'none';
my $TOKEN_SYMBOL         = 'symbol';
my $TOKEN_SPECIAL        = 'special';
my $TOKEN_REGEX          = 'regex';

#### module.exports.lex -- lex(src, opts) { return new Tokenizer(src, opts); }

sub lex {
  my ( $class, $src, $opts ) = @_;
  return $class->tokenizer_class->new( $src, $opts );
}

# Named once so the collaborator is reachable through the invocant (house rule).
sub tokenizer_class { 'Text::Nunjucks::Lexer::Tokenizer' }

#### module.exports.TOKEN_* -- the type strings as class methods

# Mirrors the `TOKEN_STRING: TOKEN_STRING, ...` half of module.exports: install a
# same-named method on this package for each type string, so a consumer reads
# Text::Nunjucks::Lexer->TOKEN_SYMBOL exactly as parser.js reads
# lexer.TOKEN_SYMBOL. The lexical above stays the single internal source.
{
  no strict 'refs';
  for my $entry (
    [ TOKEN_STRING         => $TOKEN_STRING ],
    [ TOKEN_WHITESPACE     => $TOKEN_WHITESPACE ],
    [ TOKEN_DATA           => $TOKEN_DATA ],
    [ TOKEN_BLOCK_START    => $TOKEN_BLOCK_START ],
    [ TOKEN_BLOCK_END      => $TOKEN_BLOCK_END ],
    [ TOKEN_VARIABLE_START => $TOKEN_VARIABLE_START ],
    [ TOKEN_VARIABLE_END   => $TOKEN_VARIABLE_END ],
    [ TOKEN_COMMENT        => $TOKEN_COMMENT ],
    [ TOKEN_LEFT_PAREN     => $TOKEN_LEFT_PAREN ],
    [ TOKEN_RIGHT_PAREN    => $TOKEN_RIGHT_PAREN ],
    [ TOKEN_LEFT_BRACKET   => $TOKEN_LEFT_BRACKET ],
    [ TOKEN_RIGHT_BRACKET  => $TOKEN_RIGHT_BRACKET ],
    [ TOKEN_LEFT_CURLY     => $TOKEN_LEFT_CURLY ],
    [ TOKEN_RIGHT_CURLY    => $TOKEN_RIGHT_CURLY ],
    [ TOKEN_OPERATOR       => $TOKEN_OPERATOR ],
    [ TOKEN_COMMA          => $TOKEN_COMMA ],
    [ TOKEN_COLON          => $TOKEN_COLON ],
    [ TOKEN_TILDE          => $TOKEN_TILDE ],
    [ TOKEN_PIPE           => $TOKEN_PIPE ],
    [ TOKEN_INT            => $TOKEN_INT ],
    [ TOKEN_FLOAT          => $TOKEN_FLOAT ],
    [ TOKEN_BOOLEAN        => $TOKEN_BOOLEAN ],
    [ TOKEN_NONE           => $TOKEN_NONE ],
    [ TOKEN_SYMBOL         => $TOKEN_SYMBOL ],
    [ TOKEN_SPECIAL        => $TOKEN_SPECIAL ],
    [ TOKEN_REGEX          => $TOKEN_REGEX ]
  ) {
    my ( $name, $value ) = @$entry;
    *{ __PACKAGE__ . '::' . $name } = sub { $value };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Lexer - 1:1 port of Nunjucks src/lexer.js -- the template tokenizer

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: this module is a stage of the template pipeline, used by
L<Text::Nunjucks::Environment>, and not an interface for applications.

A 1:1 port of Nunjucks C<src/lexer.js>. Turns a template string into a stream
of tokens.

    my $tokens = Text::Nunjucks::Lexer->lex( '{{ a }}', \%opts );
    while ( my $tok = $tokens->next_token ) {
      # $tok->type, $tok->value, $tok->lineno, $tok->colno
    }

C<lex> returns a L<Text::Nunjucks::Lexer::Tokenizer>; each C<next_token> yields
a L<Text::Nunjucks::Lexer::Token> (with C<type>, C<value>, C<lineno>, C<colno>)
until the input is exhausted, when it returns C<undef>. C<lineno> and C<colno>
are 0-based, as in the JavaScript original.

The token type strings are exposed as class methods mirroring the upstream
C<module.exports> (e.g. C<< Text::Nunjucks::Lexer->TOKEN_SYMBOL >>).

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
