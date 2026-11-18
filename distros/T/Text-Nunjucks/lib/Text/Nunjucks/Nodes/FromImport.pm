package Text::Nunjucks::Nodes::FromImport;
# ABSTRACT: AST node FromImport (fields template, names, withContext), ported from nodes.js

our $VERSION = '0.001';

use Moo;
use Text::Nunjucks::Nodes::NodeList;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Node';

# upstream: class FromImport extends Node -- custom init, declared in nodes.js
# between Import and FunCall.

has template    => ( is => 'rw' );
has names       => ( is => 'rw' );
has withContext => ( is => 'rw' );

sub typename { 'FromImport' }
sub fields   { [ 'template', 'names', 'withContext' ] }

# init(lineno, colno, template, names, withContext)
#  -> super.init(lineno, colno, template, names || new NodeList(), withContext)
sub BUILDARGS {
  my ( $class, $lineno, $colno, $template, $names, $withContext ) = @_;
  return $class->_field_args(
    $lineno, $colno,
    $template,
    ( $names || $class->_node_class('NodeList')->new ),
    $withContext
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::FromImport - AST node FromImport (fields template, names, withContext), ported from nodes.js

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the C<FromImport> node of the template AST that
L<Text::Nunjucks::Parser> builds and L<Text::Nunjucks::Compiler> reads; see
L<Text::Nunjucks::Nodes>.

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
