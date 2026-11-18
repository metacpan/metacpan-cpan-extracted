package Text::Nunjucks::Parser;
# ABSTRACT: 1:1 port of Nunjucks src/parser.js -- the recursive-descent parser

our $VERSION = '0.001';

use strict;
use warnings;
use Text::Nunjucks::Lexer;
use Text::Nunjucks::Parser::Parser;

# 1:1 port of upstream src/parser.js. parser.js holds one `class Parser extends
# Obj` and a `module.exports = { parse, Parser }`. This file mirrors that shape
# the way Lexer.pm mirrors lexer.js: the module-level exports live here on
# Text::Nunjucks::Parser (parse(), and parser_class() for the exported Parser
# class that jinja-compat reaches through `this.parser.Parser`), while the
# Parser class itself is the Moo class Text::Nunjucks::Parser::Parser in its own
# file (ADR 0002, ADR 0020) -- just as lexer's Tokenizer is
# Text::Nunjucks::Lexer::Tokenizer. Keeping them in separate packages resolves
# the one name clash parser.js has in a single Perl namespace: the instance
# method Parser.prototype.parse() and the module function
# module.exports.parse() are both named `parse`.
#
# lexer/nodes/lib are used through their real interfaces (lexer.TOKEN_X ->
# Text::Nunjucks::Lexer->TOKEN_X, new nodes.X -> $self->node('X')->new,
# lib.indexOf -> Text::Nunjucks::Lib->index_of), never re-derived. `throw new
# Error` becomes a thrown Text::Nunjucks::Lib::Error and `new lib.TemplateError`
# a Text::Nunjucks::Lib::TemplateError, the same mappings the lexer uses.

#### module.exports.parse -- parse(src, extensions, opts)

sub parse {
  my ( $self, $src, $extensions, $opts ) = @_;
  my $p = $self->parser_class->new( $self->lexer->lex( $src, $opts ) );
  # JS: if (extensions !== undefined) p.extensions = extensions;
  $p->extensions($extensions) if defined $extensions;
  return $p->parse_as_root;
}

# Collaborators named once, reached through the invocant (house rule).
sub lexer        { 'Text::Nunjucks::Lexer' }
sub parser_class { 'Text::Nunjucks::Parser::Parser' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Parser - 1:1 port of Nunjucks src/parser.js -- the recursive-descent parser

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: this module is a stage of the template pipeline, used by
L<Text::Nunjucks::Environment>, and not an interface for applications.

A 1:1 port of Nunjucks C<src/parser.js>. Turns a template string into an AST of
L<Text::Nunjucks::Nodes> nodes.

    my $ast = Text::Nunjucks::Parser->parse( '{{ a }}', \@extensions, \%opts );

C<parse> mirrors upstream's C<module.exports.parse>: it lexes the source with
L<Text::Nunjucks::Lexer>, applies any extensions, and returns the C<Root> node
from C<parse_as_root>. The parser class itself is the Moo class
L<Text::Nunjucks::Parser::Parser> (reachable as C<< Text::Nunjucks::Parser->parser_class >>,
mirroring upstream's exported C<Parser>).

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
