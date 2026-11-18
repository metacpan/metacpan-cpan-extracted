package Text::Nunjucks::Transformer;
# ABSTRACT: 1:1 port of Nunjucks src/transformer.js -- the async CPS rewrite

our $VERSION = '0.001';

use strict;
use warnings;
use Scalar::Util qw( blessed refaddr );
use Text::Nunjucks::Nodes;
use Text::Nunjucks::Lib;

# 1:1 port of upstream src/transformer.js. transformer.js is a plain bag of
# module-level functions with `module.exports = { transform }`; it is ported as
# a class-method-only module (getty-perl-core "dispatch through the invocant"),
# the same shape as Lib.pm: every upstream function becomes a method taking
# $self, in upstream order and snake_case, callers use
# Text::Nunjucks::Transformer->transform($ast, \@async_filters), and every
# cross-call goes through $self so a subclass can redirect. No instances.
#
# nodes/lib are reached through their real interfaces (new nodes.X ->
# $self->node('X')->new, lib.indexOf -> $self->lib->index_of), never re-derived.
#
# The transformer rewrites the parse tree so the compiler can emit callback
# (CPS) code (ADR 0003): async filters are lifted out into FilterAsync temps,
# {{ super() }} into an explicit Super node, and any If/For that turns out to
# contain async work is retyped to IfAsync / AsyncEach.
#
# `var sym = 0` is genuine module-level state upstream -- a process-global
# counter behind gensym() that never resets, so the Nth hole minted in a process
# carries the Nth number regardless of which template it came from. The 1:1
# mapping is a file-lexical $sym; upstream wins on behaviour here (the exact hole
# number is not a stable observable -- it is only ever an internal variable name
# the compiler both binds and reads back, so its value never reaches output).

# Collaborators named once, reached through the invocant (house rule).
sub node { my ( $self, $name ) = @_; return 'Text::Nunjucks::Nodes::' . $name }
sub lib  { 'Text::Nunjucks::Lib' }

#### gensym / var sym

my $sym = 0;

sub gensym {
  my ($self) = @_;
  return 'hole_' . $sym++;
}

#### mapCOW -- copy-on-write version of map

sub map_cow {
  my ( $self, $arr, $func ) = @_;
  my $res;
  for my $i ( 0 .. $#$arr ) {
    my $item = $func->( $arr->[$i] );

    if ( !$self->_same( $item, $arr->[$i] ) ) {
      $res = [ @$arr ] unless $res;    # arr.slice()
      $res->[$i] = $item;
    }
  }

  return $res || $arr;
}

# JS `a === b` for the copy-on-write identity checks in walk / mapCOW. walk()
# returns its argument unchanged (same value or ref) or a freshly built node, so
# a change is always observable as a change of reference; a non-node value only
# ever passes through unchanged and so is treated as "same".
sub _same {
  my ( $self, $a, $b ) = @_;
  return 1 unless ref($a) || ref($b);
  return ( ref($a) && ref($b) && refaddr($a) == refaddr($b) ) ? 1 : 0;
}

#### walk

sub walk {
  my ( $self, $ast, $func, $depth_first ) = @_;

  if ( !( blessed($ast) && $ast->isa( $self->node('Node') ) ) ) {
    return $ast;
  }

  if ( !$depth_first ) {
    my $ast_t = $func->($ast);

    if ( $ast_t && !$self->_same( $ast_t, $ast ) ) {
      return $ast_t;
    }
  }

  if ( $ast->isa( $self->node('NodeList') ) ) {
    my $children = $self->map_cow( $ast->children, sub { $self->walk( $_[0], $func, $depth_first ) } );

    if ( !$self->_same( $children, $ast->children ) ) {
      $ast = $self->node( $ast->typename )->new( $ast->lineno, $ast->colno, $children );
    }
  }
  elsif ( $ast->isa( $self->node('CallExtension') ) ) {
    my $args = $self->walk( $ast->args, $func, $depth_first );
    my $content_args = $self->map_cow( $ast->contentArgs, sub { $self->walk( $_[0], $func, $depth_first ) } );

    if ( !$self->_same( $args, $ast->args ) || !$self->_same( $content_args, $ast->contentArgs ) ) {
      $ast = $self->node( $ast->typename )->new( $ast->extName, $ast->prop, $args, $content_args );
    }
  }
  else {
    my $props = [ map { $ast->$_ } @{ $ast->fields } ];
    my $props_t = $self->map_cow( $props, sub { $self->walk( $_[0], $func, $depth_first ) } );

    if ( !$self->_same( $props_t, $props ) ) {
      my $fields = $ast->fields;
      $ast = $self->node( $ast->typename )->new( $ast->lineno, $ast->colno );
      for my $i ( 0 .. $#$props_t ) {
        my $field = $fields->[$i];
        $ast->$field( $props_t->[$i] );
      }
    }
  }

  return $depth_first ? ( $func->($ast) || $ast ) : $ast;
}

#### depthWalk

sub depth_walk {
  my ( $self, $ast, $func ) = @_;
  return $self->walk( $ast, $func, 1 );
}

#### _liftFilters

sub _lift_filters {
  my ( $self, $node, $async_filters, $prop ) = @_;
  my @children;

  my $walked = $self->depth_walk( ( $prop ? $node->$prop : $node ), sub {
    my ($desc_node) = @_;
    my $symbol;
    if ( $desc_node->isa( $self->node('Block') ) ) {
      return $desc_node;
    }
    elsif ( ( $desc_node->isa( $self->node('Filter') )
        && $self->lib->index_of( $async_filters, $desc_node->name->value ) != -1 )
      || $desc_node->isa( $self->node('CallExtensionAsync') ) ) {
      $symbol = $self->node('Symbol')->new( $desc_node->lineno,
        $desc_node->colno,
        $self->gensym );

      push @children, $self->node('FilterAsync')->new( $desc_node->lineno,
        $desc_node->colno,
        # JS reads descNode.name; a CallExtensionAsync has no `name` field, so
        # upstream gets undefined there (FilterAsync.name = null). The same
        # can() guard lift_super uses for a non-Symbol node.name.value.
        ( $desc_node->can('name') ? $desc_node->name : undef ),
        $desc_node->args,
        $symbol );
    }
    return $symbol;
  } );

  if ($prop) {
    $node->$prop($walked);
  }
  else {
    $node = $walked;
  }

  if (@children) {
    push @children, $node;

    return $self->node('NodeList')->new(
      $node->lineno,
      $node->colno,
      \@children
    );
  }
  else {
    return $node;
  }
}

#### liftFilters

sub lift_filters {
  my ( $self, $ast, $async_filters ) = @_;
  return $self->depth_walk( $ast, sub {
    my ($node) = @_;
    if ( $node->isa( $self->node('Output') ) ) {
      return $self->_lift_filters( $node, $async_filters );
    }
    elsif ( $node->isa( $self->node('Set') ) ) {
      return $self->_lift_filters( $node, $async_filters, 'value' );
    }
    elsif ( $node->isa( $self->node('For') ) ) {
      return $self->_lift_filters( $node, $async_filters, 'arr' );
    }
    elsif ( $node->isa( $self->node('If') ) ) {
      return $self->_lift_filters( $node, $async_filters, 'cond' );
    }
    elsif ( $node->isa( $self->node('CallExtension') ) ) {
      return $self->_lift_filters( $node, $async_filters, 'args' );
    }
    else {
      return undef;
    }
  } );
}

#### liftSuper

sub lift_super {
  my ( $self, $ast ) = @_;
  return $self->walk( $ast, sub {
    my ($block_node) = @_;
    if ( !( $block_node->isa( $self->node('Block') ) ) ) {
      return;
    }

    my $has_super = 0;
    my $symbol    = $self->gensym;

    $block_node->body( $self->walk( $block_node->body, sub {    # eslint-disable-line consistent-return
      my ($node) = @_;
      # JS reads node.name.value; a non-Symbol name (e.g. LookupVal) has no
      # `value` field and yields undefined there rather than throwing, so the
      # `=== 'super'` fails. can('value') reproduces that guarded read.
      if ( $node->isa( $self->node('FunCall') )
        && $node->name->can('value')
        && defined( $node->name->value )
        && $node->name->value eq 'super' ) {
        $has_super = 1;
        return $self->node('Symbol')->new( $node->lineno, $node->colno, $symbol );
      }
      return;
    } ) );

    if ($has_super) {
      unshift @{ $block_node->body->children }, $self->node('Super')->new(
        0, 0, $block_node->name, $self->node('Symbol')->new( 0, 0, $symbol )
      );
    }
    return;
  } );
}

#### convertStatements

sub convert_statements {
  my ( $self, $ast ) = @_;
  return $self->depth_walk( $ast, sub {
    my ($node) = @_;
    if ( !( $node->isa( $self->node('If') ) ) && !( $node->isa( $self->node('For') ) ) ) {
      return undef;
    }

    my $async = 0;
    $self->walk( $node, sub {
      my ($child) = @_;
      if ( $child->isa( $self->node('FilterAsync') )
        || $child->isa( $self->node('IfAsync') )
        || $child->isa( $self->node('AsyncEach') )
        || $child->isa( $self->node('AsyncAll') )
        || $child->isa( $self->node('CallExtensionAsync') ) ) {
        $async = 1;
        # Stop iterating by returning the node
        return $child;
      }
      return undef;
    } );

    if ($async) {
      if ( $node->isa( $self->node('If') ) ) {
        return $self->node('IfAsync')->new(
          $node->lineno,
          $node->colno,
          $node->cond,
          $node->body,
          $node->else_
        );
      }
      elsif ( $node->isa( $self->node('For') ) && !( $node->isa( $self->node('AsyncAll') ) ) ) {
        return $self->node('AsyncEach')->new(
          $node->lineno,
          $node->colno,
          $node->arr,
          $node->name,
          $node->body,
          $node->else_
        );
      }
    }
    return undef;
  } );
}

#### cps

sub cps {
  my ( $self, $ast, $async_filters ) = @_;
  return $self->convert_statements( $self->lift_super( $self->lift_filters( $ast, $async_filters ) ) );
}

#### module.exports.transform -- transform(ast, asyncFilters)

sub transform {
  my ( $self, $ast, $async_filters ) = @_;
  return $self->cps( $ast, $async_filters || [] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Nunjucks::Transformer - 1:1 port of Nunjucks src/transformer.js -- the async CPS rewrite

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Engine-internal: this module is a stage of the template pipeline, used by
L<Text::Nunjucks::Environment>, and not an interface for applications.

A 1:1 port of Nunjucks C<src/transformer.js>. Called as a class method:

    my $ast2 = Text::Nunjucks::Transformer->transform( $ast, \@async_filters );

Given a parse tree and the list of filter names the environment has registered
as asynchronous, it rewrites the tree into the form the compiler expects for
callback (CPS) emission (ADR 0003): async filters and C<CallExtensionAsync>
nodes are lifted out into C<FilterAsync> temporaries, C<{{ super() }}> calls
become explicit C<Super> nodes, and any C<If>/C<For> that transitively contains
async work is retyped to C<IfAsync> / C<AsyncEach>.

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
