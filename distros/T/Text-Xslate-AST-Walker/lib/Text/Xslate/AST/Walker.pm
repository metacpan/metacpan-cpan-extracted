package Text::Xslate::AST::Walker;

our $VERSION = '0.01';

use strict;
use warnings;
use Class::Accessor::Lite (
  new => 1,
  ro => [qw(nodes)],
);

sub search_descendants {
  my ($self, $predicate) = @_;
  return [ map { @{$self->_recursive_search($_, $predicate)} } @{$self->nodes} ];
}

sub _recursive_search {
  my ($self, $node, $predicate) = @_;
  my @matched;
  push @matched, $node if $predicate->($node);
  my @matched_descendants = map { @{$self->_recursive_search($_, $predicate)} } @{$node->child_symbols};
  push @matched, @matched_descendants;
  return \@matched;
}

package
  Text::Xslate::Symbol;

use strict;
use warnings;

sub child_symbols {
  my ($self) = @_;
  return [
    grep { $_->isa(ref($self)) }
    @{$self->child_nodes}
  ];
}

sub child_nodes {
  my ($self) = @_;
  return [
    grep { defined($_) }
    map { @{_ensure_array_ref($self->$_)} }
    qw(first second third)
  ];
}

sub _ensure_array_ref {
  my ($maybe_arrayref) = @_;
  return ref($maybe_arrayref) eq 'ARRAY' ? $maybe_arrayref : [$maybe_arrayref];
}

1;
__END__

= encoding utf-8

=head1 NAME

Text::Xslate::AST::Walker - Filter Nodes in the AST made by Text::Xslate

=head1 SYNOPSIS

  use Text::Xslate::Parser;
  use Text::Xslate::AST::Walker;

  my $template = EOF;
  : my $first_name = 'Hanae';
  Hello, <: $last_name :>, <: $first_name :>.
  EOF
  my $parser = Text::Xslate::Parser->new;
  my $nodes = $parser->parse($template);
  my $tw = Text::Xslate::AST::Walker->new(nodes => $nodes);
  my $undeclared_vars = $tw->search_descendants(sub {
    my ($node) = @_;
    ($node->arity eq 'variable') && !$node->is_defined && !$node->is_reserved;
  });

=head1 DESCRIPTION

Filter nodes in the AST which made by Text::Xslate.

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=cut
