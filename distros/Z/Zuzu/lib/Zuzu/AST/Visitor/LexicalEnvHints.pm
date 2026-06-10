package Zuzu::AST::Visitor::LexicalEnvHints;

use utf8;

our $VERSION = '0.003000';

use Scalar::Util qw( blessed refaddr );

use Moo;

has '_scope_stack' => ( is => 'rw', default => sub { [ {} ] } );

sub apply {
	my ( $self, $ast ) = @_;

	$self->_visit_node($ast);

	return $ast;
}

sub _current_scope { $_[0]->_scope_stack->[-1] }

sub _push_scope {
	my ( $self, $initial ) = @_;

	push @{ $self->_scope_stack }, { %{ $initial // {} } };

	return;
}

sub _pop_scope {
	my ( $self ) = @_;

	pop @{ $self->_scope_stack };

	return;
}

sub _declare_name {
	my ( $self, $name ) = @_;

	return if !defined $name or $name eq '';
	$self->_current_scope->{$name} = 1;

	return;
}

sub _lookup_depth {
	my ( $self, $name ) = @_;

	return undef if !defined $name;
	my $scopes = $self->_scope_stack;
	for ( my $i = $#$scopes; $i >= 0; $i-- ) {
		return $#$scopes - $i if exists $scopes->[$i]{$name};
	}

	return undef;
}

sub _annotate_var {
	my ( $self, $node ) = @_;

	delete $node->{_env_depth};
	delete $node->{_binding_name};
	my $depth = $self->_lookup_depth( $node->name );
	return if !defined $depth;

	$node->{_env_depth} = $depth;
	$node->{_binding_name} = $node->name;

	return;
}

sub _block_can_reuse_current_env {
	my ( $self, $node, $seen ) = @_;

	return 1 if !defined $node;
	$seen //= {};

	if ( blessed($node) ) {
		my $addr = refaddr($node);
		return 1 if defined $addr and $seen->{$addr}++;

		return 0 if $node->isa('Zuzu::AST::Stmt::Let');
		return 0 if $node->isa('Zuzu::AST::Stmt::LetUnpack');
		return 0 if $node->isa('Zuzu::AST::Stmt::Function');
		return 0 if $node->isa('Zuzu::AST::Stmt::Class');
		return 0 if $node->isa('Zuzu::AST::Stmt::Trait');
		return 0 if $node->isa('Zuzu::AST::Stmt::Import');
		return 0 if $node->isa('Zuzu::AST::Stmt::Catch');
		return 0
			if $node->isa('Zuzu::AST::Stmt::For')
			and $node->declare_loop_var;

		return 0 if $node->isa('Zuzu::AST::Expr::Call');
		return 0 if $node->isa('Zuzu::AST::Expr::MemberCall');
		return 0 if $node->isa('Zuzu::AST::Expr::DynamicMemberCall');
		return 0 if $node->isa('Zuzu::AST::Expr::New');
		return 0 if $node->isa('Zuzu::AST::Expr::Function');
		return 0 if $node->isa('Zuzu::AST::Expr::Spawn');
		return 0 if $node->isa('Zuzu::AST::Expr::Await');

		for my $value ( values %{ $node } ) {
			return 0 if !$self->_block_can_reuse_current_env( $value, $seen );
		}

		return 1;
	}

	if ( ref($node) eq 'ARRAY' ) {
		my $addr = refaddr($node);
		return 1 if defined $addr and $seen->{$addr}++;
		for my $value ( @{ $node } ) {
			return 0 if !$self->_block_can_reuse_current_env( $value, $seen );
		}
		return 1;
	}

	if ( ref($node) eq 'HASH' ) {
		my $addr = refaddr($node);
		return 1 if defined $addr and $seen->{$addr}++;
		for my $value ( values %{ $node } ) {
			return 0 if !$self->_block_can_reuse_current_env( $value, $seen );
		}
		return 1;
	}

	return 1;
}

sub _visit_block {
	my ( $self, $node ) = @_;

	return if !defined $node;
	$node->reuse_current_env( $self->_block_can_reuse_current_env($node) ? 1 : 0 );
	if ( $node->reuse_current_env ) {
		for my $stmt ( @{ $node->statements // [] } ) {
			$self->_visit_node($stmt);
		}
		return;
	}

	$self->_push_scope;
	for my $stmt ( @{ $node->statements // [] } ) {
		$self->_visit_node($stmt);
	}
	$self->_pop_scope;

	return;
}

sub _declare_function_params {
	my ( $self, $node ) = @_;

	$self->_declare_name('__argc__');
	for my $name ( @{ $node->params // [] } ) {
		$self->_declare_name($name);
	}
	$self->_declare_name( $node->vararg )
		if defined $node->vararg;
	$self->_declare_name( $node->named_vararg )
		if defined $node->named_vararg;

	return;
}

sub _visit_function_like {
	my ( $self, $node ) = @_;

	return if $node->can('is_predeclared') and $node->is_predeclared;

	my %initial;
	if ( $node->isa('Zuzu::AST::Stmt::Method') ) {
		$initial{self} = 1;
		$initial{super} = 1
			if !defined $node->uses_super or $node->uses_super;
	}

	$self->_push_scope( \%initial );
	$self->_declare_function_params($node);
	$self->_visit_block( $node->body );
	$self->_pop_scope;

	return;
}

sub _visit_node {
	my ( $self, $node ) = @_;

	return if !defined $node;
	return if !blessed($node);

	if ( $node->isa('Zuzu::AST::Program') ) {
		for my $stmt ( @{ $node->statements // [] } ) {
			$self->_visit_node($stmt);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Block') ) {
		$self->_visit_block($node);
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Var') ) {
		$self->_annotate_var($node);
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Let') ) {
		$self->_visit_node( $node->init ) if defined $node->init;
		$self->_declare_name( $node->name );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::LetUnpack') ) {
		for my $binding ( @{ $node->bindings // [] } ) {
			$self->_visit_node( $binding->{key_expr} );
			$self->_visit_node( $binding->{default_expr} )
				if $binding->{has_default};
		}
		$self->_visit_node( $node->init ) if defined $node->init;
		for my $binding ( @{ $node->bindings // [] } ) {
			$self->_declare_name( $binding->{name} );
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Assign') ) {
		$self->_visit_node( $node->target );
		$self->_visit_node( $node->expr ) if defined $node->expr;
		$self->_visit_node( $node->match_expr ) if defined $node->match_expr;
		$self->_visit_node( $node->replace_expr ) if defined $node->replace_expr;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Expr') ) {
		$self->_visit_node( $node->expr );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Return') ) {
		$self->_visit_node( $node->expr ) if $node->can('expr');
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::If') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_block( $node->then_block );
		$self->_visit_node( $node->else_branch ) if defined $node->else_branch;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::PostfixIf') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_node( $node->statement );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::While') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_block( $node->body );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::For') ) {
		$self->_visit_node( $node->collection );
		if ( $node->declare_loop_var ) {
			$self->_push_scope( { $node->var => 1 } );
			$self->_visit_block( $node->body );
			$self->_pop_scope;
		}
		else {
			$self->_visit_block( $node->body );
		}
		$self->_visit_block( $node->else_block ) if defined $node->else_block;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Function') ) {
		$self->_declare_name( $node->name );
		$self->_visit_function_like($node);
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Function') ) {
		$self->_visit_function_like($node);
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Method') ) {
		$self->_visit_function_like($node);
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Class') ) {
		$self->_visit_node( $node->parent ) if defined $node->parent;
		for my $trait_ref ( @{ $node->traits // [] } ) {
			$self->_visit_node($trait_ref);
		}
		for my $field ( @{ $node->fields // [] } ) {
			$self->_visit_node( $field->{init} ) if defined $field->{init};
		}
		$self->_declare_name( $node->name );
		$self->_push_scope( { self => 1 } );
		for my $klass ( @{ $node->classes // [] } ) {
			$self->_visit_node($klass);
		}
		for my $method ( @{ $node->methods // [] } ) {
			$self->_visit_node($method);
		}
		for my $method ( @{ $node->static_methods // [] } ) {
			$self->_visit_node($method);
		}
		$self->_pop_scope;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Trait') ) {
		$self->_declare_name( $node->name );
		for my $method ( @{ $node->methods // [] } ) {
			$self->_visit_node($method);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Try') ) {
		$self->_visit_block( $node->block );
		for my $catch ( @{ $node->catches // [] } ) {
			$self->_visit_node($catch);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Catch') ) {
		$self->_visit_node( $node->type_expr );
		$self->_push_scope( { $node->name => 1 } );
		$self->_visit_block( $node->block );
		$self->_pop_scope;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Import') ) {
		$self->_visit_node( $node->condition_expr )
			if defined $node->condition_expr;
		for my $item ( @{ $node->items // [] } ) {
			next if $item->{star};
			$self->_declare_name( $item->{alias} );
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Call') or $node->isa('Zuzu::AST::Expr::MemberCall') ) {
		$self->_visit_node( $node->callee ) if $node->can('callee');
		$self->_visit_node( $node->object ) if $node->can('object');
		for my $arg ( @{ $node->args // [] } ) {
			$self->_visit_node( $arg->[0] ) if ref($arg) eq 'ARRAY' and $arg->[2];
			$self->_visit_node( ref($arg) eq 'ARRAY' ? $arg->[1] : $arg );
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::DynamicMemberCall') ) {
		$self->_visit_node( $node->object );
		$self->_visit_node( $node->method_expr );
		for my $arg ( @{ $node->args // [] } ) {
			$self->_visit_node( $arg->[0] ) if ref($arg) eq 'ARRAY' and $arg->[2];
			$self->_visit_node( ref($arg) eq 'ARRAY' ? $arg->[1] : $arg );
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Spread') ) {
		$self->_visit_node( $node->expr );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Binary') ) {
		$self->_visit_node( $node->left );
		$self->_visit_node( $node->right );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Unary') ) {
		$self->_visit_node( $node->expr );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Await') or $node->isa('Zuzu::AST::Expr::Spawn') ) {
		$self->_visit_block( $node->block );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Ternary') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_node( $node->if_true ) if defined $node->if_true;
		$self->_visit_node( $node->if_false );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Index') ) {
		$self->_visit_node( $node->array );
		$self->_visit_node( $node->index );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::DictGet') ) {
		$self->_visit_node( $node->dict );
		$self->_visit_node( $node->key );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Slice') ) {
		$self->_visit_node( $node->collection );
		$self->_visit_node( $node->start ) if defined $node->start;
		$self->_visit_node( $node->length ) if defined $node->length;
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::IncDec') ) {
		$self->_visit_node( $node->target );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Array') or $node->isa('Zuzu::AST::Expr::Set') or $node->isa('Zuzu::AST::Expr::Bag') ) {
		for my $item ( @{ $node->items // [] } ) {
			$self->_visit_node($item);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Range') ) {
		$self->_visit_node( $node->start );
		$self->_visit_node( $node->end );
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Dict') ) {
		for my $pair ( @{ $node->pairs // [] } ) {
			next if ref($pair) ne 'ARRAY';
			$self->_visit_node( $pair->[0] );
			$self->_visit_node( $pair->[1] );
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::New') ) {
		$self->_visit_node( $node->class_expr );
		for my $trait_ref ( @{ $node->traits // [] } ) {
			$self->_visit_node( $trait_ref );
		}
		for my $pair ( @{ $node->args // [] } ) {
			$self->_visit_node( $pair->[1] );
		}
		return;
	}

	return;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Visitor::LexicalEnvHints >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
