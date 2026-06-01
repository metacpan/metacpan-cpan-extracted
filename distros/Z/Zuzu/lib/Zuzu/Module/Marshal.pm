package Zuzu::Module::Marshal;

use utf8;

our $VERSION = '0.001003';

use POSIX qw( isfinite );
use Scalar::Util qw( blessed looks_like_number refaddr );

use Zuzu::Marshal::CBOR qw(
	byte_string
	bytes_value
	cbor_false
	cbor_true
	decode_one
	encode_one
	is_byte_string
	is_cbor_bool
	is_tagged
	is_text_string
	tag
	tag_number
	tag_value
	text_string
	text_value
);
use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
);
use Zuzu::Env;
use Zuzu::Value::BinaryString;
use Zuzu::Value::Boolean;
use Zuzu::Value::Array;
use Zuzu::Value::Dict;
use Zuzu::Value::PairList;
use Zuzu::Value::Set;
use Zuzu::Value::Bag;
use Zuzu::Value::Object;
use Zuzu::Value::Class;
use Zuzu::Value::Function;
use Zuzu::Value::Trait;
use Zuzu::Weak qw( slot_value store_value );
use Path::Tiny qw( path );

use constant MAX_SAFE_INTEGER => 9007199254740991;
use constant KIND_PAIR => 1;
use constant KIND_ARRAY => 2;
use constant KIND_DICT => 3;
use constant KIND_PAIRLIST => 4;
use constant KIND_SET => 5;
use constant KIND_BAG => 6;
use constant KIND_OBJECT => 7;
use constant KIND_FUNCTION => 8;
use constant KIND_CLASS => 9;
use constant KIND_TRAIT => 10;
use constant KIND_BOUND_METHOD => 11;
use constant KIND_TIME => 12;
use constant KIND_PATH => 13;
use constant CODE_FUNCTION => 1;
use constant CODE_CLASS => 2;
use constant CODE_TRAIT => 3;
use constant EDGE_STRONG => 'strong';
use constant EDGE_WEAK => 'weak';

my $TRUE = Zuzu::Value::Boolean->new( value => 1 );
my $FALSE = Zuzu::Value::Boolean->new( value => 0 );

sub _call_file {
	my ( $runtime ) = @_;
	return $runtime->{_native_call_file} // '<std/marshal>';
}

sub _call_line {
	my ( $runtime ) = @_;
	return $runtime->{_native_call_line} // 0;
}

sub _throw_object {
	my ( $runtime, $class, $message ) = @_;

	die {
		_zuzu_throw => 1,
		value => $runtime->_instantiate_builtin_object(
			$class,
			{
				message => $message,
				file => _call_file($runtime),
				line => _call_line($runtime),
			},
		),
	};
}

sub _throw_type {
	my ( $runtime, $message ) = @_;

	my $class = $runtime->{_builtin_classes}{TypeException}
		// $runtime->{_builtin_classes}{Exception};
	_throw_object( $runtime, $class, $message );
}

sub _assert_arity {
	my ( $runtime, $name, $args, $expected ) = @_;

	my $got = scalar @{ $args // [] };
	return if $got == $expected;

	_throw_type(
		$runtime,
		"TypeException: std/marshal.$name expects $expected argument"
			. ( $expected == 1 ? '' : 's' )
			. ", got $got",
	);
}

sub _assert_binary_string {
	my ( $runtime, $name, $value ) = @_;

	return if blessed($value) and $value->isa('Zuzu::Value::BinaryString');

	my $type = $runtime->_type_name($value);

	_throw_type(
		$runtime,
		"TypeException: std/marshal.$name expects BinaryString, got $type",
	);
}

sub _zuzu_bool {
	my ( $value ) = @_;
	return $value ? $TRUE : $FALSE;
}

sub _safe_to_dump {
	my ( $runtime, $value ) = @_;

	return eval {
		dump_value( $runtime, $value );
		1;
	} ? 1 : 0;
}

sub dump_value {
	my ( $runtime, $value ) = @_;

	my $envelope = _encode_envelope( $runtime, $value );

	return encode_one($envelope);
}

sub load_value {
	my ( $runtime, $bytes ) = @_;

	my $decoded = decode_one($bytes);

	return _decode_envelope( $runtime, $decoded );
}

sub _function_expression_source {
	my ( $runtime, $fn ) = @_;

	die "Function source extraction expects a Function value"
		if !blessed($fn) or !$fn->isa('Zuzu::Value::Function');
	die "Native functions do not have ZuzuScript source"
		if $fn->{_native};
	die "Function value has no AST body for source extraction"
		if !$fn->body;

	my $prefix = $fn->is_async ? 'async function' : 'function';
	my $source = $prefix . ' (' . _source_param_list($fn) . ')';
	my $return_type = $fn->return_type // 'Any';
	$source .= ' -> ' . $return_type if $return_type ne 'Any';
	$source .= ' ' . _source_block( $fn->body );

	return $source;
}

sub _analyse_function_value {
	my ( $runtime, $fn ) = @_;

	my $source = _function_expression_source( $runtime, $fn );
	my %free;
	my %bound = _function_initial_bindings($fn);
	_collect_free_names_from_block( $fn->body, \%bound, \%free );

	my @captures;
	my @internal_dependencies;
	my @external_dependencies;
	for my $name ( sort keys %free ) {
		next if _is_builtin_name( $runtime, $name );

		my $binding = _find_function_binding( $fn, $name );
		die "Function source references unresolved name '$name'"
			if !$binding;

		my $value = ${ $binding->{ref} };
		if ( my $external = _external_std_dependency(
			$runtime,
			$name,
			$binding->{ref},
		) ) {
			push @external_dependencies, $external;
			next;
		}
		if ( _is_internal_dependency_value($value) ) {
			die "Function dependency '$name' is not const"
				if !$binding->{const};
			push @internal_dependencies, {
				name => $name,
				value => $value,
			};
			next;
		}
		die "Function capture '$name' is not const"
			if !$binding->{const};
		die "Function capture '$name' is not a scalar value"
			if !_is_scalar_capture_value( $runtime, $value );
		push @captures, {
			name => $name,
			value => $value,
		};
	}

	return {
		source => $source,
		free_names => [ sort keys %free ],
		captures => \@captures,
		internal_dependencies => \@internal_dependencies,
		external_dependencies => \@external_dependencies,
	};
}

sub _analyse_class_value {
	my ( $runtime, $class_value ) = @_;

	my $source = _class_declaration_source( $runtime, $class_value );
	my $node = $class_value->source_node;
	my %free;
	my %bound = _class_initial_bindings($node);
	_collect_class_free_names( $node, \%bound, \%free );

	my @captures;
	my @internal_dependencies;
	my @external_dependencies;
	for my $name ( sort keys %free ) {
		next if _is_builtin_name( $runtime, $name );

		my $binding = _find_class_binding( $class_value, $name );
		die "Class source references unresolved name '$name'"
			if !$binding;

		my $value = ${ $binding->{ref} };
		if ( my $external = _external_std_dependency(
			$runtime,
			$name,
			$binding->{ref},
		) ) {
			push @external_dependencies, $external;
			next;
		}
		if ( _is_internal_dependency_value($value) ) {
			die "Class dependency '$name' is not const"
				if !$binding->{const};
			push @internal_dependencies, {
				name => $name,
				value => $value,
			};
			next;
		}
		die "Class capture '$name' is not const"
			if !$binding->{const};
		die "Class capture '$name' is not a scalar value"
			if !_is_scalar_capture_value( $runtime, $value );
		push @captures, {
			name => $name,
			value => $value,
		};
	}

	return {
		source => $source,
		free_names => [ sort keys %free ],
		captures => \@captures,
		internal_dependencies => \@internal_dependencies,
		external_dependencies => \@external_dependencies,
	};
}

sub _analyse_trait_value {
	my ( $runtime, $trait_value ) = @_;

	my $source = _trait_declaration_source( $runtime, $trait_value );
	my $node = $trait_value->source_node;
	my %free;
	my %bound = _trait_initial_bindings($node);
	_collect_trait_free_names( $node, \%bound, \%free );

	my @captures;
	my @internal_dependencies;
	my @external_dependencies;
	for my $name ( sort keys %free ) {
		next if _is_builtin_name( $runtime, $name );

		my $binding = _find_trait_binding( $trait_value, $name );
		die "Trait source references unresolved name '$name'"
			if !$binding;

		my $value = ${ $binding->{ref} };
		if ( my $external = _external_std_dependency(
			$runtime,
			$name,
			$binding->{ref},
		) ) {
			push @external_dependencies, $external;
			next;
		}
		if ( _is_internal_dependency_value($value) ) {
			die "Trait dependency '$name' is not const"
				if !$binding->{const};
			push @internal_dependencies, {
				name => $name,
				value => $value,
			};
			next;
		}
		die "Trait capture '$name' is not const"
			if !$binding->{const};
		die "Trait capture '$name' is not a scalar value"
			if !_is_scalar_capture_value( $runtime, $value );
		push @captures, {
			name => $name,
			value => $value,
		};
	}

	return {
		source => $source,
		free_names => [ sort keys %free ],
		captures => \@captures,
		internal_dependencies => \@internal_dependencies,
		external_dependencies => \@external_dependencies,
	};
}

sub _function_initial_bindings {
	my ( $fn ) = @_;

	my %bound = map { $_ => 1 } @{ $fn->params // [] };
	$bound{ $fn->vararg } = 1 if defined $fn->vararg;
	$bound{ $fn->named_vararg } = 1 if defined $fn->named_vararg;
	$bound{__argc__} = 1;

	return %bound;
}

sub _trait_initial_bindings {
	my ( $node ) = @_;

	return ( $node->name => 1 );
}

sub _collect_trait_free_names {
	my ( $node, $bound, $free ) = @_;

	my %method_base_bound = (
		%{ $bound // {} },
		self => 1,
		super => 1,
	);
	for my $method ( @{ $node->methods // [] } ) {
		my %method_bound = (
			%method_base_bound,
			_function_method_bindings($method),
		);
		_collect_free_names_from_block(
			$method->body,
			\%method_bound,
			$free,
		);
	}

	return;
}

sub _class_initial_bindings {
	my ( $node ) = @_;

	my %bound = ( $node->name => 1 );
	for my $nested ( @{ $node->classes // [] } ) {
		$bound{ $nested->name } = 1;
	}

	return %bound;
}

sub _collect_class_free_names {
	my ( $node, $bound, $free ) = @_;

	_collect_free_names_from_expr( $node->parent, $bound, $free )
		if defined $node->parent;
	for my $trait ( @{ $node->traits // [] } ) {
		_collect_free_names_from_expr( $trait, $bound, $free );
	}
	for my $field ( @{ $node->fields // [] } ) {
		_collect_free_names_from_expr( $field->{init}, $bound, $free )
			if defined $field->{init};
	}

	my %instance_bound = (
		%{ $bound // {} },
		self => 1,
		super => 1,
		map { $_->{name} => 1 } @{ $node->fields // [] },
	);
	for my $method ( @{ $node->methods // [] } ) {
		my %method_bound = (
			%instance_bound,
			_function_method_bindings($method),
		);
		_collect_free_names_from_block(
			$method->body,
			\%method_bound,
			$free,
		);
	}

	my %static_bound = ( %{ $bound // {} }, self => 1, super => 1 );
	for my $method ( @{ $node->static_methods // [] } ) {
		my %method_bound = (
			%static_bound,
			_function_method_bindings($method),
		);
		_collect_free_names_from_block(
			$method->body,
			\%method_bound,
			$free,
		);
	}

	for my $nested ( @{ $node->classes // [] } ) {
		my %nested_bound = ( %{ $bound // {} }, _class_initial_bindings($nested) );
		_collect_class_free_names( $nested, \%nested_bound, $free );
	}

	return;
}

sub _function_method_bindings {
	my ( $method ) = @_;

	my %bound = map { $_ => 1 } @{ $method->params // [] };
	$bound{ $method->vararg } = 1 if defined $method->vararg;
	$bound{ $method->named_vararg } = 1 if defined $method->named_vararg;
	$bound{__argc__} = 1;

	return %bound;
}

sub _collect_free_names_from_block {
	my ( $block, $bound, $free ) = @_;

	my %local = %{ $bound // {} };
	for my $stmt ( @{ $block->statements // [] } ) {
		_collect_free_names_from_stmt( $stmt, \%local, $free );
	}

	return;
}

sub _collect_free_names_from_stmt {
	my ( $stmt, $bound, $free ) = @_;

	if ( $stmt->isa('Zuzu::AST::Stmt::Return') ) {
		_collect_free_names_from_expr( $stmt->expr, $bound, $free )
			if defined $stmt->expr;
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Expr') ) {
		_collect_free_names_from_expr( $stmt->expr, $bound, $free );
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Let') ) {
		_collect_free_names_from_expr( $stmt->init, $bound, $free )
			if defined $stmt->init;
		$bound->{ $stmt->name } = 1;
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Assign') ) {
		_collect_free_names_from_expr( $stmt->target, $bound, $free );
		if ( ( $stmt->op // '' ) eq '~=' ) {
			_collect_free_names_from_expr( $stmt->match_expr, $bound, $free );
			my %replace_bound = ( %{ $bound // {} }, m => 1 );
			_collect_free_names_from_expr(
				$stmt->replace_expr,
				\%replace_bound,
				$free,
			);
			return;
		}
		_collect_free_names_from_expr( $stmt->expr, $bound, $free );
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Block') ) {
		_collect_free_names_from_block( $stmt, $bound, $free );
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::If') ) {
		_collect_free_names_from_expr( $stmt->cond, $bound, $free );
		_collect_free_names_from_block( $stmt->then_block, $bound, $free );
		_collect_free_names_from_else( $stmt->else_branch, $bound, $free )
			if $stmt->else_branch;
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::While') ) {
		_collect_free_names_from_expr( $stmt->cond, $bound, $free );
		_collect_free_names_from_block( $stmt->body, $bound, $free );
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::For') ) {
		_collect_free_names_from_expr( $stmt->collection, $bound, $free );
		my %loop_bound = %{ $bound // {} };
		$loop_bound{ $stmt->var } = 1 if $stmt->declare_loop_var;
		_collect_free_names_from_block( $stmt->body, \%loop_bound, $free );
		_collect_free_names_from_block(
			$stmt->else_block,
			$bound,
			$free,
		) if $stmt->else_block;
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Try') ) {
		_collect_free_names_from_block( $stmt->block, $bound, $free );
		for my $catch ( @{ $stmt->catches // [] } ) {
			_collect_free_names_from_expr( $catch->type_expr, $bound, $free );
			my %catch_bound = ( %{ $bound // {} }, $catch->name => 1 );
			_collect_free_names_from_block(
				$catch->block,
				\%catch_bound,
				$free,
			);
		}
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Import') ) {
		_collect_import_bound_names( $stmt, $bound );
		_collect_free_names_from_expr(
			$stmt->condition_expr,
			$bound,
			$free,
		) if defined $stmt->condition_expr;
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Function') ) {
		$bound->{ $stmt->name } = 1;
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Die') ) {
		_collect_free_names_from_expr( $stmt->expr, $bound, $free );
		return;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Throw') ) {
		_collect_free_names_from_expr( $stmt->expr, $bound, $free );
		return;
	}
	if (
		$stmt->isa('Zuzu::AST::Stmt::Next')
		or $stmt->isa('Zuzu::AST::Stmt::Last')
		or $stmt->isa('Zuzu::AST::Stmt::Continue')
	) {
		return;
	}

	die "Unsupported function body statement for capture analysis: "
		. ref($stmt);
}

sub _collect_free_names_from_else {
	my ( $branch, $bound, $free ) = @_;

	if ( $branch->isa('Zuzu::AST::Block') ) {
		_collect_free_names_from_block( $branch, $bound, $free );
		return;
	}
	if ( $branch->isa('Zuzu::AST::Stmt::If') ) {
		_collect_free_names_from_stmt( $branch, $bound, $free );
		return;
	}

	die "Unsupported else branch for capture analysis: " . ref($branch);
}

sub _collect_free_names_from_expr {
	my ( $expr, $bound, $free ) = @_;

	return if !defined $expr;
	if ( $expr->isa('Zuzu::AST::Expr::Var') ) {
		$free->{ $expr->name } = 1 if !$bound->{ $expr->name };
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Literal') ) {
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::TypeRef') ) {
		$free->{ $expr->root } = 1 if !$bound->{ $expr->root };
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Binary') ) {
		_collect_free_names_from_expr( $expr->left, $bound, $free );
		_collect_free_names_from_expr( $expr->right, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Unary') ) {
		_collect_free_names_from_expr( $expr->expr, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Ternary') ) {
		_collect_free_names_from_expr( $expr->cond, $bound, $free );
		_collect_free_names_from_expr( $expr->if_true, $bound, $free )
			if defined $expr->if_true;
		_collect_free_names_from_expr( $expr->if_false, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Call') ) {
		_collect_free_names_from_expr( $expr->callee, $bound, $free );
		_collect_free_names_from_args( $expr->args, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::MemberCall') ) {
		_collect_free_names_from_expr( $expr->object, $bound, $free );
		_collect_free_names_from_args( $expr->args, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::DynamicMemberCall') ) {
		_collect_free_names_from_expr( $expr->object, $bound, $free );
		_collect_free_names_from_expr( $expr->method_expr, $bound, $free );
		_collect_free_names_from_args( $expr->args, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Index') ) {
		_collect_free_names_from_expr( $expr->array, $bound, $free );
		_collect_free_names_from_expr( $expr->index, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Slice') ) {
		_collect_free_names_from_expr( $expr->collection, $bound, $free );
		_collect_free_names_from_expr( $expr->start, $bound, $free );
		_collect_free_names_from_expr( $expr->length, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::DictGet') ) {
		_collect_free_names_from_expr( $expr->dict, $bound, $free );
		_collect_free_names_from_expr( $expr->key, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::New') ) {
		_collect_free_names_from_expr( $expr->class_expr, $bound, $free );
		for my $trait ( @{ $expr->traits // [] } ) {
			_collect_free_names_from_expr( $trait, $bound, $free );
		}
		_collect_free_names_from_args( $expr->args, $bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Function') ) {
		my %nested_bound = ( %{ $bound // {} }, _function_expr_bindings($expr) );
		_collect_free_names_from_block( $expr->body, \%nested_bound, $free );
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Await') ) {
		_collect_free_names_from_block( $expr->block, $bound, $free );
		return;
	}
	if (
		$expr->isa('Zuzu::AST::Expr::Array')
		or $expr->isa('Zuzu::AST::Expr::Set')
		or $expr->isa('Zuzu::AST::Expr::Bag')
	) {
		for my $item ( @{ $expr->items // [] } ) {
			_collect_free_names_from_expr( $item, $bound, $free );
		}
		return;
	}
	if (
		$expr->isa('Zuzu::AST::Expr::Dict')
		or $expr->isa('Zuzu::AST::Expr::PairList')
	) {
		for my $pair ( @{ $expr->pairs // [] } ) {
			_collect_free_names_from_expr( $pair->[0], $bound, $free );
			_collect_free_names_from_expr( $pair->[1], $bound, $free );
		}
		return;
	}
	if ( $expr->isa('Zuzu::AST::Expr::Range') ) {
		_collect_free_names_from_expr( $expr->start, $bound, $free );
		_collect_free_names_from_expr( $expr->end, $bound, $free );
		return;
	}

	die "Unsupported expression for capture analysis: " . ref($expr);
}

sub _function_expr_bindings {
	my ( $expr ) = @_;

	my %bound = map { $_ => 1 } @{ $expr->params // [] };
	$bound{ $expr->vararg } = 1 if defined $expr->vararg;
	$bound{ $expr->named_vararg } = 1 if defined $expr->named_vararg;
	$bound{__argc__} = 1;

	return %bound;
}

sub _collect_free_names_from_args {
	my ( $args, $bound, $free ) = @_;

	for my $arg ( @{ $args // [] } ) {
		my ( $name, $value, $dynamic ) = @{ $arg };
		_collect_free_names_from_expr( $name, $bound, $free )
			if $dynamic;
		_collect_free_names_from_expr( $value, $bound, $free );
	}

	return;
}

sub _collect_import_bound_names {
	my ( $stmt, $bound ) = @_;

	for my $item ( @{ $stmt->items // [] } ) {
		next if $item->{star};
		$bound->{ $item->{alias} } = 1;
	}

	return;
}

sub _is_builtin_name {
	my ( $runtime, $name ) = @_;

	return $runtime->{_builtin_global_names}{$name} ? 1 : 0;
}

sub _find_function_binding {
	my ( $fn, $name ) = @_;

	my $env = $fn->closure_env;
	while ($env) {
		if ( exists $env->slots->{$name} ) {
			return {
				ref => $env->slots->{$name},
				const => $env->const->{$name} ? 1 : 0,
				type => $env->types->{$name} // 'Any',
			};
		}
		$env = $env->parent;
	}

	return undef;
}

sub _find_class_binding {
	my ( $class_value, $name ) = @_;

	my $env = $class_value->closure_env;
	while ($env) {
		if ( exists $env->slots->{$name} ) {
			return {
				ref => $env->slots->{$name},
				const => $env->const->{$name} ? 1 : 0,
				type => $env->types->{$name} // 'Any',
			};
		}
		$env = $env->parent;
	}

	return undef;
}

sub _find_trait_binding {
	my ( $trait_value, $name ) = @_;

	my $env = $trait_value->closure_env;
	while ($env) {
		if ( exists $env->slots->{$name} ) {
			return {
				ref => $env->slots->{$name},
				const => $env->const->{$name} ? 1 : 0,
				type => $env->types->{$name} // 'Any',
			};
		}
		$env = $env->parent;
	}

	return undef;
}

sub _external_std_dependency {
	my ( $runtime, $local_name, $ref ) = @_;

	return undef if !defined $runtime or !defined $ref;

	for my $module ( sort keys %{ $runtime->{_modules} // {} } ) {
		next if $module !~ m{\Astd/};
		my $exports = $runtime->{_module_exports}{$module} // {};
		my $env = $runtime->{_modules}{$module};
		for my $export_name ( sort keys %{ $exports } ) {
			next if !exists $env->slots->{$export_name};
			next if $env->slots->{$export_name} != $ref;
			return {
				local_name => $local_name,
				module => $module,
				export_name => $export_name,
			};
		}
	}

	return undef;
}

sub _is_internal_dependency_value {
	my ( $value ) = @_;

	return 1 if blessed($value) and $value->isa('Zuzu::Value::Function');
	return 1 if blessed($value) and $value->isa('Zuzu::Value::Class');
	return 1 if blessed($value) and $value->isa('Zuzu::Value::Trait');
	return 0;
}

sub _is_scalar_capture_value {
	my ( $runtime, $value ) = @_;

	return 0 if !_is_scalar_type( $runtime, $value );
	return eval {
		_encode_scalar_value( $runtime, $value );
		1;
	} ? 1 : 0;
}

sub _class_declaration_source {
	my ( $runtime, $class_value ) = @_;

	die "Class source extraction expects a Class value"
		if !blessed($class_value) or !$class_value->isa('Zuzu::Value::Class');
	die "Native classes do not have ZuzuScript source"
		if $class_value->native_constructor or $class_value->builtin_kind;
	die "Class value has no AST declaration for source extraction"
		if !$class_value->source_node;

	return _source_class_decl( $class_value->source_node );
}

sub _trait_declaration_source {
	my ( $runtime, $trait_value ) = @_;

	die "Trait source extraction expects a Trait value"
		if !blessed($trait_value) or !$trait_value->isa('Zuzu::Value::Trait');
	die "Trait value has no AST declaration for source extraction"
		if !$trait_value->source_node;

	return _source_trait_decl( $trait_value->source_node );
}

sub _source_class_decl {
	my ( $node ) = @_;

	my $source = 'class ' . $node->name;
	$source .= ' extends ' . _source_expr( $node->parent )
		if defined $node->parent;
	if ( @{ $node->traits // [] } ) {
		$source .= ' with ' . join(
			', ',
			map { _source_expr($_) } @{ $node->traits },
		);
	}

	my @members;
	push @members, map { _source_field_decl($_) } @{ $node->fields // [] };
	push @members, map {
		_source_method_decl($_)
	} grep {
		!$_->{_generated_field_accessor}
	} @{ $node->methods // [] };
	push @members, map {
		_source_method_decl( $_, 1 )
	} @{ $node->static_methods // [] };
	push @members, map { _source_class_decl($_) } @{ $node->classes // [] };

	return $source . ';' if !@members;
	return $source . ' { ' . join( ' ', @members ) . ' }';
}

sub _source_trait_decl {
	my ( $node ) = @_;

	my $source = 'trait ' . $node->name;
	my @members = map { _source_method_decl($_) } @{ $node->methods // [] };

	return $source . ';' if !@members;
	return $source . ' { ' . join( ' ', @members ) . ' }';
}

sub _source_field_decl {
	my ( $field ) = @_;

	my $kw = $field->{is_const} ? 'const' : 'let';
	my $name = _source_typed_name(
		$field->{declared_type},
		$field->{name},
		'Any',
	);
	my $source = "$kw $name";
	if ( @{ $field->{accessors} // [] } ) {
		$source .= ' with ' . join( ', ', @{ $field->{accessors} } );
	}
	$source .= ' := ' . _source_expr( $field->{init} )
		if defined $field->{init};
	$source .= ' but weak' if $field->{is_weak_storage};

	return $source . ';';
}

sub _source_method_decl {
	my ( $method, $force_static ) = @_;

	my $source = '';
	$source .= 'async ' if $method->is_async;
	$source .= 'static ' if $force_static || $method->is_static;
	$source .= 'method ' . $method->name . ' ('
		. _source_param_list($method)
		. ')';
	my $return_type = $method->return_type // 'Any';
	$source .= ' -> ' . $return_type if $return_type ne 'Any';
	$source .= ' ' . _source_block( $method->body );

	return $source;
}

sub _source_param_list {
	my ( $fn ) = @_;

	my @params;
	for my $name ( @{ $fn->params // [] } ) {
		my $type = $fn->param_types->{$name} // 'Any';
		my $param = $type eq 'Any' ? $name : "$type $name";
		if ( $fn->param_optional->{$name} ) {
			$param .= '?';
		}
		elsif ( exists $fn->param_defaults->{$name} ) {
			$param .= ' := ' . _source_expr( $fn->param_defaults->{$name} );
		}
		push @params, $param;
	}

	my @collectors;
	if ( defined $fn->vararg ) {
		push @collectors, _source_typed_name(
			$fn->vararg_type,
			$fn->vararg,
			'Array',
		);
	}
	if ( defined $fn->named_vararg ) {
		push @collectors, _source_typed_name(
			$fn->named_vararg_type,
			$fn->named_vararg,
			'PairList',
		);
	}
	push @params, '... ' . join( ', ', @collectors ) if @collectors;

	return join( ', ', @params );
}

sub _source_typed_name {
	my ( $type, $name, $implicit_type ) = @_;

	$type //= 'Any';
	return $name if $type eq 'Any' or $type eq $implicit_type;
	return "$type $name";
}

sub _source_block {
	my ( $block ) = @_;

	my @statements = map {
		_source_stmt($_)
	} @{ $block->statements // [] };
	return '{}' if !@statements;

	return '{ ' . join( ' ', @statements ) . ' }';
}

sub _source_stmt {
	my ( $stmt ) = @_;

	if ( $stmt->isa('Zuzu::AST::Stmt::Return') ) {
		return defined $stmt->expr
			? 'return ' . _source_expr( $stmt->expr ) . ';'
			: 'return;';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Expr') ) {
		return _source_expr( $stmt->expr ) . ';';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Let') ) {
		my $kw = $stmt->is_const ? 'const' : 'let';
		my $name = _source_typed_name(
			$stmt->declared_type,
			$stmt->name,
			'Any',
		);
		my $source = "$kw $name";
		$source .= ' := ' . _source_expr( $stmt->init )
			if defined $stmt->init;
		$source .= ' but weak' if $stmt->is_weak_storage;
		return $source . ';';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Assign') ) {
		if ( ( $stmt->op // '' ) eq '~=' ) {
			return join(
				' ',
				_source_expr( $stmt->target ),
				'~=',
				_source_expr( $stmt->match_expr ),
				'->',
				_source_expr( $stmt->replace_expr ) . ';',
			);
		}
		return join(
			' ',
			_source_expr( $stmt->target ),
			$stmt->op,
			_source_expr( $stmt->expr )
				. ( $stmt->is_weak_write ? ' but weak' : '' )
				. ';',
		);
	}
	if ( $stmt->isa('Zuzu::AST::Block') ) {
		return _source_block($stmt);
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::If') ) {
		my $source = 'if (' . _source_expr( $stmt->cond ) . ') '
			. _source_block( $stmt->then_block );
		$source .= ' else ' . _source_else_branch( $stmt->else_branch )
			if $stmt->else_branch;
		return $source;
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::While') ) {
		return 'while (' . _source_expr( $stmt->cond ) . ') '
			. _source_block( $stmt->body );
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Die') ) {
		return 'die ' . _source_expr( $stmt->expr ) . ';';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Throw') ) {
		return 'throw ' . _source_expr( $stmt->expr ) . ';';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Import') ) {
		my $source = 'from ' . $stmt->module . ' ';
		$source .= 'try ' if $stmt->try_mode;
		$source .= 'import ';
		$source .= join(
			', ',
			map {
				if ( $_->{star} ) {
					'*';
				}
				elsif ( $_->{alias} ne $_->{name} ) {
					$_->{name} . ' as ' . $_->{alias};
				}
				else {
					$_->{name};
				}
			} @{ $stmt->items // [] },
		);
		if ( defined $stmt->condition_expr ) {
			$source .= $stmt->condition_positive ? ' if ' : ' unless ';
			$source .= _source_expr( $stmt->condition_expr );
		}
		return $source . ';';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Next') ) {
		return 'next;';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Last') ) {
		return 'last;';
	}
	if ( $stmt->isa('Zuzu::AST::Stmt::Continue') ) {
		return 'continue;';
	}

	die "Unsupported function body statement for source extraction: "
		. ref($stmt);
}

sub _source_else_branch {
	my ( $branch ) = @_;

	return _source_block($branch) if $branch->isa('Zuzu::AST::Block');
	return _source_stmt($branch) if $branch->isa('Zuzu::AST::Stmt::If');
	die "Unsupported else branch for source extraction: " . ref($branch);
}

sub _source_expr {
	my ( $expr, $parent_prec, $side ) = @_;

	$parent_prec //= 0;
	$side //= '';

	die "Missing expression for source extraction" if !defined $expr;

	my $source;
	my $prec = 100;
	if ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Literal') ) {
		$source = _source_literal( $expr->value );
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Var') ) {
		$source = $expr->name;
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::TypeRef') ) {
		$source = $expr->root;
		$source .= '.' . $expr->member if defined $expr->member;
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Binary') ) {
		$prec = _source_binary_prec( $expr->op );
		my $right_parent_prec =
			( $expr->op eq '**' or $expr->op eq '◁' or $expr->op eq '<|' )
			? $prec - 1
			: $prec;
		$source = join(
			' ',
			_source_expr( $expr->left, $prec, 'left' ),
			$expr->op,
			_source_expr( $expr->right, $right_parent_prec, 'right' ),
		);
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Unary') ) {
		$prec = 90;
		my $op = $expr->op;
		if ( $op =~ /\A[A-Za-z_]\w*\z/ ) {
			$source = $op . ' ' . _source_expr( $expr->expr, $prec );
		}
		else {
			$source = $op . _source_expr( $expr->expr, $prec );
		}
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Ternary') ) {
		$prec = 1;
		if ( defined $expr->if_true ) {
			$source = _source_expr( $expr->cond, $prec )
				. ' ? '
				. _source_expr( $expr->if_true )
				. ' : '
				. _source_expr( $expr->if_false );
		}
		else {
			$source = _source_expr( $expr->cond, $prec )
				. ' ?: '
				. _source_expr( $expr->if_false );
		}
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Call') ) {
		$source = _source_expr( $expr->callee, 95 )
			. '('
			. _source_args( $expr->args )
			. ')';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::MemberCall') ) {
		$source = _source_expr( $expr->object, 95 )
			. '.'
			. $expr->method
			. '('
			. _source_args( $expr->args )
			. ')';
	}
	elsif (
		blessed($expr)
		and $expr->isa('Zuzu::AST::Expr::DynamicMemberCall')
	) {
		$source = _source_expr( $expr->object, 95 )
			. '.('
			. _source_expr( $expr->method_expr )
			. ')('
			. _source_args( $expr->args )
			. ')';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Index') ) {
		$source = _source_expr( $expr->array, 95 )
			. '['
			. _source_expr( $expr->index )
			. ']';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Slice') ) {
		$source = _source_expr( $expr->collection, 95 )
			. '['
			. ( defined $expr->start ? _source_expr( $expr->start ) : '' )
			. ':'
			. ( defined $expr->length ? _source_expr( $expr->length ) : '' )
			. ']';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::DictGet') ) {
		$source = _source_expr( $expr->dict, 95 )
			. '{'
			. _source_expr( $expr->key )
			. '}';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Array') ) {
		$source = '[ ' . join(
			', ',
			map { _source_expr($_) } @{ $expr->items // [] },
		) . ' ]';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Dict') ) {
		$source = '{ ' . join(
			', ',
			map {
				_source_expr( $_->[0] ) . ': ' . _source_expr( $_->[1] )
			} @{ $expr->pairs // [] },
		) . ' }';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::PairList') ) {
		$source = '{{ ' . join(
			', ',
			map {
				_source_expr( $_->[0] ) . ': ' . _source_expr( $_->[1] )
			} @{ $expr->pairs // [] },
		) . ' }}';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Set') ) {
		$source = '<< ' . join(
			', ',
			map { _source_expr($_) } @{ $expr->items // [] },
		) . ' >>';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Bag') ) {
		$source = '<<< ' . join(
			', ',
			map { _source_expr($_) } @{ $expr->items // [] },
		) . ' >>>';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Range') ) {
		$source = _source_expr( $expr->start, 20 )
			. '..'
			. _source_expr( $expr->end, 20 );
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::New') ) {
		$source = 'new '
			. _source_expr( $expr->class_expr, 95 );
		if ( @{ $expr->traits // [] } ) {
			$source .= ' with ' . join(
				', ',
				map { _source_expr($_) } @{ $expr->traits },
			);
		}
		$source .= '('
			. _source_args( $expr->args )
			. ')';
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Function') ) {
		my $fn = Zuzu::Value::Function->new(
			params => [ @{ $expr->params // [] } ],
			vararg => $expr->vararg,
			named_vararg => $expr->named_vararg,
			param_types => { %{ $expr->param_types // {} } },
			vararg_type => $expr->vararg_type // 'Any',
			named_vararg_type => $expr->named_vararg_type // 'PairList',
			param_optional => { %{ $expr->param_optional // {} } },
			param_defaults => { %{ $expr->param_defaults // {} } },
			return_type => $expr->return_type // 'Any',
			body => $expr->body,
			is_async => $expr->is_async ? 1 : 0,
		);
		$source = _function_expression_source( undef, $fn );
	}
	elsif ( blessed($expr) and $expr->isa('Zuzu::AST::Expr::Await') ) {
		$source = 'await ' . _source_block( $expr->block );
	}
	else {
		die "Unsupported expression for source extraction: " . ref($expr);
	}

	return '(' . $source . ')'
		if $prec < $parent_prec or ( $side eq 'right' and $prec == $parent_prec );

	return $source;
}

sub _source_binary_prec {
	my ( $op ) = @_;

	return 0 if $op eq '▷' || $op eq '|>' || $op eq '◁' || $op eq '<|';
	return 1 if $op eq 'or' || $op eq '⋁';
	return 2 if $op eq 'xor' || $op eq '⊻';
	return 3 if $op eq 'and' || $op eq '⋀' || $op eq 'nand' || $op eq '⊼';
	return 4 if $op eq 'default';
	return 4 if $op eq '==' || $op eq '≡' || $op eq '!=' || $op eq '≢';
	return 5 if $op =~ /\A(?:=|eq|ne|gt|ge|lt|le|cmp)\z/;
	return 5 if $op =~ /\A(?:eqi|nei|gti|gei|lti|lei|cmpi)\z/;
	return 5 if $op =~ /\A(?:in|subsetof|supersetof|equivalentof)\z/;
	return 5 if $op =~ /\A(?:instanceof|does|can|~|@|@\?|@@)\z/;
	return 5 if $op =~ /\A(?:[<>]=?|<=>|[≤≥≠≶≷∈∉⊂⊃]|⊂⊃)\z/;
	return 6 if $op eq '|';
	return 7 if $op eq '^';
	return 8 if $op eq '&';
	return 9 if $op eq 'union' || $op eq 'intersection' || $op eq '\\';
	return 9 if $op eq '⋃' || $op eq '⋂' || $op eq '∖';
	return 10 if $op eq '_';
	return 11 if $op eq '+' || $op eq '-';
	return 12 if $op eq '*' || $op eq '/' || $op eq '×';
	return 12 if $op eq '÷' || $op eq 'mod';
	return 13 if $op eq '**';

	die "Unsupported binary operator for source extraction: $op";
}

sub _source_args {
	my ( $args ) = @_;

	return join(
		', ',
		map {
			my ( $name, $value, $dynamic ) = @{ $_ };
			if ($dynamic) {
				_source_expr($_->[0]) . ': ' . _source_expr($value);
			}
			elsif ( defined $name ) {
				$name . ': ' . _source_expr($value);
			}
			else {
				_source_expr($value);
			}
		} @{ $args // [] },
	);
}

sub _source_literal {
	my ( $value ) = @_;

	return 'null' if !defined $value;
	return $value->value ? 'true' : 'false'
		if blessed($value) and $value->isa('Zuzu::Value::Boolean');
	return _source_binary_string( $value->bytes )
		if blessed($value) and $value->isa('Zuzu::Value::BinaryString');
	return _source_regexp( $value->pattern, $value->flags )
		if blessed($value) and $value->isa('Zuzu::Value::Regexp');
	return _source_string($value) if !ref($value) and $value !~ /\A-?\d/;
	return "$value" if !ref($value);

	die "Unsupported literal for source extraction: " . ref($value);
}

sub _source_string {
	my ( $value ) = @_;

	$value //= '';
	$value =~ s/\\/\\\\/g;
	$value =~ s/"/\\"/g;
	$value =~ s/\n/\\n/g;
	$value =~ s/\r/\\r/g;
	$value =~ s/\t/\\t/g;

	return '"' . $value . '"';
}

sub _source_binary_string {
	my ( $bytes ) = @_;

	$bytes //= '';
	$bytes =~ s/\\/\\\\/g;
	$bytes =~ s/"/\\"/g;
	$bytes =~ s/\n/\\n/g;
	$bytes =~ s/\r/\\r/g;
	$bytes =~ s/\t/\\t/g;
	$bytes =~ s/([^\x20-\x7E])/sprintf '\\x{%02X}', ord($1)/ge;

	return '~"' . $bytes . '"';
}

sub _source_regexp {
	my ( $pattern, $flags ) = @_;

	$pattern //= '';
	$flags //= '';
	$pattern =~ s{/}{\\/}g;

	return '/' . $pattern . '/' . $flags;
}

sub _number_to_cbor {
	my ( $value ) = @_;

	my $number = 0 + $value;
	die "Number values must be finite" if !isfinite($number);

	if ( _is_integral_number($number) and abs($number) <= MAX_SAFE_INTEGER ) {
		return int($number);
	}

	return $number;
}

sub _is_integral_number {
	my ( $number ) = @_;
	return 0 if !_is_finite_number($number);
	return 0 if _is_negative_zero($number);
	return int($number) == $number ? 1 : 0;
}

sub _is_integer_value {
	my ( $value ) = @_;

	return 0 if ref($value);
	return 0 if !looks_like_number($value);
	return 0 if !_is_finite_number( 0 + $value );
	return int($value) == $value ? 1 : 0;
}

sub _is_finite_number {
	my ( $number ) = @_;
	return isfinite($number) ? 1 : 0;
}

sub _is_negative_zero {
	my ( $number ) = @_;
	return 0 if $number != 0;
	return sprintf( '%.17g', $number ) eq '-0' ? 1 : 0;
}

sub _encode_scalar_value {
	my ( $runtime, $value ) = @_;

	my $type = $runtime->_type_name($value);
	return undef if $type eq 'Null';
	return $value->value ? cbor_true() : cbor_false()
		if $type eq 'Boolean';
	return _number_to_cbor($value) if $type eq 'Number';
	return text_string($value) if $type eq 'String';
	return byte_string( $value->bytes ) if $type eq 'BinaryString';

	die "Value of type $type is not marshalable in scalar phase";
}

sub _decode_scalar_value {
	my ( $runtime, $value ) = @_;

	return undef if !defined $value;
	return _zuzu_bool($value) if is_cbor_bool($value);
	return 0 + $value if !ref($value);
	return text_value($value) if is_text_string($value);
	return Zuzu::Value::BinaryString->new( bytes => bytes_value($value) )
		if is_byte_string($value);

	die "Envelope root is not a scalar value";
}

sub _new_dump_state {
	my %strong_ids;

	return {
		objects => [],
		strong_ids => \%strong_ids,
		on_dump => {},
		code => [],
		code_ids => {},
		code_names => {},
	};
}

sub _encode_value {
	my ( $runtime, $value, $state, $edge_strength ) = @_;

	$edge_strength //= EDGE_STRONG;
	die "Unknown dump edge strength '$edge_strength'"
		if $edge_strength ne EDGE_STRONG and $edge_strength ne EDGE_WEAK;

	return _encode_weak_value( $runtime, $value, $state )
		if $edge_strength eq EDGE_WEAK;

	return _encode_scalar_value( $runtime, $value )
		if _is_scalar_type( $runtime, $value );

	if ( _is_pair_value( $runtime, $value ) ) {
		return _encode_pair_value( $runtime, $value, $state );
	}

	if ( _is_time_value( $runtime, $value ) ) {
		return _encode_time_value( $runtime, $value, $state );
	}

	if ( _is_path_value( $runtime, $value ) ) {
		return _encode_path_value( $runtime, $value, $state );
	}

	if ( blessed($value) and $value->isa('Zuzu::Value::Class') ) {
		return _encode_class_value( $runtime, $value, $state );
	}

	if ( blessed($value) and $value->isa('Zuzu::Value::Trait') ) {
		return _encode_trait_value( $runtime, $value, $state );
	}

	if ( blessed($value) and $value->isa('Zuzu::Value::Function') ) {
		return _encode_bound_method_value( $runtime, $value, $state )
			if $value->{_is_method};
		return _encode_function_value( $runtime, $value, $state );
	}

	my $array = $runtime->_unwrap_builtin_collection( $value, 'Array' );
	if ($array) {
		return _encode_array_value( $runtime, $array, $state );
	}

	my $dict = $runtime->_unwrap_builtin_collection( $value, 'Dict' );
	if ($dict) {
		return _encode_dict_value( $runtime, $dict, $state );
	}

	my $pairlist = $runtime->_unwrap_builtin_collection( $value, 'PairList' );
	if ($pairlist) {
		return _encode_pairlist_value( $runtime, $pairlist, $state );
	}

	my $set = $runtime->_unwrap_builtin_collection( $value, 'Set' );
	if ($set) {
		return _encode_set_value( $runtime, $set, $state );
	}

	my $bag = $runtime->_unwrap_builtin_collection( $value, 'Bag' );
	if ($bag) {
		return _encode_bag_value( $runtime, $bag, $state );
	}

	if ( blessed($value) and $value->isa('Zuzu::Value::Object') ) {
		return _encode_object_value( $runtime, $value, $state );
	}

	my $type = $runtime->_type_name($value);
	die "Value of type $type is not marshalable in this phase";
}

sub _encode_strong_value {
	my ( $runtime, $value, $state ) = @_;

	return _encode_value( $runtime, $value, $state, EDGE_STRONG );
}

sub _encode_weak_value {
	my ( $runtime, $value, $state ) = @_;

	return [ 1, _encode_scalar_value( $runtime, $value ) ]
		if _is_scalar_type( $runtime, $value );

	my $addr = refaddr($value);
	return [ 1, undef ] if !defined $addr;
	return [ 1, undef ] if !exists $state->{strong_ids}{$addr};

	return [ 1, [ 0, $state->{strong_ids}{$addr} ] ];
}

sub _encode_stored_value {
	my ( $runtime, $value, $state, $weak ) = @_;

	return _encode_value(
		$runtime,
		$value,
		$state,
		$weak ? EDGE_WEAK : EDGE_STRONG,
	);
}

sub _is_scalar_type {
	my ( $runtime, $value ) = @_;

	my $type = $runtime->_type_name($value);
	return 1 if $type eq 'Null';
	return 1 if $type eq 'Boolean';
	return 1 if $type eq 'Number';
	return 1 if $type eq 'String';
	return 1 if $type eq 'BinaryString';
	return 0;
}

sub _module_symbol {
	my ( $runtime, $module, $symbol ) = @_;

	my $env = $runtime->_load_module(
		$module,
		_call_file($runtime),
		_call_line($runtime),
	);
	my $ref = $env->find_ref($symbol);
	die "Runtime-supported module $module does not export $symbol"
		if !defined $ref;

	return ${ $ref };
}

sub _object_descends_from {
	my ( $class, $target ) = @_;

	return 0 if !defined $class or !defined $target;
	my $cur = $class;
	while ($cur) {
		return 1 if $cur == $target;
		$cur = $cur->parent;
	}

	return 0;
}

sub _object_is_module_class {
	my ( $runtime, $value, $module, $symbol ) = @_;

	return 0
		if !blessed($value) or !$value->isa('Zuzu::Value::Object');
	my $target = _module_symbol( $runtime, $module, $symbol );

	return _object_descends_from( $value->class, $target );
}

sub _is_pair_value {
	my ( $runtime, $value ) = @_;

	return 0
		if !blessed($value) or !$value->isa('Zuzu::Value::Object');
	return $runtime->_class_is_or_descends( $value->class, 'Pair' ) ? 1 : 0;
}

sub _pair_slot_array {
	my ( $pair ) = @_;

	my $slot = $pair->slots->{pair};
	die "Pair value has invalid pair slot"
		if !blessed($slot) or !$slot->isa('Zuzu::Value::Array');

	return $slot;
}

sub _encode_pair_value {
	my ( $runtime, $pair, $state ) = @_;

	my $addr = refaddr($pair);
	die "Pair value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $items = _pair_slot_array($pair)->items // [];
	my $pair_array = _pair_slot_array($pair);
	my $key = $items->[0];
	my $value = $pair_array->_value_at(1);
	my $weak = $pair_array->weak->[1] ? 1 : 0;
	_encode_strong_value( $runtime, $value, $state ) if !$weak;
	my $payload = [
		text_string($key),
		_encode_stored_value( $runtime, $value, $state, $weak ),
	];
	$state->{objects}[$id] = [ KIND_PAIR, $payload ];

	return [ 0, $id ];
}

sub _encode_class_value {
	my ( $runtime, $class_value, $state ) = @_;

	my $addr = refaddr($class_value);
	die "Class value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $code_id = _encode_class_code( $runtime, $class_value, $state, undef );
	$state->{objects}[$id] = [ KIND_CLASS, [$code_id] ];

	return [ 0, $id ];
}

sub _encode_trait_value {
	my ( $runtime, $trait_value, $state ) = @_;

	my $addr = refaddr($trait_value);
	die "Trait value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $code_id = _encode_trait_code( $runtime, $trait_value, $state, undef );
	$state->{objects}[$id] = [ KIND_TRAIT, [$code_id] ];

	return [ 0, $id ];
}

sub _encode_function_value {
	my ( $runtime, $fn, $state ) = @_;

	die "Bound method values are not marshalable in this phase"
		if $fn->{_is_method};

	my $addr = refaddr($fn);
	die "Function value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $code_id = _encode_function_code( $runtime, $fn, $state, undef );
	$state->{objects}[$id] = [ KIND_FUNCTION, [$code_id] ];

	return [ 0, $id ];
}

sub _encode_bound_method_value {
	my ( $runtime, $method, $state ) = @_;

	die "Unbound method values are not marshalable in this phase"
		if !defined $method->{_bound_self};

	my $addr = refaddr($method);
	die "Bound method value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $method_name = $method->{_method_name} // $method->name;
	die "Bound method value has no method name"
		if !defined $method_name or $method_name eq '';

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	$state->{objects}[$id] = [
		KIND_BOUND_METHOD,
		[
			_encode_strong_value(
				$runtime,
				$method->{_bound_self},
				$state,
			),
			text_string($method_name),
		],
	];

	return [ 0, $id ];
}

sub _encode_function_code {
	my ( $runtime, $fn, $state, $preferred_name ) = @_;

	die "Function dependency is not a Function value"
		if !blessed($fn) or !$fn->isa('Zuzu::Value::Function');
	die "Bound method values are not marshalable in this phase"
		if $fn->{_is_method};
	die "Native functions do not have ZuzuScript source"
		if $fn->{_native};

	my $addr = refaddr($fn);
	die "Function code value has no stable identity" if !defined $addr;

	return $state->{code_ids}{$addr}
		if exists $state->{code_ids}{$addr};

	my $id = scalar @{ $state->{code} };
	$state->{code_ids}{$addr} = $id;
	push @{ $state->{code} }, undef;

	my $binding_name = _function_code_binding_name(
		$fn,
		$state,
		$id,
		$preferred_name,
	);
	$state->{code_names}{$binding_name} = 1;

	my $analysis = _analyse_function_value( $runtime, $fn );
	my @captures = map {
		[
			text_string( $_->{name} ),
			_encode_scalar_value( $runtime, $_->{value} ),
		]
	} @{ $analysis->{captures} };
	my @dependencies;
	for my $dependency ( @{ $analysis->{internal_dependencies} } ) {
		push @dependencies, _encode_code_dependency(
			$runtime,
			$dependency,
			$state,
		);
	}
	for my $dependency ( @{ $analysis->{external_dependencies} } ) {
		push @dependencies, [
			1,
			text_string( $dependency->{local_name} ),
			text_string( $dependency->{module} ),
			text_string( $dependency->{export_name} ),
		];
	}

	$state->{code}[$id] = [
		CODE_FUNCTION,
		text_string($binding_name),
		text_string( $analysis->{source} ),
		\@captures,
		\@dependencies,
	];

	return $id;
}

sub _encode_class_code {
	my ( $runtime, $class_value, $state, $preferred_name ) = @_;

	die "Class dependency is not a Class value"
		if !blessed($class_value) or !$class_value->isa('Zuzu::Value::Class');
	die "Native classes do not have ZuzuScript source"
		if $class_value->native_constructor or $class_value->builtin_kind;

	my $addr = refaddr($class_value);
	die "Class code value has no stable identity" if !defined $addr;

	return $state->{code_ids}{$addr}
		if exists $state->{code_ids}{$addr};

	my $analysis = _analyse_class_value( $runtime, $class_value );

	my $id = scalar @{ $state->{code} };
	$state->{code_ids}{$addr} = $id;
	push @{ $state->{code} }, undef;

	my $binding_name = _class_code_binding_name(
		$class_value,
		$state,
		$id,
		$preferred_name,
	);
	$state->{code_names}{$binding_name} = 1;

	my @captures = map {
		[
			text_string( $_->{name} ),
			_encode_scalar_value( $runtime, $_->{value} ),
		]
	} @{ $analysis->{captures} };
	my @dependencies;
	for my $dependency ( @{ $analysis->{internal_dependencies} } ) {
		push @dependencies, _encode_code_dependency(
			$runtime,
			$dependency,
			$state,
		);
	}
	for my $dependency ( @{ $analysis->{external_dependencies} } ) {
		push @dependencies, [
			1,
			text_string( $dependency->{local_name} ),
			text_string( $dependency->{module} ),
			text_string( $dependency->{export_name} ),
		];
	}

	$state->{code}[$id] = [
		CODE_CLASS,
		text_string($binding_name),
		text_string( $analysis->{source} ),
		\@captures,
		\@dependencies,
	];

	return $id;
}

sub _encode_trait_code {
	my ( $runtime, $trait_value, $state, $preferred_name ) = @_;

	die "Trait dependency is not a Trait value"
		if !blessed($trait_value) or !$trait_value->isa('Zuzu::Value::Trait');

	my $addr = refaddr($trait_value);
	die "Trait code value has no stable identity" if !defined $addr;

	return $state->{code_ids}{$addr}
		if exists $state->{code_ids}{$addr};

	my $analysis = _analyse_trait_value( $runtime, $trait_value );

	my $id = scalar @{ $state->{code} };
	$state->{code_ids}{$addr} = $id;
	push @{ $state->{code} }, undef;

	my $binding_name = _trait_code_binding_name(
		$trait_value,
		$state,
		$id,
		$preferred_name,
	);
	$state->{code_names}{$binding_name} = 1;

	my @captures = map {
		[
			text_string( $_->{name} ),
			_encode_scalar_value( $runtime, $_->{value} ),
		]
	} @{ $analysis->{captures} };
	my @dependencies;
	for my $dependency ( @{ $analysis->{internal_dependencies} } ) {
		push @dependencies, _encode_code_dependency(
			$runtime,
			$dependency,
			$state,
		);
	}
	for my $dependency ( @{ $analysis->{external_dependencies} } ) {
		push @dependencies, [
			1,
			text_string( $dependency->{local_name} ),
			text_string( $dependency->{module} ),
			text_string( $dependency->{export_name} ),
		];
	}

	$state->{code}[$id] = [
		CODE_TRAIT,
		text_string($binding_name),
		text_string( $analysis->{source} ),
		\@captures,
		\@dependencies,
	];

	return $id;
}

sub _encode_code_dependency {
	my ( $runtime, $dependency, $state ) = @_;

	my $value = $dependency->{value};
	if ( blessed($value) and $value->isa('Zuzu::Value::Function') ) {
		return [
			0,
			_encode_function_code(
				$runtime,
				$value,
				$state,
				$dependency->{name},
			),
		];
	}
	if ( blessed($value) and $value->isa('Zuzu::Value::Class') ) {
		return [
			0,
			_encode_class_code(
				$runtime,
				$value,
				$state,
				$dependency->{name},
			),
		];
	}
	if ( blessed($value) and $value->isa('Zuzu::Value::Trait') ) {
		return [
			0,
			_encode_trait_code(
				$runtime,
				$value,
				$state,
				$dependency->{name},
			),
		];
	}
	die "Internal code dependency '$dependency->{name}' has unsupported type";
}

sub _function_code_binding_name {
	my ( $fn, $state, $id, $preferred_name ) = @_;

	for my $name ( $preferred_name, $fn->name ) {
		next if !defined $name;
		next if !_is_identifier($name);
		next if $state->{code_names}{$name};
		return $name;
	}

	my $name = "__zuzu_marshal_fn_$id";
	while ( $state->{code_names}{$name} ) {
		$id++;
		$name = "__zuzu_marshal_fn_$id";
	}

	return $name;
}

sub _class_code_binding_name {
	my ( $class_value, $state, $id, $preferred_name ) = @_;

	for my $name ( $preferred_name, $class_value->source_node->name ) {
		next if !defined $name;
		next if !_is_identifier($name);
		next if $state->{code_names}{$name};
		return $name;
	}

	my $name = "__zuzu_marshal_class_$id";
	while ( $state->{code_names}{$name} ) {
		$id++;
		$name = "__zuzu_marshal_class_$id";
	}

	return $name;
}

sub _trait_code_binding_name {
	my ( $trait_value, $state, $id, $preferred_name ) = @_;

	for my $name ( $preferred_name, $trait_value->source_node->name ) {
		next if !defined $name;
		next if !_is_identifier($name);
		next if $state->{code_names}{$name};
		return $name;
	}

	my $name = "__zuzu_marshal_trait_$id";
	while ( $state->{code_names}{$name} ) {
		$id++;
		$name = "__zuzu_marshal_trait_$id";
	}

	return $name;
}

sub _is_identifier {
	my ( $name ) = @_;

	return defined $name && $name =~ /\A[A-Za-z_][A-Za-z0-9_]*\z/;
}

sub _encode_object_value {
	my ( $runtime, $object, $state ) = @_;

	my $addr = refaddr($object);
	die "Object value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	_run_on_dump_hook( $runtime, $object, $state, $addr );

	my $native_constructor = $runtime->_native_constructor_for( $object->class );
	die "Runtime-backed object of type "
		. ( $object->class ? $object->class->name : '<unknown>' )
		. " is not marshalable in this phase"
		if $native_constructor;

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $class_ref = _encode_strong_value( $runtime, $object->class, $state );
	my @slot_names = sort keys %{ $object->slots // {} };
	for my $name ( @slot_names ) {
		next if $object->weak->{$name};
		_encode_strong_value(
			$runtime,
			slot_value( \$object->slots->{$name} ),
			$state,
		);
	}
	my @slots = map {
		my $weak = $object->weak->{$_} ? 1 : 0;
		[
			text_string($_),
			_encode_stored_value(
				$runtime,
				slot_value( \$object->slots->{$_} ),
				$state,
				$weak,
			),
		]
	} @slot_names;
	my $payload = [
		$class_ref,
		\@slots,
	];
	$state->{objects}[$id] = [ KIND_OBJECT, $payload ];

	return [ 0, $id ];
}

sub _hook_error_text {
	my ( $runtime, $error ) = @_;

	if ( ref($error) eq 'HASH' and $error->{_zuzu_throw} ) {
		my $value = $error->{value};
		my $text;
		local $@;
		eval {
			$text = $runtime->_to_String($value);
			1;
		} or do {
			$text = "$value";
		};

		if ( blessed($value) and $value->isa('Zuzu::Value::Object') ) {
			my $slots = $value->slots // {};
			my $file = $slots->{file};
			my $line = $slots->{line};
			$text .= " at $file, line $line"
				if defined $file and defined $line;
		}

		return $text;
	}

	return "$error";
}

sub _run_on_dump_hook {
	my ( $runtime, $object, $state, $addr ) = @_;

	return if $state->{on_dump}{$addr}++;

	my $method = $runtime->_lookup_method( $object->class, '__on_dump__', 0 );
	return if !$method;

	eval {
		$runtime->_call_method(
			$method,
			$object,
			[],
			{},
			[],
			_call_file($runtime),
			_call_line($runtime),
		);
		1;
	} or do {
		my $error = $@;
		my $class = $object->class ? $object->class->name : '<unknown>';
		die "__on_dump__ for $class failed: "
			. _hook_error_text( $runtime, $error );
	};

	return;
}

sub _is_time_value {
	my ( $runtime, $value ) = @_;

	return 0
		if !blessed($value)
		or !$value->isa('Zuzu::Value::Object')
		or !exists $value->slots->{_epoch};

	return _object_is_module_class( $runtime, $value, 'std/time', 'Time' );
}

sub _is_path_value {
	my ( $runtime, $value ) = @_;

	return 0
		if !blessed($value)
		or !$value->isa('Zuzu::Value::Object')
		or !exists $value->slots->{_path_tiny};

	return _object_is_module_class( $runtime, $value, 'std/io', 'Path' );
}

sub _encode_time_value {
	my ( $runtime, $time, $state ) = @_;

	my $addr = refaddr($time);
	die "Time value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $epoch = $time->slots->{_epoch};
	my @payload = ( _number_to_cbor($epoch) );
	push @payload, text_string( $time->slots->{_timezone} )
		if exists $time->slots->{_timezone};
	$state->{objects}[$id] = [ KIND_TIME, \@payload ];

	return [ 0, $id ];
}

sub _encode_path_value {
	my ( $runtime, $path_value, $state ) = @_;

	my $addr = refaddr($path_value);
	die "Path value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my $path_obj = $path_value->slots->{_path_tiny};
	die "Path value has invalid internal path"
		if !defined $path_obj or !ref($path_obj) or !$path_obj->can('stringify');
	$state->{objects}[$id] = [
		KIND_PATH,
		[ text_string( $path_obj->stringify ) ],
	];

	return [ 0, $id ];
}

sub _encode_array_value {
	my ( $runtime, $array, $state ) = @_;

	my $addr = refaddr($array);
	die "Array value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	for ( my $i = 0; $i < @{ $array->items // [] }; $i++ ) {
		next if $array->weak->[$i];
		_encode_strong_value( $runtime, $array->_value_at($i), $state );
	}
	my @payload = map {
		my $weak = $array->weak->[$_] ? 1 : 0;
		_encode_stored_value(
			$runtime,
			$array->_value_at($_),
			$state,
			$weak,
		);
	} 0 .. $#{ $array->items // [] };

	$state->{objects}[$id] = [ KIND_ARRAY, \@payload ];

	return [ 0, $id ];
}

sub _encode_dict_value {
	my ( $runtime, $dict, $state ) = @_;

	my $addr = refaddr($dict);
	die "Dict value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	my @keys = sort keys %{ $dict->map // {} };
	for my $key ( @keys ) {
		next if $dict->weak->{$key};
		_encode_strong_value( $runtime, $dict->_value_for_key($key), $state );
	}
	my @payload = map {
		my $weak = $dict->weak->{$_} ? 1 : 0;
		[
			text_string($_),
			_encode_stored_value(
				$runtime,
				$dict->_value_for_key($_),
				$state,
				$weak,
			),
		]
	} @keys;

	$state->{objects}[$id] = [ KIND_DICT, \@payload ];

	return [ 0, $id ];
}

sub _encode_pairlist_value {
	my ( $runtime, $pairlist, $state ) = @_;

	my $addr = refaddr($pairlist);
	die "PairList value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	for ( my $i = 0; $i < @{ $pairlist->list // [] }; $i++ ) {
		next if $pairlist->weak->[$i];
		_encode_strong_value( $runtime, $pairlist->_value_at($i), $state );
	}
	my @payload = map {
		my $weak = $pairlist->weak->[$_] ? 1 : 0;
		[
			text_string( $pairlist->list->[$_][0] ),
			_encode_stored_value(
				$runtime,
				$pairlist->_value_at($_),
				$state,
				$weak,
			),
		]
	} 0 .. $#{ $pairlist->list // [] };

	$state->{objects}[$id] = [ KIND_PAIRLIST, \@payload ];

	return [ 0, $id ];
}

sub _encode_set_value {
	my ( $runtime, $set, $state ) = @_;

	my $addr = refaddr($set);
	die "Set value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	for ( my $i = 0; $i < @{ $set->items // [] }; $i++ ) {
		next if $set->weak->[$i];
		_encode_strong_value( $runtime, $set->_value_at($i), $state );
	}
	my @payload = map {
		my $weak = $set->weak->[$_] ? 1 : 0;
		_encode_stored_value(
			$runtime,
			$set->_value_at($_),
			$state,
			$weak,
		);
	} 0 .. $#{ $set->items // [] };

	$state->{objects}[$id] = [ KIND_SET, \@payload ];

	return [ 0, $id ];
}

sub _encode_bag_value {
	my ( $runtime, $bag, $state ) = @_;

	my $addr = refaddr($bag);
	die "Bag value has no stable identity" if !defined $addr;

	if ( exists $state->{strong_ids}{$addr} ) {
		my $id = $state->{strong_ids}{$addr};
		return [ 0, $id ];
	}

	my $id = scalar @{ $state->{objects} };
	$state->{strong_ids}{$addr} = $id;
	push @{ $state->{objects} }, undef;

	for ( my $i = 0; $i < @{ $bag->items // [] }; $i++ ) {
		next if $bag->weak->[$i];
		_encode_strong_value( $runtime, $bag->_value_at($i), $state );
	}
	my @payload = map {
		my $weak = $bag->weak->[$_] ? 1 : 0;
		_encode_stored_value(
			$runtime,
			$bag->_value_at($_),
			$state,
			$weak,
		);
	} 0 .. $#{ $bag->items // [] };

	$state->{objects}[$id] = [ KIND_BAG, \@payload ];

	return [ 0, $id ];
}

sub _encode_envelope {
	my ( $runtime, $value ) = @_;

	my $state = _new_dump_state();
	my $root = _encode_strong_value( $runtime, $value, $state );
	return tag(
		55799,
		[
			text_string('ZUZU-MARSHAL'),
			1,
			{},
			$root,
			$state->{objects},
			$state->{code},
		],
	);
}

sub _decode_envelope {
	my ( $runtime, $decoded ) = @_;

	die "Top-level item is not tag 55799"
		if !is_tagged($decoded) or tag_number($decoded) != 55799;

	my $envelope = tag_value($decoded);
	die "Envelope must be an array"
		if ref($envelope) ne 'ARRAY';
	die "Envelope must contain exactly 6 fields"
		if scalar @{ $envelope } != 6;

	my ( $magic, $version, $options, $root, $objects, $code ) =
		@{ $envelope };

	die "Envelope magic is invalid"
		if !is_text_string($magic) or text_value($magic) ne 'ZUZU-MARSHAL';
	die "Unsupported Zuzu Marshal version"
		if ref($version) or $version != 1;
	die "Envelope options must be a map"
		if ref($options) ne 'HASH';
	die "Envelope object table must be an array"
		if ref($objects) ne 'ARRAY';
	die "Envelope code table must be an array"
		if ref($code) ne 'ARRAY';

	my $code_values = _load_code_table( $runtime, $code );
	my $placeholders = _allocate_object_placeholders(
		$runtime,
		$objects,
		$code_values,
	);
	_fill_object_placeholders( $runtime, $objects, $placeholders );
	my $value = _decode_value(
		$runtime,
		$root,
		$placeholders,
		allow_weak => 0,
		context => 'Envelope root',
	);
	_run_on_load_hooks( $runtime, $objects, $placeholders );

	return $value;
}

sub _allocate_object_placeholders {
	my ( $runtime, $objects, $code_values ) = @_;

	my @placeholders;
	for my $id ( 0 .. $#{ $objects } ) {
		my $entry = $objects->[$id];
		die "Object table entry $id must be a two-item array"
			if ref($entry) ne 'ARRAY' or scalar @{ $entry } != 2;

		my ( $kind ) = @{ $entry };
		die "Object table entry $id kind must be an integer"
			if !_is_integer_value($kind);
		if ( $kind == KIND_PAIR ) {
			my $pair_array = Zuzu::Value::Array->new( items => [] );
			$placeholders[$id] = $runtime->_instantiate_builtin_object(
				$runtime->{_builtin_classes}{Pair},
				{
					pair => $pair_array,
				},
			);
			next;
		}
		if ( $kind == KIND_ARRAY ) {
			$placeholders[$id] = Zuzu::Value::Array->new( items => [] );
			next;
		}
		if ( $kind == KIND_DICT ) {
			$placeholders[$id] = Zuzu::Value::Dict->new( map => {} );
			next;
		}
		if ( $kind == KIND_PAIRLIST ) {
			$placeholders[$id] = Zuzu::Value::PairList->new( list => [] );
			next;
		}
		if ( $kind == KIND_SET ) {
			$placeholders[$id] = Zuzu::Value::Set->new( items => [] );
			next;
		}
		if ( $kind == KIND_BAG ) {
			$placeholders[$id] = Zuzu::Value::Bag->new( items => [] );
			next;
		}
		if ( $kind == KIND_OBJECT ) {
			$placeholders[$id] = Zuzu::Value::Object->new(
				class => undef,
				slots => {},
				const => {},
				types => {},
				weak => {},
			);
			next;
		}
		if ( $kind == KIND_FUNCTION ) {
			$placeholders[$id] = _decode_function_payload(
				$runtime,
				$id,
				$entry->[1],
				$code_values,
			);
			next;
		}
		if ( $kind == KIND_CLASS ) {
			$placeholders[$id] =
				_decode_class_payload(
					$runtime,
					$id,
					$entry->[1],
					$code_values,
			);
			next;
		}
		if ( $kind == KIND_TRAIT ) {
			$placeholders[$id] = _decode_trait_payload(
				$runtime,
				$id,
				$entry->[1],
				$code_values,
			);
			next;
		}
		if ( $kind == KIND_BOUND_METHOD ) {
			$placeholders[$id] = Zuzu::Value::Function->new(
				name => '<pending bound method>',
				params => [],
				body => undef,
				closure_env => undef,
			);
			$placeholders[$id]{_is_method} = 1;
			next;
		}
		if ( $kind == KIND_TIME ) {
			$placeholders[$id] = _new_time_placeholder($runtime);
			next;
		}
		if ( $kind == KIND_PATH ) {
			$placeholders[$id] = _new_path_placeholder($runtime);
			next;
		}
		die "Unsupported object kind $kind in current loader";
	}

	return \@placeholders;
}

sub _fill_object_placeholders {
	my ( $runtime, $objects, $placeholders ) = @_;

	for my $id ( 0 .. $#{ $objects } ) {
		my ( $kind, $payload ) = @{ $objects->[$id] };
		if ( $kind == KIND_PAIR ) {
			die "Pair object payload $id must be a two-item array"
				if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 2;
			my ( $key, $value ) = @{ $payload };
			die "Pair object payload $id key must be a text string"
				if !is_text_string($key);
			my ( $decoded_value, $weak ) = _decode_stored_value(
				$runtime,
				$value,
				$placeholders,
				"Pair object payload $id value",
			);
			my $pair_array = _pair_slot_array( $placeholders->[$id] );
			$pair_array->_store_at( 0, text_value($key), 0 );
			$pair_array->_store_at( 1, $decoded_value, $weak );
			next;
		}
		if ( $kind == KIND_ARRAY ) {
			die "Array object payload $id must be an array"
				if ref($payload) ne 'ARRAY';
			my $array = $placeholders->[$id];
			$array->items( [] );
			$array->weak( [] );
			for my $encoded ( @{ $payload } ) {
				my ( $value, $weak ) = _decode_stored_value(
					$runtime,
					$encoded,
					$placeholders,
					"Array object payload $id item",
				);
				$array->_store_at( $array->length, $value, $weak );
			}
			next;
		}
		if ( $kind == KIND_DICT ) {
			my ( $map, $weak ) = _decode_dict_payload(
				$runtime,
				$id,
				$payload,
				$placeholders,
			);
			$placeholders->[$id]->map($map);
			$placeholders->[$id]->weak($weak);
			next;
		}
		if ( $kind == KIND_PAIRLIST ) {
			my ( $list, $weak ) = _decode_pairlist_payload(
				$runtime,
				$id,
				$payload,
				$placeholders,
			);
			$placeholders->[$id]->list($list);
			$placeholders->[$id]->weak($weak);
			next;
		}
		if ( $kind == KIND_SET ) {
			my $set = $placeholders->[$id];
			my @items = _decode_item_payload_records(
				$runtime,
				"Set object payload $id",
				$payload,
				$placeholders,
			);
			for my $record ( @items ) {
				my ( $value, $weak ) = @{ $record };
				my $index = $set->length;
				$set->_store_at( $index, $value, $weak );
			}
			$set->_uniq;
			next;
		}
		if ( $kind == KIND_BAG ) {
			my @items = _decode_item_payload_records(
				$runtime,
				"Bag object payload $id",
				$payload,
				$placeholders,
			);
			my $bag = $placeholders->[$id];
			$bag->items( [] );
			$bag->weak( [] );
			for my $record ( @items ) {
				my ( $value, $weak ) = @{ $record };
				$bag->_store_at( $bag->length, $value, $weak );
			}
			next;
		}
		if ( $kind == KIND_OBJECT ) {
			_fill_object_payload(
				$runtime,
				$id,
				$payload,
				$placeholders,
			);
			next;
		}
		if ( $kind == KIND_FUNCTION ) {
			next;
		}
		if ( $kind == KIND_CLASS ) {
			next;
		}
		if ( $kind == KIND_TRAIT ) {
			next;
		}
		if ( $kind == KIND_BOUND_METHOD ) {
			next;
		}
		if ( $kind == KIND_TIME ) {
			my ( $epoch, $timezone ) = _decode_time_payload( $id, $payload );
			$placeholders->[$id]->slots->{_epoch} = $epoch;
			$placeholders->[$id]->slots->{_timezone} = $timezone;
			next;
		}
		if ( $kind == KIND_PATH ) {
			$placeholders->[$id]->slots->{_path_tiny} =
				path( _decode_path_payload( $id, $payload ) );
			next;
		}
		die "Unsupported object kind $kind in current loader";
	}

	_fill_bound_method_placeholders( $runtime, $objects, $placeholders );
}

sub _load_code_table {
	my ( $runtime, $code ) = @_;

	my $shared = Zuzu::Env->new( parent => undef );
	for my $name ( sort keys %{ $runtime->{_builtin_global_names} // {} } ) {
		my $ref = $runtime->{_global}->find_ref($name);
		next if !defined $ref;
		$shared->alias_to_ref(
			$name,
			$ref,
			$runtime->{_global}{const}{$name} ? 1 : 0,
			$runtime->{_global}{types}{$name} // 'Any',
		);
	}

	my @records;
	my @refs;
	my %code_names;
	for my $id ( 0 .. $#{ $code } ) {
		my $record = _validate_code_record( $id, $code->[$id] );
		die "Unsupported code kind $record->{kind} in current loader"
			if $record->{kind} != CODE_FUNCTION
			and $record->{kind} != CODE_CLASS
			and $record->{kind} != CODE_TRAIT;
		die "Duplicate code binding '$record->{binding_name}'"
			if $code_names{ $record->{binding_name} }++;
		my $ref = $shared->declare( $record->{binding_name}, undef, 1 );
		$refs[$id] = $ref;
		$records[$id] = $record;
	}

	for my $id ( 0 .. $#records ) {
		_install_external_dependencies(
			$runtime,
			$shared,
			$id,
			$records[$id],
			scalar(@records),
		);
	}

	my @values;
	my @status;
	for my $id ( 0 .. $#records ) {
		_load_code_record_by_id(
			$runtime,
			$shared,
			\@records,
			\@refs,
			\@values,
			\@status,
			$id,
		);
	}

	return \@values;
}

sub _validate_code_record {
	my ( $id, $record ) = @_;

	die "Code table entry $id must be a five-item array"
		if ref($record) ne 'ARRAY' or scalar @{ $record } != 5;
	my ( $kind, $binding_name, $source, $captures, $dependencies ) =
		@{ $record };
	die "Code table entry $id kind must be an integer"
		if !_is_integer_value($kind);
	die "Code table entry $id binding name must be a text string"
		if !is_text_string($binding_name);
	$binding_name = text_value($binding_name);
	die "Code table entry $id binding name is not a valid identifier"
		if !_is_identifier($binding_name);
	die "Code table entry $id source must be a text string"
		if !is_text_string($source);
	die "Code table entry $id captures must be an array"
		if ref($captures) ne 'ARRAY';
	die "Code table entry $id dependencies must be an array"
		if ref($dependencies) ne 'ARRAY';

	return {
		kind => $kind,
		binding_name => $binding_name,
		source => text_value($source),
		captures => $captures,
		dependencies => $dependencies,
	};
}

sub _install_external_dependencies {
	my ( $runtime, $shared, $id, $record, $record_count ) = @_;

	for my $dependency ( @{ $record->{dependencies} } ) {
		die "Code dependency in record $id must be an array"
			if ref($dependency) ne 'ARRAY' or !@{ $dependency };
		my $kind = $dependency->[0];
		die "Code dependency in record $id kind must be an integer"
			if !_is_integer_value($kind);
		if ( $kind == 0 ) {
			die "Internal dependency in record $id must be [0, code_id]"
				if scalar @{ $dependency } != 2;
			my $code_id = $dependency->[1];
			die "Internal dependency in record $id has invalid code id"
				if !_is_integer_value($code_id)
				or $code_id < 0
				or $code_id >= $record_count;
			next;
		}
		if ( $kind == 1 ) {
			_install_external_dependency(
				$runtime,
				$shared,
				$id,
				$dependency,
			);
			next;
		}
		die "Unsupported code dependency kind $kind in record $id";
	}

	return;
}

sub _install_external_dependency {
	my ( $runtime, $shared, $id, $dependency ) = @_;

	die "External dependency in record $id must have four fields"
		if scalar @{ $dependency } != 4;
	my ( undef, $local_name, $module, $export_name ) = @{ $dependency };
	for my $field (
		[ local_name => \$local_name ],
		[ module => \$module ],
		[ export_name => \$export_name ],
	) {
		die "External dependency $field->[0] in record $id must be text"
			if !is_text_string( ${ $field->[1] } );
		${ $field->[1] } = text_value( ${ $field->[1] } );
	}
	die "External dependency local name '$local_name' is not valid"
		if !_is_identifier($local_name);
	die "External dependency module '$module' is not a stdlib module"
		if $module !~ m{\Astd/};

	my $module_env = $runtime->_load_module(
		$module,
		_call_file($runtime),
		_call_line($runtime),
	);
	my $ref = $module_env->find_ref($export_name);
	die "External dependency '$module.$export_name' is not exported"
		if !defined $ref;
	if ( exists $shared->slots->{$local_name} ) {
		die "External dependency '$local_name' conflicts with code binding"
			if $shared->slots->{$local_name} != $ref;
		return;
	}
	$shared->alias_to_ref(
		$local_name,
		$ref,
		$module_env->{const}{$export_name} ? 1 : 0,
		$module_env->{types}{$export_name} // 'Any',
	);

	return;
}

sub _load_code_record_by_id {
	my ( $runtime, $shared, $records, $refs, $values, $status, $id ) = @_;

	die "Internal dependency has invalid code id"
		if !_is_integer_value($id) or $id < 0 or $id > $#{ $records };
	return $values->[$id] if ( $status->[$id] // '' ) eq 'done';
	die "Cyclic class or trait code dependency involving record $id"
		if ( $status->[$id] // '' ) eq 'loading';

	my $record = $records->[$id];
	$status->[$id] = 'loading';
	if ( $record->{kind} == CODE_CLASS or $record->{kind} == CODE_TRAIT ) {
		for my $dependency ( @{ $record->{dependencies} } ) {
			next if $dependency->[0] != 0;
			my $dependency_id = $dependency->[1];
			die "Internal dependency in record $id has invalid code id"
				if !_is_integer_value($dependency_id)
				or $dependency_id < 0
				or $dependency_id > $#{ $records };
			next if $records->[$dependency_id]{kind} == CODE_FUNCTION;
			_load_code_record_by_id(
				$runtime,
				$shared,
				$records,
				$refs,
				$values,
				$status,
				$dependency_id,
			);
		}
	}

	my $value = _load_code_record( $runtime, $shared, $id, $record );
	${ $refs->[$id] } = $value;
	$values->[$id] = $value;
	$status->[$id] = 'done';

	return $value;
}

sub _load_code_record {
	my ( $runtime, $shared, $id, $record ) = @_;

	return _load_function_code_record( $runtime, $shared, $id, $record )
		if $record->{kind} == CODE_FUNCTION;
	return _load_class_code_record( $runtime, $shared, $id, $record )
		if $record->{kind} == CODE_CLASS;
	return _load_trait_code_record( $runtime, $shared, $id, $record )
		if $record->{kind} == CODE_TRAIT;

	die "Unsupported code kind $record->{kind} in current loader";
}

sub _load_function_code_record {
	my ( $runtime, $shared, $id, $record ) = @_;

	my $private = Zuzu::Env->new( parent => $shared );
	my %capture_names;
	for my $capture ( @{ $record->{captures} } ) {
		die "Capture in code record $id must be a two-item array"
			if ref($capture) ne 'ARRAY' or scalar @{ $capture } != 2;
		my ( $name, $value ) = @{ $capture };
		die "Capture name in code record $id must be a text string"
			if !is_text_string($name);
		$name = text_value($name);
		die "Capture name '$name' in code record $id is not valid"
			if !_is_identifier($name);
		die "Duplicate capture '$name' in code record $id"
			if $capture_names{$name}++;
		_reject_weak_storage_record(
			$value,
			"Capture '$name' in code record $id",
		);
		$private->declare(
			$name,
			_decode_scalar_value( $runtime, $value ),
			1,
		);
	}

	my $result_name = "__zuzu_marshal_value_$id";
	while ( defined $private->find_ref($result_name) ) {
		$result_name = '_' . $result_name;
	}
	my $source = "let $result_name := "
		. $record->{source}
		. "; $result_name;";
	my $value;
	eval {
		$runtime->_push_env($private);
		$value = $runtime->eval_with_current_scope(
			$source,
			'<std/marshal-code>',
		);
		1;
	} or do {
		my $error = $@;
		$runtime->_pop_env;
		die $error;
	};
	$runtime->_pop_env;

	die "Code record $id did not evaluate to a Function"
		if !blessed($value) or !$value->isa('Zuzu::Value::Function');

	return $value;
}

sub _load_class_code_record {
	my ( $runtime, $shared, $id, $record ) = @_;

	my $parent = _shared_code_env_without(
		$shared,
		$record->{binding_name},
	);
	my $private = _private_code_env_with_captures(
		$runtime,
		$parent,
		$id,
		$record,
	);
	my $value;
	eval {
		$runtime->_push_env($private);
		$value = $runtime->eval_with_current_scope(
			$record->{source},
			'<std/marshal-code>',
		);
		1;
	} or do {
		my $error = $@;
		$runtime->_pop_env;
		die $error;
	};
	$runtime->_pop_env;

	die "Code record $id did not evaluate to a Class"
		if !blessed($value) or !$value->isa('Zuzu::Value::Class');

	return $value;
}

sub _load_trait_code_record {
	my ( $runtime, $shared, $id, $record ) = @_;

	my $parent = _shared_code_env_without(
		$shared,
		$record->{binding_name},
	);
	my $private = _private_code_env_with_captures(
		$runtime,
		$parent,
		$id,
		$record,
	);
	my $value;
	eval {
		$runtime->_push_env($private);
		$value = $runtime->eval_with_current_scope(
			$record->{source},
			'<std/marshal-code>',
		);
		1;
	} or do {
		my $error = $@;
		$runtime->_pop_env;
		die $error;
	};
	$runtime->_pop_env;

	die "Code record $id did not evaluate to a Trait"
		if !blessed($value) or !$value->isa('Zuzu::Value::Trait');

	return $value;
}

sub _shared_code_env_without {
	my ( $shared, $hidden_name ) = @_;

	my $filtered = Zuzu::Env->new( parent => undef );
	for my $name ( sort keys %{ $shared->slots } ) {
		next if $name eq $hidden_name;
		$filtered->alias_to_ref(
			$name,
			$shared->slots->{$name},
			$shared->const->{$name} ? 1 : 0,
			$shared->types->{$name} // 'Any',
		);
	}

	return $filtered;
}

sub _private_code_env_with_captures {
	my ( $runtime, $shared, $id, $record ) = @_;

	my $private = Zuzu::Env->new( parent => $shared );
	my %capture_names;
	for my $capture ( @{ $record->{captures} } ) {
		die "Capture in code record $id must be a two-item array"
			if ref($capture) ne 'ARRAY' or scalar @{ $capture } != 2;
		my ( $name, $value ) = @{ $capture };
		die "Capture name in code record $id must be a text string"
			if !is_text_string($name);
		$name = text_value($name);
		die "Capture name '$name' in code record $id is not valid"
			if !_is_identifier($name);
		die "Duplicate capture '$name' in code record $id"
			if $capture_names{$name}++;
		_reject_weak_storage_record(
			$value,
			"Capture '$name' in code record $id",
		);
		$private->declare(
			$name,
			_decode_scalar_value( $runtime, $value ),
			1,
		);
	}

	return $private;
}

sub _decode_function_payload {
	my ( $runtime, $id, $payload, $code_values ) = @_;

	die "Function object payload $id must be a one-item array"
		if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 1;
	my $code_id = $payload->[0];
	_reject_weak_storage_record(
		$code_id,
		"Function object payload $id code id",
	);
	die "Function object payload $id code id must be an integer"
		if !_is_integer_value($code_id);
	die "Function object payload $id code id is outside the code table"
		if $code_id < 0 or $code_id > $#{ $code_values };

	my $value = $code_values->[$code_id];
	die "Function object payload $id code record is not a Function"
		if !blessed($value) or !$value->isa('Zuzu::Value::Function');

	return $value;
}

sub _decode_class_payload {
	my ( $runtime, $id, $payload, $code_values ) = @_;

	die "Class object payload $id must be a one-item array"
		if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 1;
	my $code_id = $payload->[0];
	_reject_weak_storage_record(
		$code_id,
		"Class object payload $id code id",
	);
	die "Class object payload $id code id must be an integer"
		if !_is_integer_value($code_id);
	die "Class object payload $id code id is outside the code table"
		if $code_id < 0 or $code_id > $#{ $code_values };

	my $class = $code_values->[$code_id];
	die "Class object payload $id code record is not a Class"
		if !blessed($class) or !$class->isa('Zuzu::Value::Class');

	return $class;
}

sub _decode_trait_payload {
	my ( $runtime, $id, $payload, $code_values ) = @_;

	die "Trait object payload $id must be a one-item array"
		if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 1;
	my $code_id = $payload->[0];
	_reject_weak_storage_record(
		$code_id,
		"Trait object payload $id code id",
	);
	die "Trait object payload $id code id must be an integer"
		if !_is_integer_value($code_id);
	die "Trait object payload $id code id is outside the code table"
		if $code_id < 0 or $code_id > $#{ $code_values };

	my $trait = $code_values->[$code_id];
	die "Trait object payload $id code record is not a Trait"
		if !blessed($trait) or !$trait->isa('Zuzu::Value::Trait');

	return $trait;
}

sub _fill_bound_method_placeholders {
	my ( $runtime, $objects, $placeholders ) = @_;

	for my $id ( 0 .. $#{ $objects } ) {
		my ( $kind, $payload ) = @{ $objects->[$id] };
		next if $kind != KIND_BOUND_METHOD;

		my $bound = _decode_bound_method_payload(
			$runtime,
			$id,
			$payload,
			$placeholders,
		);
		_replace_function_value( $placeholders->[$id], $bound );
	}

	return;
}

sub _decode_bound_method_payload {
	my ( $runtime, $id, $payload, $placeholders ) = @_;

	die "Bound method object payload $id must be a two-item array"
		if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 2;
	my ( $receiver_ref, $method_name ) = @{ $payload };
	my $receiver = _decode_value(
		$runtime,
		$receiver_ref,
		$placeholders,
		allow_weak => 0,
		context => "Bound method object payload $id receiver",
	);
	die "Bound method object payload $id receiver must resolve to an Object"
		if !blessed($receiver) or !$receiver->isa('Zuzu::Value::Object');
	die "Bound method object payload $id method name must be a text string"
		if !is_text_string($method_name);
	$method_name = text_value($method_name);

	my $method = $runtime->_lookup_method( $receiver->class, $method_name, 0 );
	die "Bound method object payload $id method '$method_name' was not found"
		if !$method;

	return $runtime->_bind_method( $receiver, $method_name, $method );
}

sub _replace_function_value {
	my ( $target, $source ) = @_;

	%{ $target } = %{ $source };

	return;
}

sub _fill_object_payload {
	my ( $runtime, $id, $payload, $placeholders ) = @_;

	die "Object payload $id must be a two-item array"
		if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 2;

	my ( $class_ref, $slot_payload ) = @{ $payload };
	my $class = _decode_value(
		$runtime,
		$class_ref,
		$placeholders,
		allow_weak => 0,
		context => "Object payload $id class",
	);
	die "Object payload $id class must resolve to a Class"
		if !blessed($class) or !$class->isa('Zuzu::Value::Class');
	die "Object payload $id slots must be an array"
		if ref($slot_payload) ne 'ARRAY';

	my ( $slots, $const, $types, $weak ) = $runtime->_instantiate_slots($class);
	my %slot_names;
	for my $record ( @{ $slot_payload } ) {
		die "Object payload $id slot records must be two-item arrays"
			if ref($record) ne 'ARRAY' or scalar @{ $record } != 2;
		my ( $name, $encoded_value ) = @{ $record };
		die "Object payload $id slot names must be text strings"
			if !is_text_string($name);
		$name = text_value($name);
		die "Object payload $id contains duplicate slot '$name'"
			if $slot_names{$name}++;
		my ( $value, $record_weak ) = _decode_stored_value(
			$runtime,
			$encoded_value,
			$placeholders,
			"Object payload $id slot '$name'",
		);
		my $declared_type = exists $types->{$name} ? $types->{$name} : 'Any';
		$runtime->_assert_declared_type(
			$declared_type,
			$value,
			_call_file($runtime),
			_call_line($runtime),
			$name,
		) if $declared_type ne 'Any';
		my $is_weak = ( $weak->{$name} || $record_weak ) ? 1 : 0;
		store_value( \$slots->{$name}, $value, $is_weak );
		$weak->{$name} = $is_weak;
		$const->{$name} = 0 if !exists $const->{$name};
		$types->{$name} = 'Any' if !exists $types->{$name};
	}

	my $object = $placeholders->[$id];
	$object->class($class);
	$object->slots($slots);
	$object->const($const);
	$object->types($types);
	$object->weak($weak);

	return;
}

sub _run_on_load_hooks {
	my ( $runtime, $objects, $placeholders ) = @_;

	for my $id ( 0 .. $#{ $objects } ) {
		my ( $kind ) = @{ $objects->[$id] };
		next if $kind != KIND_OBJECT;

		my $object = $placeholders->[$id];
		my $method = $runtime->_lookup_method(
			$object->class,
			'__on_load__',
			0,
		);
		next if !$method;

		eval {
			$runtime->_call_method(
				$method,
				$object,
				[],
				{},
				[],
				_call_file($runtime),
				_call_line($runtime),
			);
			1;
		} or do {
			my $error = $@;
			my $class = $object->class ? $object->class->name : '<unknown>';
			die "__on_load__ for object id $id ($class) failed: "
				. _hook_error_text( $runtime, $error );
		};
	}

	return;
}

sub _new_time_placeholder {
	my ( $runtime ) = @_;

	my $time_class = _module_symbol( $runtime, 'std/time', 'Time' );
	return $time_class->native_constructor->(
		$runtime,
		$time_class,
		[ 0 ],
		{},
		_call_file($runtime),
		_call_line($runtime),
	);
}

sub _new_path_placeholder {
	my ( $runtime ) = @_;

	my $path_class = _module_symbol( $runtime, 'std/io', 'Path' );
	return $path_class->native_constructor->(
		$runtime,
		$path_class,
		[ '.' ],
		{},
		_call_file($runtime),
		_call_line($runtime),
	);
}

sub _decode_time_payload {
	my ( $id, $payload ) = @_;

	die "Time object payload $id must contain epoch and optional timezone"
		if ref($payload) ne 'ARRAY'
		or scalar @{ $payload } < 1
		or scalar @{ $payload } > 2;
	my $epoch = $payload->[0];
	die "Time object payload $id epoch must be a number"
		if ref($epoch);
	my $timezone = 'UTC';
	if ( scalar @{ $payload } > 1 ) {
		die "Time object payload $id timezone must be a text string"
			if !is_text_string( $payload->[1] );
		$timezone = text_value( $payload->[1] );
	}

	return ( 0 + $epoch, $timezone );
}

sub _decode_path_payload {
	my ( $id, $payload ) = @_;

	die "Path object payload $id must be a one-item array"
		if ref($payload) ne 'ARRAY' or scalar @{ $payload } != 1;
	my $path_value = $payload->[0];
	die "Path object payload $id path must be a text string"
		if !is_text_string($path_value);

	return text_value($path_value);
}

sub _decode_item_payload_records {
	my ( $runtime, $context, $payload, $placeholders ) = @_;

	die "$context must be an array"
		if ref($payload) ne 'ARRAY';

	return map {
		my ( $value, $weak ) = _decode_stored_value(
			$runtime,
			$_,
			$placeholders,
			"$context item",
		);
		[ $value, $weak ];
	} @{ $payload };
}

sub _decode_dict_payload {
	my ( $runtime, $id, $payload, $placeholders ) = @_;

	die "Dict object payload $id must be an array"
		if ref($payload) ne 'ARRAY';

	my %map;
	my %weak;
	for my $pair ( @{ $payload } ) {
		my ( $key, $value, $is_weak ) = _decode_key_value_record(
			$runtime,
			"Dict object payload $id",
			$pair,
			$placeholders,
		);
		die "Dict object payload $id contains duplicate key '$key'"
			if exists $map{$key};
		$map{$key} = undef;
		store_value( \$map{$key}, $value, $is_weak );
		$weak{$key} = $is_weak ? 1 : 0;
	}

	return ( \%map, \%weak );
}

sub _decode_pairlist_payload {
	my ( $runtime, $id, $payload, $placeholders ) = @_;

	die "PairList object payload $id must be an array"
		if ref($payload) ne 'ARRAY';

	my @list;
	my @weak;
	for my $pair ( @{ $payload } ) {
		my ( $key, $value, $is_weak ) = _decode_key_value_record(
			$runtime,
			"PairList object payload $id",
			$pair,
			$placeholders,
		);
		push @list, [ $key, undef ];
		store_value( \$list[-1][1], $value, $is_weak );
		push @weak, $is_weak ? 1 : 0;
	}

	return ( \@list, \@weak );
}

sub _decode_key_value_record {
	my ( $runtime, $context, $pair, $placeholders ) = @_;

	die "$context entries must be two-item arrays"
		if ref($pair) ne 'ARRAY' or scalar @{ $pair } != 2;

	my ( $key, $value ) = @{ $pair };
	die "$context keys must be text strings"
		if !is_text_string($key);

	return (
		text_value($key),
		_decode_stored_value(
			$runtime,
			$value,
			$placeholders,
			"$context value",
		),
	);
}

sub _decode_stored_value {
	my ( $runtime, $value, $placeholders, $context ) = @_;

	$context //= 'Stored value';
	if ( _is_weak_storage_record($value) ) {
		_validate_weak_storage_record(
			$runtime,
			$value,
			$placeholders,
			$context,
		);
		return (
			_decode_value(
				$runtime,
				$value->[1],
				$placeholders,
				allow_weak => 0,
				context => "$context weak storage value",
			),
			1,
		);
	}

	return (
		_decode_value(
			$runtime,
			$value,
			$placeholders,
			allow_weak => 0,
			context => $context,
		),
		0,
	);
}

sub _decode_value {
	my ( $runtime, $value, $placeholders, %opts ) = @_;

	my $allow_weak = exists $opts{allow_weak} ? $opts{allow_weak} : 1;
	my $context = $opts{context} // 'Encoded value';

	return _decode_scalar_value( $runtime, $value )
		if !ref($value)
		or is_cbor_bool($value)
		or is_text_string($value)
		or is_byte_string($value);

	if ( ref($value) eq 'ARRAY' ) {
		die "$context array must be [0, id] or [1, value]"
			if scalar @{ $value } != 2;
		my ( $marker, $id ) = @{ $value };
		die "$context marker must be 0 or 1"
			if !_is_integer_value($marker)
			or ( $marker != 0 and $marker != 1 );
		if ( $marker == 1 ) {
			_validate_weak_storage_record(
				$runtime,
				$value,
				$placeholders,
				$context,
			);
			die "$context weak storage record is not allowed here"
				if !$allow_weak;
			die "$context weak storage record is only allowed in a "
				. "stored value position";
		}
		die "Encoded reference id must be an integer"
			if !_is_integer_value($id);
		die "Reference id $id is outside the object table"
			if $id < 0 or $id > $#{ $placeholders };
		return $placeholders->[$id];
	}

	die "Envelope root is not a scalar or supported reference";
}

sub _validate_weak_storage_record {
	my ( $runtime, $record, $placeholders, $context ) = @_;

	die "$context weak storage record must be [1, value]"
		if ref($record) ne 'ARRAY' or scalar @{ $record } != 2;
	my ( undef, $inner ) = @{ $record };
	die "$context nested weak storage records are invalid"
		if _is_weak_storage_record($inner);
	_decode_value(
		$runtime,
		$inner,
		$placeholders,
		allow_weak => 0,
		context => "$context weak storage value",
	);

	return 1;
}

sub _reject_weak_storage_record {
	my ( $value, $context ) = @_;

	die "$context weak storage record is not allowed here"
		if _is_weak_storage_record($value);

	return;
}

sub _is_weak_storage_record {
	my ( $value ) = @_;

	return 0
		if ref($value) ne 'ARRAY'
		or scalar @{ $value } != 2
		or ref( $value->[0] );

	return $value->[0] == 1 ? 1 : 0;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $exception_parent = $runtime->{_builtin_classes}{Exception};
	my $marshalling_exception = native_class(
		name => 'MarshallingException',
		parent => $exception_parent,
	);
	my $unmarshalling_exception = native_class(
		name => 'UnmarshallingException',
		parent => $exception_parent,
	);

	my $dump = native_function(
		name => 'dump',
		native => sub {
			my @args = @_;
			_assert_arity( $runtime, 'dump', \@args, 1 );
			my $bytes;
			eval {
				$bytes = dump_value( $runtime, $args[0] );
				1;
			} or do {
				my $error = $@;
				_throw_object(
					$runtime,
					$marshalling_exception,
					"std/marshal.dump failed: $error",
				);
			};
			return Zuzu::Value::BinaryString->new( bytes => $bytes );
		},
	);

	my $load = native_function(
		name => 'load',
		native => sub {
			my @args = @_;
			_assert_arity( $runtime, 'load', \@args, 1 );
			_assert_binary_string( $runtime, 'load', $args[0] );
			my $value;
			eval {
				$value = load_value( $runtime, $args[0]->bytes );
				1;
			} or do {
				my $error = $@;
				_throw_object(
					$runtime,
					$unmarshalling_exception,
					"std/marshal.load failed: $error",
				);
			};
			return $value;
		},
	);

	my $safe_to_dump = native_function(
		name => 'safe_to_dump',
		native => sub {
			my @args = @_;
			_assert_arity( $runtime, 'safe_to_dump', \@args, 1 );
			return _safe_to_dump( $runtime, $args[0] ) ? $TRUE : $FALSE;
		},
	);

	return {
		dump => $dump,
		load => $load,
		safe_to_dump => $safe_to_dump,
		MarshallingException => $marshalling_exception,
		UnmarshallingException => $unmarshalling_exception,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::Marshal - runtime support for std/marshal

=head1 DESCRIPTION

Runtime support for C<std/marshal>. The current implementation supports
Zuzu Marshal CBOR v1 envelopes with scalars, Pair, Array, Dict,
PairList, Set, Bag, Time, Path, user functions, user-defined classes,
user-defined traits, user object values, and bound method values. User
object C<__on_dump__> and C<__on_load__> lifecycle hooks are called
during dump and load.
C<safe_to_dump> performs the same dump traversal and returns false for
values that cannot currently be marshalled. User-defined functions,
classes, and traits are serialized through code table records
containing source, scalar captures, and supported dependencies. Weak
storage records are emitted and loaded only in stored value positions
such as object slots and collection entries. Malformed, nested, or
misplaced weak records are rejected. A weak edge that is not already
strongly reachable is encoded as C<[1, null]> so that marshalling does
not strengthen it during dump or load.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::Marshal >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
