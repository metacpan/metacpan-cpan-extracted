package Zuzu::AST::Visitor::TypeCheckHints;

use utf8;

our $VERSION = '0.005000';

use Scalar::Util qw( blessed );

use Moo;

has '_scope_stack' => ( is => 'rw', default => sub { [ {} ] } );
has '_return_type_stack' => ( is => 'rw', default => sub { [] } );

sub apply {
	my ( $self, $ast ) = @_;

	$self->_visit_node($ast);

	return $ast;
}

sub _current_scope {
	my ( $self ) = @_;

	return $self->_scope_stack->[-1];
}

sub _push_scope {
	my ( $self ) = @_;

	push @{ $self->_scope_stack }, {};

	return;
}

sub _pop_scope {
	my ( $self ) = @_;

	pop @{ $self->_scope_stack };

	return;
}

sub _declare_typed_name {
	my ( $self, $name, $declared_type ) = @_;

	return if !defined $name;
	$declared_type //= 'Any';

	$self->_current_scope->{ $name } = $declared_type;

	return;
}

sub _lookup_declared_type {
	my ( $self, $name ) = @_;

	return 'Any' if !defined $name;

	for ( my $i = $#{ $self->_scope_stack }; $i >= 0; $i-- ) {
		my $scope = $self->_scope_stack->[$i];
		return $scope->{ $name } if exists $scope->{ $name };
	}

	return 'Any';
}

sub _visit_block_with_scope {
	my ( $self, $block ) = @_;

	return if !defined $block;

	$self->_push_scope;
	$self->_visit_node($block);
	$self->_pop_scope;

	return;
}

sub _visit_function_like {
	my ( $self, $node ) = @_;

	$self->_push_scope;

	for my $name ( @{ $node->params // [] } ) {
		my $declared_type = $node->param_types->{$name} // 'Any';
		$self->_declare_typed_name( $name, $declared_type );
	}
	if ( defined $node->vararg ) {
		my $declared_type = $node->vararg_type // 'Any';
		$self->_declare_typed_name( $node->vararg, $declared_type );
	}

	for my $name ( sort keys %{ $node->param_defaults // {} } ) {
		my $default_expr = $node->param_defaults->{$name};
		$self->_visit_node($default_expr);
		my $declared_type = $node->param_types->{$name} // 'Any';
		if ( $self->_expr_matches_type( $default_expr, $declared_type ) ) {
			$node->{_default_typecheck_safe}{$name} = 1;
		}
	}

	if ( $node->can('is_predeclared') and $node->is_predeclared ) {
		$self->_pop_scope;
		return;
	}

	push @{ $self->_return_type_stack }, ( $node->return_type // 'Any' );
	$self->_visit_node( $node->body );
	pop @{ $self->_return_type_stack };
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
		for my $stmt ( @{ $node->statements // [] } ) {
			$self->_visit_node($stmt);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Let') ) {
		$self->_visit_node( $node->init ) if defined $node->init;
		my $declared_type = $node->declared_type // 'Any';
		if ( defined $node->init and $declared_type ne 'Any' ) {
			if ( $self->_expr_matches_type( $node->init, $declared_type ) ) {
				$node->{_skip_type_check} = 1;
			}
		}
		$self->_declare_typed_name( $node->name, $declared_type );
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
			$self->_declare_typed_name(
				$binding->{name},
				$binding->{declared_type} // 'Any',
			);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Assign') ) {
		$self->_visit_node( $node->target );
		$self->_visit_node( $node->expr );
		if ( $node->op eq ':=' and blessed( $node->target ) and $node->target->isa('Zuzu::AST::Expr::Var') ) {
			my $name = $node->target->name;
			my $declared_type = $self->_lookup_declared_type($name);
			if ( $declared_type ne 'Any' and $self->_expr_matches_type( $node->expr, $declared_type ) ) {
				$node->{_skip_type_check} = 1;
			}
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Expr') ) {
		$self->_visit_node( $node->expr );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Return') ) {
		$self->_visit_node( $node->expr ) if $node->can('expr');
		if ( @{ $self->_return_type_stack } and defined $node->expr ) {
			my $declared_return_type = $self->_return_type_stack->[-1] // 'Any';
			if ( $declared_return_type ne 'Any' and $self->_expr_matches_type( $node->expr, $declared_return_type ) ) {
				$node->{_skip_type_check} = 1;
			}
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::If') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_block_with_scope( $node->then_block );
		$self->_visit_block_with_scope( $node->else_branch ) if defined $node->else_branch;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::PostfixIf') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_node( $node->statement );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::While') ) {
		$self->_visit_node( $node->cond );
		$self->_visit_block_with_scope( $node->body );
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::For') ) {
		$self->_visit_node( $node->collection );
		$self->_push_scope;
		if ( $node->declare_loop_var ) {
			$self->_declare_typed_name( $node->var, 'Any' );
		}
		$self->_visit_node( $node->body );
		$self->_pop_scope;
		$self->_visit_block_with_scope( $node->else_block ) if defined $node->else_block;
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Function') or $node->isa('Zuzu::AST::Expr::Function') or $node->isa('Zuzu::AST::Stmt::Method') ) {
		$self->_visit_function_like($node);
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Class') ) {
		$self->_visit_node( $node->parent ) if defined $node->parent;
		for my $trait_ref ( @{ $node->traits // [] } ) {
			$self->_visit_node($trait_ref);
		}
		for my $field ( @{ $node->fields // [] } ) {
			next if !defined $field->{init};
			$self->_visit_node( $field->{init} );
		}
		for my $method ( @{ $node->methods // [] } ) {
			$self->_visit_node($method);
		}
		for my $method ( @{ $node->static_methods // [] } ) {
			$self->_visit_node($method);
		}
		for my $klass ( @{ $node->classes // [] } ) {
			$self->_visit_node($klass);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Trait') ) {
		for my $method ( @{ $node->methods // [] } ) {
			$self->_visit_node($method);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Try') ) {
		$self->_visit_block_with_scope( $node->block );
		for my $catch ( @{ $node->catches // [] } ) {
			$self->_visit_node($catch);
		}
		return;
	}

	if ( $node->isa('Zuzu::AST::Stmt::Catch') ) {
		$self->_visit_node( $node->type_expr );
		$self->_push_scope;
		$self->_declare_typed_name( $node->name, 'Any' );
		$self->_visit_node( $node->block );
		$self->_pop_scope;
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::Call') or $node->isa('Zuzu::AST::Expr::MemberCall') ) {
		$self->_visit_node( $node->callee ) if $node->can('callee');
		$self->_visit_node( $node->object ) if $node->can('object');
		my @arg_types;
		for my $arg ( @{ $node->args // [] } ) {
			my $expr = ref($arg) eq 'ARRAY' ? $arg->[1] : $arg;
			if ( ref($arg) eq 'ARRAY' and $arg->[2] ) {
				$self->_visit_node( $arg->[0] );
			}
			$self->_visit_node($expr);
			next if blessed($expr) and $expr->isa('Zuzu::AST::Expr::Spread');
			push @arg_types, $self->_expr_static_type($expr)
				if ref($arg) ne 'ARRAY' or !defined $arg->[0];
		}
		$node->{_arg_static_types} = \@arg_types;
		return;
	}

	if ( $node->isa('Zuzu::AST::Expr::DynamicMemberCall') ) {
		$self->_visit_node( $node->object );
		$self->_visit_node( $node->method_expr );
		for my $arg ( @{ $node->args // [] } ) {
			my $expr = ref($arg) eq 'ARRAY' ? $arg->[1] : $arg;
			if ( ref($arg) eq 'ARRAY' and $arg->[2] ) {
				$self->_visit_node( $arg->[0] );
			}
			$self->_visit_node($expr);
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
		$self->_visit_block_with_scope( $node->block );
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

sub _expr_matches_type {
	my ( $self, $expr, $target_type ) = @_;

	return 1 if !defined $target_type or $target_type eq 'Any';

	my $expr_type = $self->_expr_static_type($expr);
	return 0 if !defined $expr_type;

	return $expr_type eq $target_type ? 1 : 0;
}

sub _expr_static_type {
	my ( $self, $expr ) = @_;

	return undef if !defined $expr;
	return undef if !blessed($expr);

	if ( $expr->isa('Zuzu::AST::Expr::Var') ) {
		my $declared_type = $self->_lookup_declared_type( $expr->name );
		return undef if !defined $declared_type or $declared_type eq 'Any';
		return $declared_type;
	}

	if ( $expr->isa('Zuzu::AST::Expr::Literal') ) {
		my $value = $expr->value;

		return 'Null' if !defined $value;
		return 'Boolean' if blessed($value) and $value->isa('Zuzu::Value::Boolean');
		return 'Array' if blessed($value) and $value->isa('Zuzu::Value::Array');
		return 'Dict' if blessed($value) and $value->isa('Zuzu::Value::Dict');
		return 'Set' if blessed($value) and $value->isa('Zuzu::Value::Set');
		return 'Bag' if blessed($value) and $value->isa('Zuzu::Value::Bag');
		return 'Function' if blessed($value) and $value->isa('Zuzu::Value::Function');
		return 'Class' if blessed($value) and $value->isa('Zuzu::Value::Class');
		return 'Object' if blessed($value) and $value->isa('Zuzu::Value::Object');
		return 'Number' if !ref($value) and $value =~ /^-?(?:\d+(?:\.\d+)?|\.\d+)$/;

		return 'String';
	}

	return undef;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::AST::Visitor::TypeCheckHints >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
