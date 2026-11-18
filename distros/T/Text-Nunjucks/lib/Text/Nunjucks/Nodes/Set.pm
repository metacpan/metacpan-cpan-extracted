package Text::Nunjucks::Nodes::Set;
# ABSTRACT: AST node Set (fields targets, value), ported from nodes.js

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Node';

# nodes.js: const Set = Node.extend('Set', { fields: ['targets', 'value'] });

has targets => ( is => 'rw' );
has value   => ( is => 'rw' );

# Set carries a non-field `body`. Upstream declares Set with fields
# {targets, value}, and the parser attaches a block-set's Capture to node.body
# dynamically (parser.js parseSet), which the compiler reads back
# (compiler.js compileSet). It is not a field(), so it never appears in the AST
# dump -- exactly the CallExtension.autoescape pattern: a real accessor that
# lives outside the field list.
has body => ( is => 'rw' );

sub typename { 'Set' }
sub fields   { [ 'targets', 'value' ] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::Set - AST node Set (fields targets, value), ported from nodes.js

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the C<Set> node of the template AST that
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
