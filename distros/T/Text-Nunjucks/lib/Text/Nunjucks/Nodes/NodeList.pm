package Text::Nunjucks::Nodes::NodeList;
# ABSTRACT: AST node holding a list of child nodes (nodes.js class NodeList)

our $VERSION = '0.001';

use Moo;
use namespace::autoclean;

extends 'Text::Nunjucks::Nodes::Node';

# upstream: class NodeList extends Node

has children => ( is => 'rw' );

sub typename { 'NodeList' }
sub fields   { ['children'] }

# init(lineno, colno, nodes) -> super.init(lineno, colno, nodes || [])
sub BUILDARGS {
  my ( $class, $lineno, $colno, $nodes ) = @_;
  return $class->_field_args( $lineno, $colno, $nodes || [] );
}

sub add_child {
  my ( $self, $node ) = @_;
  push @{ $self->children }, $node;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::NodeList - AST node holding a list of child nodes (nodes.js class NodeList)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the node of the template AST in L<Text::Nunjucks::Nodes> that
holds an ordered list of child nodes in C<children>, and the parent of C<Root>,
C<Group>, C<Array>, C<Dict>, C<Output> and C<KeywordArgs>.

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
