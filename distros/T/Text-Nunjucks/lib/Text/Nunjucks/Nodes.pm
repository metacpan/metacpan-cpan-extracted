package Text::Nunjucks::Nodes;
# ABSTRACT: AST node types for Text::Nunjucks, ported 1:1 from nodes.js

our $VERSION = '0.001';

use strict;
use warnings;
use Scalar::Util qw( blessed );
use JSON::MaybeXS ();

# 1:1 port of upstream src/nodes.js. object.js has no Perl counterpart
# (ADR 0002): Moo is the object system. Every node class nodes.js declares --
# the base classes it writes with `class` (Node, Value, NodeList), the two with
# a custom init (FromImport, CallExtension) and every `X.extend('Name',
# {fields})` line -- is a hand-written Moo class in its own file under
# Text/Nunjucks/Nodes/ (ADR 0020), carrying the nodes.js line it ports. This
# module keeps nodes.js's module-level functions (print, printNodes) and loads
# every node class, in nodes.js declaration order, so `use Text::Nunjucks::Nodes`
# makes all of them available.
#
# nodes.js requires only Obj from object.js, not EmitterObj, so no on/emit role
# is needed here.

use Text::Nunjucks::Nodes::Node;
use Text::Nunjucks::Nodes::Value;
use Text::Nunjucks::Nodes::NodeList;
use Text::Nunjucks::Nodes::Root;
use Text::Nunjucks::Nodes::Literal;
use Text::Nunjucks::Nodes::Symbol;
use Text::Nunjucks::Nodes::Group;
use Text::Nunjucks::Nodes::Array;
use Text::Nunjucks::Nodes::Pair;
use Text::Nunjucks::Nodes::Dict;
use Text::Nunjucks::Nodes::LookupVal;
use Text::Nunjucks::Nodes::If;
use Text::Nunjucks::Nodes::IfAsync;
use Text::Nunjucks::Nodes::InlineIf;
use Text::Nunjucks::Nodes::For;
use Text::Nunjucks::Nodes::AsyncEach;
use Text::Nunjucks::Nodes::AsyncAll;
use Text::Nunjucks::Nodes::Macro;
use Text::Nunjucks::Nodes::Caller;
use Text::Nunjucks::Nodes::Import;
use Text::Nunjucks::Nodes::FromImport;
use Text::Nunjucks::Nodes::FunCall;
use Text::Nunjucks::Nodes::Filter;
use Text::Nunjucks::Nodes::FilterAsync;
use Text::Nunjucks::Nodes::KeywordArgs;
use Text::Nunjucks::Nodes::Block;
use Text::Nunjucks::Nodes::Super;
use Text::Nunjucks::Nodes::TemplateRef;
use Text::Nunjucks::Nodes::Extends;
use Text::Nunjucks::Nodes::Include;
use Text::Nunjucks::Nodes::Set;
use Text::Nunjucks::Nodes::Switch;
use Text::Nunjucks::Nodes::Case;
use Text::Nunjucks::Nodes::Output;
use Text::Nunjucks::Nodes::Capture;
use Text::Nunjucks::Nodes::TemplateData;
use Text::Nunjucks::Nodes::UnaryOp;
use Text::Nunjucks::Nodes::BinOp;
use Text::Nunjucks::Nodes::In;
use Text::Nunjucks::Nodes::Is;
use Text::Nunjucks::Nodes::Or;
use Text::Nunjucks::Nodes::And;
use Text::Nunjucks::Nodes::Not;
use Text::Nunjucks::Nodes::Add;
use Text::Nunjucks::Nodes::Concat;
use Text::Nunjucks::Nodes::Sub;
use Text::Nunjucks::Nodes::Mul;
use Text::Nunjucks::Nodes::Div;
use Text::Nunjucks::Nodes::FloorDiv;
use Text::Nunjucks::Nodes::Mod;
use Text::Nunjucks::Nodes::Pow;
use Text::Nunjucks::Nodes::Neg;
use Text::Nunjucks::Nodes::Pos;
use Text::Nunjucks::Nodes::Compare;
use Text::Nunjucks::Nodes::CompareOperand;
use Text::Nunjucks::Nodes::CallExtension;
use Text::Nunjucks::Nodes::CallExtensionAsync;

#### printNodes -- AST pretty-printer (upstream: print / printNodes)

my $JSON = JSON::MaybeXS->new( canonical => 1, convert_blessed => 1 )->pretty(1);

# upstream `print`. "This is hacky, but this is just a debugging function
# anyway." A non-empty line ("0" counts, unlike Perl truthiness) is prefixed
# with `indent` spaces; the last line gets no trailing newline. NOTE: debug
# helper only, not byte-asserted anywhere -- the property JSON's whitespace and
# key order differ from JS's JSON.stringify (Perl hashes are unordered).
sub _print {
  my ( $str, $indent, $inline ) = @_;
  $indent = 0 unless defined $indent;
  my @lines = split /\n/, $str, -1;
  for my $i ( 0 .. $#lines ) {
    my $line = $lines[$i];
    print STDOUT ( ' ' x $indent )
      if length($line) && ( ( $inline && $i > 0 ) || !$inline );
    print STDOUT $line . ( $i == $#lines ? '' : "\n" );
  }
}

# Print the AST in a nicely formatted tree format for debuggin
sub print_nodes {
  my ( $node, $indent ) = @_;
  $indent = $indent || 0;

  _print( $node->typename . ': ', $indent );

  if ( $node->isa('Text::Nunjucks::Nodes::NodeList') ) {
    _print("\n");
    print_nodes( $_, $indent + 2 ) for @{ $node->children };
  }
  elsif ( $node->isa('Text::Nunjucks::Nodes::CallExtension') ) {
    _print( $node->extName . '.' . $node->prop . "\n" );

    print_nodes( $node->args, $indent + 2 ) if $node->args;

    if ( $node->contentArgs ) {
      print_nodes( $_, $indent + 2 ) for @{ $node->contentArgs };
    }
  }
  else {
    my @nodes;
    my $props;

    $node->iter_fields( sub {
      my ( $val, $field_name ) = @_;
      if ( blessed($val) && $val->isa('Text::Nunjucks::Nodes::Node') ) {
        push @nodes, [ $field_name, $val ];
      }
      else {
        $props ||= {};
        $props->{$field_name} = $val;
      }
    } );

    if ($props) {
      _print( $JSON->encode($props) . "\n", undef, 1 );
    }
    else {
      _print("\n");
    }

    for my $pair (@nodes) {
      my ( $field_name, $n ) = @$pair;
      _print( '[' . $field_name . '] =>', $indent + 2 );
      print_nodes( $n, $indent + 4 );
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Nodes - AST node types for Text::Nunjucks, ported 1:1 from nodes.js

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: this module is a stage of the template pipeline, used by
L<Text::Nunjucks::Environment>, and not an interface for applications.

A 1:1 port of Nunjucks C<src/nodes.js>. Loads every node class: the base
classes (C<Node>, C<Value>, C<NodeList>), the two nodes with a custom
constructor (C<FromImport>, C<CallExtension>) and the concrete node types
upstream declares with C<Node.extend(name, { fields })>, each in its own file
(L<Text::Nunjucks::Nodes::Node>, L<Text::Nunjucks::Nodes::If>, ...).

Every node lives in the C<Text::Nunjucks::Nodes::> namespace (e.g.
C<Text::Nunjucks::Nodes::Symbol>) and is constructed positionally:

    Text::Nunjucks::Nodes::Symbol->new( $lineno, $colno, $value );

Each node answers C<typename>, C<fields> (an arrayref of field names in
declared order), C<lineno>, C<colno>, and one accessor per field.

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
