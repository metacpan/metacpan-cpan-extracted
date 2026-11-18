package Text::Nunjucks::Nodes::Node;
# ABSTRACT: Base class of every AST node (nodes.js class Node)

our $VERSION = '0.001';

use Moo;
use Scalar::Util qw( blessed );
use namespace::autoclean;

# upstream: class Node extends Obj. Every node answers ->typename (the oracle
# AST type string), ->fields (arrayref of field names in nodes.js order),
# ->lineno, ->colno and one accessor per field. That is exactly the shape
# t/corpus.t's ast_dump reads. A subclass sets its own typename (upstream sets
# it fresh on every extend, it is never inherited) and overrides fields only
# where the list changes; inherited fields keep their accessors through normal
# inheritance, the way JS prototype chaining carries them.

has lineno => ( is => 'ro' );
has colno  => ( is => 'ro' );

sub typename { 'Node' }
sub fields   { [] }

# Node construction is positional -- new nodes.Symbol(lineno, colno, value) --
# so BUILDARGS turns the positional call into the hash Moo's constructor
# wants. The first two args are line/col; the rest map onto the fields in
# declared order. A field that was not passed stays undef, which encodes to
# JSON null: upstream's init does the same ("Fields should never be
# undefined, but null. It makes testing easier to normalize values.").
sub BUILDARGS {
  my ( $class, @args ) = @_;
  return $class->_field_args(@args);
}

sub _field_args {
  my ( $class, $lineno, $colno, @vals ) = @_;
  my $fields = $class->fields;
  my %args = ( lineno => $lineno, colno => $colno );
  for my $i ( 0 .. $#$fields ) {
    $args{ $fields->[$i] } = $vals[$i];
  }
  return \%args;
}

# Named once so a subclass can redirect sibling-node construction (house
# rule: reach for collaborators through the invocant, not a hardcoded name).
sub _node_class {
  my ( $self, $name ) = @_;
  return 'Text::Nunjucks::Nodes::' . $name;
}

sub find_all {
  my ( $self, $type, $results ) = @_;
  $results ||= [];

  if ( $self->isa( $self->_node_class('NodeList') ) ) {
    _traverse_and_check( $_, $type, $results ) for @{ $self->children };
  }
  else {
    _traverse_and_check( $self->$_, $type, $results ) for @{ $self->fields };
  }

  return $results;
}

sub iter_fields {
  my ( $self, $func ) = @_;
  $func->( $self->$_, $_ ) for @{ $self->fields };
}

# upstream module-level function traverseAndCheck; kept next to find_all, its
# only caller, since the two are mutually recursive.
sub _traverse_and_check {
  my ( $obj, $type, $results ) = @_;
  push @$results, $obj if blessed($obj) && $obj->isa($type);
  $obj->find_all( $type, $results )
    if blessed($obj) && $obj->isa('Text::Nunjucks::Nodes::Node');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes::Node - Base class of every AST node (nodes.js class Node)

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: the base class of the template AST in L<Text::Nunjucks::Nodes>.
A node is constructed positionally, line and column first, then its fields in
declared order:

    Text::Nunjucks::Nodes::Symbol->new( $lineno, $colno, $value );

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
