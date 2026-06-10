package Zuzu::Parser::_Impl;

use utf8;

our $VERSION = '0.003000';

use Zuzu::AST::Block;
use Zuzu::AST::Expr::Array;
use Zuzu::AST::Expr::Await;
use Zuzu::AST::Expr::Binary;
use Zuzu::AST::Expr::Bag;
use Zuzu::AST::Expr::Call;
use Zuzu::AST::Expr::Dict;
use Zuzu::AST::Expr::DictGet;
use Zuzu::AST::Expr::DynamicMemberCall;
use Zuzu::AST::Expr::Function;
use Zuzu::AST::Expr::Index;
use Zuzu::AST::Expr::IncDec;
use Zuzu::AST::Expr::Literal;
use Zuzu::AST::Expr::MemberCall;
use Zuzu::AST::Expr::New;
use Zuzu::AST::Expr::PairList;
use Zuzu::AST::Expr::Range;
use Zuzu::AST::Expr::Regexp;
use Zuzu::AST::Expr::Set;
use Zuzu::AST::Expr::Slice;
use Zuzu::AST::Expr::Spawn;
use Zuzu::AST::Expr::Spread;
use Zuzu::AST::Expr::Ternary;
use Zuzu::AST::Expr::TypeRef;
use Zuzu::AST::Expr::Unary;
use Zuzu::AST::Expr::Var;
use Zuzu::AST::Program;
use Zuzu::AST::Stmt::Assign;
use Zuzu::AST::Stmt::Assert;
use Zuzu::AST::Stmt::Debug;
use Zuzu::AST::Stmt::Continue;
use Zuzu::AST::Stmt::Expr;
use Zuzu::AST::Stmt::For;
use Zuzu::AST::Stmt::Function;
use Zuzu::AST::Stmt::If;
use Zuzu::AST::Stmt::Import;
use Zuzu::AST::Stmt::Class;
use Zuzu::AST::Stmt::Catch;
use Zuzu::AST::Stmt::Die;
use Zuzu::AST::Stmt::Last;
use Zuzu::AST::Stmt::Let;
use Zuzu::AST::Stmt::LetUnpack;
use Zuzu::AST::Stmt::Method;
use Zuzu::AST::Stmt::Next;
use Zuzu::AST::Stmt::PostfixIf;
use Zuzu::AST::Stmt::Return;
use Zuzu::AST::Stmt::Switch;
use Zuzu::AST::Stmt::Throw;
use Zuzu::AST::Stmt::Trait;
use Zuzu::AST::Stmt::Try;
use Zuzu::AST::Stmt::While;
use Zuzu::Error;
use Zuzu::Lexer;
use Zuzu::Util ();
use Zuzu::Value::Regexp;
use Zuzu::Value::Boolean;
use Zuzu::Value::BinaryString;

use Moo;
use Scalar::Util qw( blessed );

has 'lexer' => ( is => 'rw' );
has 'filename' => ( is => 'rw' );
has 'tok' => ( is => 'rw' );
has 'scopes' => (
	is => 'rw',
	default => sub {
		my %root = map {
			$_ => { kind => 'builtin', mutable => 0 }
			} qw(
				Exception
				Any
				Null
				Boolean
				Number
				AssertionException
				TypeException
				CancelledException
				TimeoutException
				ChannelClosedException
				Object
				Collection
				Array
				Dict
				PairList
				Set
				Bag
				Pair
				String
				BinaryString
				Task
				Regexp
				Function
				Trait
				Class
				say
				print
				warn
				typeof
				to_binary
				to_string
				__file__
				__system__
				__global__
			);

		return [ \%root ];
	},
);

sub BUILD {
	my ($self, $args) = @_;

	$self->{tok} = $self->{lexer}->next_token;

	return;
}

sub _err {
	my ($self, $msg, $tok) = @_;

	$tok //= $self->{tok};
	die Zuzu::Error->new_compile(code => 'E_COMPILE_SYNTAX', message => $msg, file => $tok->file, line => $tok->line);
}

sub _eat {
	my ($self, $type, $value) = @_;

	my $t = $self->{tok};
	$self->_err("Expected $type", $t) if $t->type ne $type;
	$self->_err("Expected '$value'", $t) if defined($value) && (($t->value // '') ne $value);
	$self->{tok} = $self->{lexer}->next_token;

	return $t;
}

sub _maybe {
	my ($self, $type, $value) = @_;

	my $t = $self->{tok};

	return 0 if $t->type ne $type;

	return 0 if defined($value) && (($t->value // '') ne $value);
	$self->{tok} = $self->{lexer}->next_token;

	return $t;
}

sub _peek_token {
	my ($self) = @_;

	my $lexer = $self->{lexer};
	my ( $pos, $line, $col, $last ) = (
		$lexer->pos,
		$lexer->line,
		$lexer->col,
		$lexer->last_token,
	);
	my $tok = $lexer->next_token;
	$lexer->pos($pos);
	$lexer->line($line);
	$lexer->col($col);
	$lexer->last_token($last);

	return $tok;
}

sub _eat_member_name {
	my ( $self ) = @_;

	if ( $self->{tok}->is_IDENT ) {
		return $self->_eat('IDENT')->value;
	}
	if ( $self->{tok}->is_KW ) {
		return $self->_eat('KW')->value;
	}
	$self->_err("Expected method name", $self->{tok});
}

sub _push_scope { push @{$_[0]->{scopes}}, {} }

sub _pop_scope  { pop @{$_[0]->{scopes}} }

sub _parse_block_in_async_context {
	my ( $self, $is_async, $decls, $imports ) = @_;

	if ( $is_async ) {
		local $self->{_async_context_depth} =
			( $self->{_async_context_depth} // 0 ) + 1;
		return $self->_parse_block_with_decls( $decls, $imports );
	}

	local $self->{_async_context_depth} = 0;
	return $self->_parse_block_with_decls( $decls, $imports );
}

sub _mark_wildcard_import_in_scope {
	my ( $self ) = @_;

	$self->{scopes}[-1]{'__wildcard_import__'} = 1;

	return;
}

sub _has_wildcard_import_in_scope {
	my ( $self ) = @_;

	for ( my $i = $#{$self->{scopes}}; $i >= 0; $i-- ) {
		return 1 if $self->{scopes}[$i]{'__wildcard_import__'};
	}

	return 0;
}

sub _declare {
	my ($self, $name, $info, $tok, $opts) = @_;

	$tok //= $self->{tok};
	$opts //= {};
	$self->_err("Keyword '$name' cannot be used as an identifier", $tok) if Zuzu::Util::is_keyword($name);
	$self->_err("'^^' is reserved for the chain placeholder", $tok) if $name eq '^^';
	my $scope = $self->{scopes}[-1];
	if ( exists $scope->{$name} ) {
		my $existing = $scope->{$name};
		if ( !$opts->{allow_builtin_shadow} or $existing->{kind} ne 'builtin' ) {
			$self->_err("Redeclaration of '$name' in the same scope", $tok);
		}
	}
	$scope->{$name} = $info;
}

sub _declare_function_name {
	my ( $self, $name, $tok, $is_predeclared ) = @_;

	$self->_err("Keyword '$name' cannot be used as an identifier", $tok) if Zuzu::Util::is_keyword($name);
	$self->_err("'^^' is reserved for the chain placeholder", $tok) if $name eq '^^';
	my $scope = $self->{scopes}[-1];
	if ( exists $scope->{$name} ) {
		my $existing = $scope->{$name};
		if ( $is_predeclared or $existing->{kind} ne 'func_predecl' ) {
			$self->_err("Redeclaration of '$name' in the same scope", $tok);
		}
		$scope->{$name} = { kind => 'func', mutable => 0 };
		return;
	}

	$scope->{$name} = {
		kind => $is_predeclared ? 'func_predecl' : 'func',
		mutable => 0,
	};
}

sub _lookup {
	my ($self, $name) = @_;

	for (my $i = $#{$self->{scopes}}; $i >= 0; $i--) {

		return $self->{scopes}[$i]{$name} if exists $self->{scopes}[$i]{$name};
	}

	return undef;
}

sub parse_program {
	my ($self) = @_;

	my @stmts;
	{
		local $self->{_async_context_depth} =
			( $self->{_async_context_depth} // 0 ) + 1;
		while ( ! $self->{tok}->is_EOF ) {
			$self->_eat_optional_statement_separators;
			last if $self->{tok}->is_EOF;
			push @stmts, $self->parse_statement;
		}
	}

	return Zuzu::AST::Program->new(file => $self->{filename}, line => 1, statements => \@stmts);
}

sub _eat_optional_statement_separators {
	my ( $self ) = @_;

	while ( $self->_maybe( 'OP', ';' ) ) {
		# Consume no-op statement separators.
	}

	return;
}

sub parse_statement {
	my ($self) = @_;

	my $t = $self->{tok};

	if ( $t->is_KW('let') or $t->is_KW('const') ) {

		return $self->parse_let;
	}
	if ( $t->is_KW('function') or $t->is_KW('async') ) {

		return $self->parse_function_def;
	}
	if ( $t->is_KW('class') ) {

		return $self->parse_class_def;
	}
	if ( $t->is_KW('trait') ) {

		return $self->parse_trait_def;
	}
	if ( $t->is_KW('if') ) {

		return $self->parse_if;
	}
	if ( $t->is_KW('while') ) {

		return $self->parse_while;
	}
	if ( $t->is_KW('for') ) {

		return $self->parse_for;
	}
	if ( $t->is_KW('switch') ) {

		return $self->parse_switch;
	}
	if ( $t->is_KW('try') ) {

		return $self->parse_try;
	}
	if ( $t->is_KW('return') ) {

		return $self->parse_return;
	}
	if (
		$t->is_KW('say')
		or $t->is_KW('print')
		or $t->is_KW('warn')
		or $t->is_KW('debug')
		or $t->is_KW('assert')
	) {
		return $self->parse_builtin_statement;
	}
	if ( $t->is_KW('throw') ) {
		my $kw = $self->_eat('KW', 'throw');
		my $expr = $self->parse_expression;
		my $stmt = Zuzu::AST::Stmt::Throw->new(
			file => $kw->file,
			line => $kw->line,
			expr => $expr,
		);

		return $self->_finish_with_postfix_condition($stmt);
	}
	if ( $t->is_KW('die') ) {
		my $kw = $self->_eat('KW', 'die');
		my $expr = $self->parse_expression;
		my $stmt = Zuzu::AST::Stmt::Die->new(
			file => $kw->file,
			line => $kw->line,
			expr => $expr,
		);

		return $self->_finish_with_postfix_condition($stmt);
	}
	if ( $t->is_KW('next') ) {
		my $kw = $self->_eat('KW', 'next');
		my $stmt = Zuzu::AST::Stmt::Next->new(file => $kw->file, line => $kw->line);

		return $self->_finish_with_postfix_condition($stmt);
	}
	if ( $t->is_KW('continue') ) {
		my $kw = $self->_eat('KW', 'continue');
		my $stmt = Zuzu::AST::Stmt::Continue->new(file => $kw->file, line => $kw->line);

		return $self->_finish_with_postfix_condition($stmt);
	}
	if ( $t->is_KW('last') ) {
		my $kw = $self->_eat('KW', 'last');
		my $stmt = Zuzu::AST::Stmt::Last->new(file => $kw->file, line => $kw->line);

		return $self->_finish_with_postfix_condition($stmt);
	}
	if ( $t->is_KW('from') ) {

		return $self->parse_import;
	}
	if ( $t->is_OP('{') ) {

		return $self->parse_block;
	}

	# assignment or expr stmt
	my $expr = $self->parse_expression;

	if ( blessed($expr) and $expr->isa('Zuzu::AST::Stmt::Assign') ) {
		return $self->_finish_with_postfix_condition($expr);
	}

	my $stmt = Zuzu::AST::Stmt::Expr->new(file => $t->file, line => $t->line, expr => $expr);

	return $self->_finish_with_postfix_condition($stmt);
}

sub parse_builtin_statement {
	my ($self) = @_;

	my $kw = $self->_eat('KW');
	if ( $kw->value eq 'assert' ) {
		my $expr = $self->parse_expression;
		my $stmt = Zuzu::AST::Stmt::Assert->new(
			file => $kw->file,
			line => $kw->line,
			expr => $expr,
		);

		return $self->_finish_with_postfix_condition($stmt);
	}
	if ( $kw->value eq 'debug' ) {
		my $level = $self->parse_expression;
		$self->_eat('OP', ',');
		my $message = $self->parse_expression;
		my $stmt = Zuzu::AST::Stmt::Debug->new(
			file => $kw->file,
			line => $kw->line,
			level_expr => $level,
			message_expr => $message,
		);

		return $self->_finish_with_postfix_condition($stmt);
	}
	my @args;
	push @args, $self->parse_expression;
	while ( $self->_maybe('OP', ',') ) {
		push @args, $self->parse_expression;
	}

	my $callee = Zuzu::AST::Expr::Var->new(
		file => $kw->file,
		line => $kw->line,
		name => $kw->value,
	);
	my $call = Zuzu::AST::Expr::Call->new(
		file => $kw->file,
		line => $kw->line,
		callee => $callee,
		args => \@args,
	);
	my $stmt = Zuzu::AST::Stmt::Expr->new(
		file => $kw->file,
		line => $kw->line,
		expr => $call,
	);

	return $self->_finish_with_postfix_condition($stmt);
}

sub _finish_with_postfix_condition {
	my ($self, $stmt) = @_;

	my $has_postfix = 0;
	my $negate = 0;
	if ( $self->{tok}->is_KW('if') ) {
		$self->_eat('KW', 'if');
		$has_postfix = 1;
	} elsif ( $self->{tok}->is_KW('unless') ) {
		$self->_eat('KW', 'unless');
		$negate = 1;
		$has_postfix = 1;
	}

	if ( $has_postfix ) {
		my $cond = $self->parse_expression;
		$stmt = Zuzu::AST::Stmt::PostfixIf->new(
			file => $stmt->file,
			line => $stmt->line,
			statement => $stmt,
			cond => $cond,
			negate => $negate,
		);
	}
	elsif ( $self->{tok}->is_KW('for') ) {
		$self->_eat('KW', 'for');
		my $collection = $self->parse_expression;
		$stmt = Zuzu::AST::Stmt::For->new(
			file => $stmt->file,
			line => $stmt->line,
			var => '^^',
			declare_loop_var => 1,
			loop_var_kind => 'const',
			collection => $collection,
			body => Zuzu::AST::Block->new(
				file => $stmt->file,
				line => $stmt->line,
				statements => [ $stmt ],
			),
			else_block => undef,
		);
	}

	$self->_eat_statement_separator;

	return $stmt;
}

sub _eat_statement_separator {
	my ($self) = @_;

	return if $self->_maybe('OP', ';');
	return if $self->{tok}->is_OP('}');
	return if $self->{tok}->is_EOF;

	$self->_eat('OP', ';');
}

sub parse_block {
	my ($self) = @_;

	my $lb = $self->_eat('OP', '{');
	$self->_push_scope;
	my @stmts;
	while ( ! $self->{tok}->is_OP('}') ) {
		$self->_err("Unterminated block", $self->{tok}) if $self->{tok}->is_EOF;
		$self->_eat_optional_statement_separators;
		last if $self->{tok}->is_OP('}');
		push @stmts, $self->parse_statement;
	}
	$self->_eat('OP', '}');
	$self->_pop_scope;

	return Zuzu::AST::Block->new(file => $lb->file, line => $lb->line, statements => \@stmts);
}

sub _parse_let_decl {
	my ( $self, $expect_semicolon ) = @_;

	my $kw = $self->_eat('KW');
	my $is_const = ($kw->value eq 'const') ? 1 : 0;

	if ( $self->{tok}->is_OP('{') ) {
		return $self->_parse_let_unpack_decl( $kw, $is_const, $expect_semicolon );
	}

	my ( $declared_type, $name, $name_tok ) = $self->_parse_typed_identifier;
	my $is_weak_storage = $self->_parse_optional_weak_modifier('declaration');

	# Detect forbidden "let x = 1"
	if ($self->{tok}->is_OP && $self->{tok}->value eq '=') {
		$self->_err("Invalid assignment '=' in declaration. Use ':=' (did you mean: let $name := ... ?)", $self->{tok});
	}

	my $init;
	if ($self->_maybe('OP', ':=')) {
		$init = $self->parse_expression;
		$is_weak_storage ||= $self->_parse_optional_weak_modifier('declaration');
	} else {
		$init = undef;
	}
	$self->_eat_statement_separator if $expect_semicolon;

	$self->_declare(
		$name,
		{
			kind => $is_const ? 'const' : 'let',
			mutable => $is_const ? 0 : 1,
			declared_type => $declared_type,
		},
		$name_tok,
	);

	return Zuzu::AST::Stmt::Let->new(
		file => $kw->file, line => $kw->line,
		name => $name, init => $init, is_const => $is_const, declared_type => $declared_type,
		is_weak_storage => $is_weak_storage ? 1 : 0,
	);
}

sub _parse_let_unpack_decl {
	my ( $self, $kw, $is_const, $expect_semicolon ) = @_;

	$self->_eat('OP', '{');
	my @bindings;
	my %names;
	while ( !$self->{tok}->is_OP('}') ) {
		if ( $self->_maybe('OP', ',') ) {
			next;
		}
		my $binding = $self->_parse_unpack_binding;
		if ( $names{ $binding->{name} }++ ) {
			$self->_err(
				"Duplicate unpacked binding '".$binding->{name}."' in declaration",
				$binding->{name_tok},
			);
		}
		push @bindings, $binding;
		$self->_maybe('OP', ',');
	}
	$self->_eat('OP', '}');
	$self->_eat('OP', ':=');
	my $init = $self->parse_expression;
	$self->_eat_statement_separator if $expect_semicolon;

	for my $binding ( @bindings ) {
		$self->_declare(
			$binding->{name},
			{
				kind => $is_const ? 'const' : 'let',
				mutable => $is_const ? 0 : 1,
				declared_type => $binding->{declared_type},
			},
			$binding->{name_tok},
		);
	}

	return Zuzu::AST::Stmt::LetUnpack->new(
		file => $kw->file,
		line => $kw->line,
		bindings => \@bindings,
		init => $init,
		is_const => $is_const,
	);
}

sub _parse_unpack_binding {
	my ( $self ) = @_;

	my ( $key_expr, $declared_type, $name, $name_tok );
	my $binding_file = $self->{tok}->file;
	my $binding_line = $self->{tok}->line;

	if ( $self->{tok}->is_IDENT ) {
		my $first = $self->_eat('IDENT');
		if ( $self->_maybe('OP', ':') ) {
			$key_expr = Zuzu::AST::Expr::Literal->new(
				file => $first->file,
				line => $first->line,
				value => $first->value,
			);
			( $declared_type, $name, $name_tok ) = $self->_parse_typed_identifier;
		}
		elsif ( $self->{tok}->is_IDENT ) {
			my $local_tok = $self->_eat('IDENT');
			$declared_type = $first->value;
			$name = $local_tok->value;
			$name_tok = $local_tok;
			$key_expr = Zuzu::AST::Expr::Literal->new(
				file => $local_tok->file,
				line => $local_tok->line,
				value => $local_tok->value,
			);
		}
		else {
			$declared_type = 'Any';
			$name = $first->value;
			$name_tok = $first;
			$key_expr = Zuzu::AST::Expr::Literal->new(
				file => $first->file,
				line => $first->line,
				value => $first->value,
			);
		}
	}
	elsif ( $self->{tok}->is_KW ) {
		my $key_tok = $self->_eat('KW');
		$key_expr = Zuzu::AST::Expr::Literal->new(
			file => $key_tok->file,
			line => $key_tok->line,
			value => $key_tok->value,
		);
		$self->_eat('OP', ':');
		( $declared_type, $name, $name_tok ) = $self->_parse_typed_identifier;
	}
	elsif ( $self->{tok}->is_STRING or $self->{tok}->is_type('TEMPLATE') ) {
		$key_expr = $self->parse_primary;
		$self->_eat('OP', ':');
		( $declared_type, $name, $name_tok ) = $self->_parse_typed_identifier;
	}
	elsif ( $self->{tok}->is_OP('(') ) {
		$key_expr = $self->parse_primary;
		$self->_eat('OP', ':');
		( $declared_type, $name, $name_tok ) = $self->_parse_typed_identifier;
	}
	else {
		$self->_err("Expected unpacked binding in declaration", $self->{tok});
	}

	my $default_expr;
	my $has_default = 0;
	if ( $self->_maybe('OP', ':=') ) {
		$default_expr = $self->parse_expression;
		$has_default = 1;
	}
	my $is_weak_storage = $self->_parse_optional_weak_modifier('declaration');

	return {
		file => $binding_file,
		line => $binding_line,
		key_expr => $key_expr,
		name => $name,
		name_tok => $name_tok,
		declared_type => $declared_type,
		default_expr => $default_expr,
		has_default => $has_default,
		is_weak_storage => $is_weak_storage ? 1 : 0,
	};
}

sub parse_let {
	my ($self) = @_;

	return $self->_parse_let_decl(1);
}

sub parse_function_def {
	my ($self) = @_;

	my $async_tok;
	if ( $self->{tok}->is_KW('async') ) {
		$async_tok = $self->_eat('KW', 'async');
	}
	my $kw = $self->_eat('KW', 'function');
	my $name_tok = $self->_eat('IDENT');
	my $name = $name_tok->value;

	if ( $self->_maybe('OP', ';') ) {
		$self->_declare_function_name( $name, $name_tok, 1 );
		return Zuzu::AST::Stmt::Function->new(
			file => ( $async_tok // $kw )->file,
			line => ( $async_tok // $kw )->line,
			name => $name,
			params => [],
			is_async => $async_tok ? 1 : 0,
			is_predeclared => 1,
		);
	}

	$self->_declare_function_name( $name, $name_tok, 0 );

	my ( $params, $vararg, $param_types, $vararg_type, $param_optional, $param_defaults, $named_vararg, $named_vararg_type ) = $self->_parse_param_list;
	my $return_type = $self->_parse_optional_return_type;

	my @arg_decls = map {
		{
			name => $_,
			mutable => 0,
			declared_type => $param_types->{$_} // 'Any',
		}
	} @{ $params // [] };
	if ( defined $vararg ) {
		push @arg_decls, {
			name => $vararg,
			mutable => 0,
			declared_type => $vararg_type // 'Any',
		};
	}
	if ( defined $named_vararg ) {
		push @arg_decls, {
			name => $named_vararg,
			mutable => 0,
			declared_type => $named_vararg_type // 'PairList',
		};
	}
	my $is_async = $async_tok ? 1 : 0;
	my $body = $self->_parse_block_in_async_context(
		$is_async,
		\@arg_decls,
		[],
	);

	return Zuzu::AST::Stmt::Function->new(
		file => ( $async_tok // $kw )->file,
		line => ( $async_tok // $kw )->line,
		name => $name,
		params => $params,
		vararg => $vararg,
		body => $body,
		param_types => $param_types,
		vararg_type => $vararg_type,
		named_vararg => $named_vararg,
		named_vararg_type => $named_vararg_type,
		param_optional => $param_optional,
		param_defaults => $param_defaults,
		return_type => $return_type,
		is_async => $is_async,
	);
}

sub parse_class_def {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'class');
	my $name_tok = $self->_eat('IDENT');
	my $name = $name_tok->value;
	my $parent;
	my @traits;
	if ( $self->_maybe('KW', 'extends') ) {
		$parent = $self->parse_type_ref;
	}
	if ( $self->{tok}->is_KW('with') or $self->{tok}->is_KW('but') ) {
		$self->_eat('KW');
		push @traits, $self->parse_type_ref;
		while ( $self->_maybe('OP', ',') ) {
			push @traits, $self->parse_type_ref;
		}
	}

	$self->_declare($name, { kind => 'class', mutable => 0 }, $name_tok);

	my @fields;
	my @methods;
	my @static_methods;
	my @classes;

	if ( $self->_maybe('OP', ';') ) {
		return Zuzu::AST::Stmt::Class->new(
			file => $kw->file,
			line => $kw->line,
			name => $name,
			parent => $parent,
			traits => \@traits,
			fields => \@fields,
			methods => \@methods,
			static_methods => \@static_methods,
			classes => \@classes,
		);
	}

	$self->_eat('OP', '{');
	while ( ! $self->{tok}->is_OP('}') ) {
		my $t = $self->{tok};
		if ( $t->is_KW('let') or $t->is_KW('const') ) {
			my $decl = $self->_eat('KW');
			my ( $declared_type, $name ) = $self->_parse_typed_identifier;
			my $accessors = $self->_parse_field_accessor_list;
			my $is_weak_storage = $self->_parse_optional_weak_modifier('field declaration');
			my $init;
			if ( $self->{tok}->is_OP('=') ) {
				$self->_err("Invalid assignment '=' in declaration. Use ':='", $self->{tok});
			}
			if ( $self->_maybe('OP', ':=') ) {
				$init = $self->parse_expression;
				$is_weak_storage ||= $self->_parse_optional_weak_modifier('field declaration');
			}
			$self->_eat('OP', ';');
			push @fields, {
				name => $name,
				is_const => $decl->value eq 'const' ? 1 : 0,
				init => $init,
				declared_type => $declared_type,
				is_weak_storage => $is_weak_storage ? 1 : 0,
				accessors => [ @{ $accessors // [] } ],
			};
			push @methods, @{ $self->_build_field_accessor_methods(
				name => $name,
				declared_type => $declared_type,
				accessors => $accessors,
				is_weak_storage => $is_weak_storage,
				file => $decl->file,
				line => $decl->line,
			) };
			next;
		}
		if ( $t->is_KW('static') or $t->is_KW('async') or $t->is_KW('method') ) {
			my $m = $self->parse_method_def( \@fields );
			if ( $m->is_static ) {
				push @static_methods, $m;
			}
			else {
				push @methods, $m;
			}
			next;
		}
		if ( $t->is_KW('class') ) {
			push @classes, $self->parse_class_def;
			next;
		}
		$self->_err("Only fields, methods, and nested classes are allowed in class bodies", $t);
	}
	$self->_eat('OP', '}');

	return Zuzu::AST::Stmt::Class->new(
		file => $kw->file,
		line => $kw->line,
		name => $name,
		parent => $parent,
		traits => \@traits,
		fields => \@fields,
		methods => \@methods,
		static_methods => \@static_methods,
		classes => \@classes,
	);
}

sub _parse_field_accessor_list {
	my ( $self ) = @_;

	return [] if not $self->_maybe( 'KW', 'with' );

	my %valid = map { $_ => 1 } qw( get set clear has );
	my @ops;
	while (1) {
		my $tok = $self->_eat('IDENT');
		my $kind = $tok->value;
		if ( not $valid{$kind} ) {
			$self->_err(
				"Unknown field accessor '$kind'. Expected one of: get, set, clear, has",
				$tok,
			);
		}
		push @ops, $kind if not grep { $_ eq $kind } @ops;
		last if not $self->_maybe('OP', ',');
	}

	return \@ops;
}

sub _parse_optional_weak_modifier {
	my ( $self, $context ) = @_;

	return 0 if not $self->{tok}->is_KW('but');

	my $but = $self->_eat('KW', 'but');
	my $tok = $self->{tok};
	if ( !( $tok->is_IDENT || $tok->is_KW ) || $tok->value ne 'weak' ) {
		my $modifier = $tok->value // '';
		$self->_err(
			"Unknown but modifier '$modifier' in $context; expected 'but weak'",
			$tok,
		);
	}
	$self->{tok} = $self->{lexer}->next_token;

	return 1;
}

sub _build_field_accessor_methods {
	my ( $self, %args ) = @_;

	my $name = $args{name};
	my $declared_type = $args{declared_type} // 'Any';
	my $accessors = $args{accessors} // [];
	my $is_weak_storage = $args{is_weak_storage} ? 1 : 0;
	my $file = $args{file};
	my $line = $args{line};
	my @methods;

	for my $kind ( @{ $accessors } ) {
		if ( $kind eq 'get' ) {
			push @methods, Zuzu::AST::Stmt::Method->new(
				file => $file,
				line => $line,
				name => 'get_' . $name,
				params => [],
				vararg => undef,
				named_vararg => undef,
				is_static => 0,
				param_types => {},
				vararg_type => 'Any',
				named_vararg_type => 'PairList',
				param_optional => {},
				param_defaults => {},
				return_type => $declared_type,
				body => Zuzu::AST::Block->new(
					file => $file,
					line => $line,
					statements => [
						Zuzu::AST::Stmt::Return->new(
							file => $file,
							line => $line,
							expr => Zuzu::AST::Expr::Var->new(
								file => $file,
								line => $line,
								name => $name,
							),
						),
					],
				),
			);
			$methods[-1]{_generated_field_accessor} = 1;
		}
		elsif ( $kind eq 'set' ) {
			my $param_name = '__value';
			push @methods, Zuzu::AST::Stmt::Method->new(
				file => $file,
				line => $line,
				name => 'set_' . $name,
				params => [ $param_name ],
				vararg => undef,
				named_vararg => undef,
				is_static => 0,
				param_types => { $param_name => $declared_type },
				vararg_type => 'Any',
				named_vararg_type => 'PairList',
				param_optional => {},
				param_defaults => {},
				return_type => 'Any',
				body => Zuzu::AST::Block->new(
					file => $file,
					line => $line,
					statements => [
						Zuzu::AST::Stmt::Assign->new(
							file => $file,
							line => $line,
							target => Zuzu::AST::Expr::Var->new(
								file => $file,
								line => $line,
								name => $name,
							),
							op => ':=',
							is_weak_write => $is_weak_storage,
							expr => Zuzu::AST::Expr::Var->new(
								file => $file,
								line => $line,
								name => $param_name,
							),
						),
						Zuzu::AST::Stmt::Return->new(
							file => $file,
							line => $line,
							expr => Zuzu::AST::Expr::Var->new(
								file => $file,
								line => $line,
								name => 'self',
							),
						),
					],
				),
			);
			$methods[-1]{_generated_field_accessor} = 1;
		}
		elsif ( $kind eq 'clear' ) {
			my $assign = Zuzu::AST::Stmt::Assign->new(
				file => $file,
				line => $line,
				target => Zuzu::AST::Expr::Var->new(
					file => $file,
					line => $line,
					name => $name,
				),
				op => ':=',
				expr => Zuzu::AST::Expr::Literal->new(
					file => $file,
					line => $line,
					value => undef,
				),
			);
			$assign->{_skip_type_check} = 1;

			push @methods, Zuzu::AST::Stmt::Method->new(
				file => $file,
				line => $line,
				name => 'clear_' . $name,
				params => [],
				vararg => undef,
				named_vararg => undef,
				is_static => 0,
				param_types => {},
				vararg_type => 'Any',
				named_vararg_type => 'PairList',
				param_optional => {},
				param_defaults => {},
				return_type => 'Any',
				body => Zuzu::AST::Block->new(
					file => $file,
					line => $line,
					statements => [
						$assign,
						Zuzu::AST::Stmt::Return->new(
							file => $file,
							line => $line,
							expr => Zuzu::AST::Expr::Var->new(
								file => $file,
								line => $line,
								name => 'self',
							),
						),
					],
				),
			);
			$methods[-1]{_generated_field_accessor} = 1;
		}
		elsif ( $kind eq 'has' ) {
			push @methods, Zuzu::AST::Stmt::Method->new(
				file => $file,
				line => $line,
				name => 'has_' . $name,
				params => [],
				vararg => undef,
				named_vararg => undef,
				is_static => 0,
				param_types => {},
				vararg_type => 'Any',
				named_vararg_type => 'PairList',
				param_optional => {},
				param_defaults => {},
				return_type => 'Boolean',
				body => Zuzu::AST::Block->new(
					file => $file,
					line => $line,
					statements => [
						Zuzu::AST::Stmt::Return->new(
							file => $file,
							line => $line,
							expr => Zuzu::AST::Expr::Binary->new(
								file => $file,
								line => $line,
								op => '≢',
								left => Zuzu::AST::Expr::Var->new(
									file => $file,
									line => $line,
									name => $name,
								),
								right => Zuzu::AST::Expr::Literal->new(
									file => $file,
									line => $line,
									value => undef,
								),
							),
						),
					],
				),
			);
			$methods[-1]{_generated_field_accessor} = 1;
		}
	}

	return \@methods;
}

sub parse_trait_def {
	my ( $self ) = @_;

	my $kw = $self->_eat('KW', 'trait');
	my $name_tok = $self->_eat('IDENT');
	my $name = $name_tok->value;

	$self->_declare($name, { kind => 'trait', mutable => 0 }, $name_tok);

	my @methods;
	if ( $self->_maybe('OP', ';') ) {
		return Zuzu::AST::Stmt::Trait->new(
			file => $kw->file,
			line => $kw->line,
			name => $name,
			methods => \@methods,
		);
	}

	$self->_eat('OP', '{');
	while ( ! $self->{tok}->is_OP('}') ) {
		my $t = $self->{tok};
		if ( $t->is_KW('async') or $t->is_KW('method') ) {
			push @methods, $self->parse_method_def( [] );
			next;
		}
		$self->_err("Only methods are allowed in trait bodies", $t);
	}
	$self->_eat('OP', '}');

	return Zuzu::AST::Stmt::Trait->new(
		file => $kw->file,
		line => $kw->line,
		name => $name,
		methods => \@methods,
	);
}

sub parse_type_ref {
	my ( $self ) = @_;

	my $root_tok = $self->_eat('IDENT');
	my $info = $self->_lookup( $root_tok->value );
	if ( !$info and !$self->_has_wildcard_import_in_scope ) {
		$self->_err("Use of undeclared identifier '".$root_tok->value."' (compile-time)", $root_tok);
	}

	return Zuzu::AST::Expr::TypeRef->new(
		file => $root_tok->file,
		line => $root_tok->line,
		root => $root_tok->value,
		member => undef,
	);
}

sub parse_method_def {
	my ( $self, $fields ) = @_;

	my $is_static = 0;
	my $is_async = 0;
	my $saw_static_before_async = 0;
	my $start_tok;
	while ( $self->{tok}->is_KW('static') or $self->{tok}->is_KW('async') ) {
		my $modifier = $self->_eat('KW');
		$start_tok //= $modifier;
		if ( $modifier->value eq 'static' ) {
			$self->_err("Duplicate static method modifier", $modifier)
				if $is_static;
			$is_static = 1;
			$saw_static_before_async = 1 if !$is_async;
		}
		else {
			$self->_err("Duplicate async method modifier", $modifier)
				if $is_async;
			warn sprintf(
				"static async method is deprecated; use async static method at %s line %s\n",
				$modifier->file // '<input>',
				$modifier->line // 0,
			) if $saw_static_before_async;
			$is_async = 1;
		}
	}
	my $kw = $self->_eat('KW', 'method');
	$start_tok //= $kw;
	my $name = $self->_eat_member_name;

	if ( $self->_maybe('OP', ';') ) {
		return Zuzu::AST::Stmt::Method->new(
			file => $start_tok->file,
			line => $start_tok->line,
			name => $name,
			params => [],
			body => undef,
			is_static => $is_static,
			is_async => $is_async,
			is_predeclared => 1,
		);
	}

	my ( $params, $vararg, $param_types, $vararg_type, $param_optional, $param_defaults, $named_vararg, $named_vararg_type ) = $self->_parse_param_list;
	my $return_type = $self->_parse_optional_return_type;

	my @locals = map {
		{
			name => $_,
			mutable => 0,
			declared_type => $param_types->{$_} // 'Any',
		}
	} @{ $params // [] };
	if ( defined $vararg ) {
		push @locals, {
			name => $vararg,
			mutable => 0,
			declared_type => $vararg_type // 'Any',
		};
	}
	if ( defined $named_vararg ) {
		push @locals, {
			name => $named_vararg,
			mutable => 0,
			declared_type => $named_vararg_type // 'PairList',
		};
	}
	push @locals, 'self';
	if ( ! $is_static ) {
		push @locals, map {
			{
				name => $_->{name},
				mutable => $_->{is_const} ? 0 : 1,
				declared_type => $_->{declared_type} // 'Any',
			}
		} @{ $fields // [] };
	}
	push @locals, 'super';
	my $body = $self->_parse_block_in_async_context(
		$is_async,
		\@locals,
		[],
	);

	return Zuzu::AST::Stmt::Method->new(
		file => $start_tok->file,
		line => $start_tok->line,
		name => $name,
		params => $params,
		vararg => $vararg,
		body => $body,
		is_static => $is_static,
		param_types => $param_types,
		vararg_type => $vararg_type,
		named_vararg => $named_vararg,
		named_vararg_type => $named_vararg_type,
		param_optional => $param_optional,
		param_defaults => $param_defaults,
		return_type => $return_type,
		is_async => $is_async,
	);
}

sub _parse_optional_return_type {
	my ( $self ) = @_;

	return 'Any' if ! $self->_maybe('OP', '->') and ! $self->_maybe('OP', '→');
	my $type = $self->_eat('IDENT');

	return $type->value;
}

sub _parse_param_list {
	my ($self) = @_;

	$self->_eat('OP', '(');
	my @params;
	my $vararg;
	my $named_vararg;
	my %param_types;
	my %param_optional;
	my %param_defaults;
	my $vararg_type = 'Any';
	my $named_vararg_type = 'PairList';
	my $seen_optional = 0;
	$self->_push_scope;
	if ( ! $self->{tok}->is_OP(')') ) {
		while (1) {
			if ( $self->{tok}->is_OP('...') ) {
				$self->_eat('OP', '...');
				while (1) {
					my ( $collector_type, $collector_name ) = $self->_parse_param_name;
					if ( $collector_type eq 'PairList' ) {
						$self->_err("Only one PairList collector can follow '...'", $self->{tok})
							if defined $named_vararg;
						$named_vararg = $collector_name;
						$named_vararg_type = $collector_type;
					}
					else {
						$self->_err("Only one positional collector can follow '...'", $self->{tok})
							if defined $vararg;
						$vararg = $collector_name;
						$vararg_type = $collector_type eq 'Any' ? 'Array' : $collector_type;
					}
					my $declared = $collector_type eq 'Any'
						? ( defined $named_vararg and $named_vararg eq $collector_name ? 'PairList' : 'Array' )
						: $collector_type;
					$self->_declare(
						$collector_name,
						{
							kind => 'local',
							mutable => 0,
							declared_type => $declared,
						},
						$self->{tok},
					);
					last if $self->{tok}->is_OP(')');
					$self->_eat('OP', ',');
				}
				last;
			}

			my ( $type_name, $param_name ) = $self->_parse_param_name;
			push @params, $param_name;
			$param_types{$param_name} = $type_name;
			$self->_declare(
				$param_name,
				{
					kind => 'local',
					mutable => 0,
					declared_type => $type_name,
				},
				$self->{tok},
			);
			if ( $self->_maybe('OP', '?') ) {
				$self->_err("Optional parameter '$param_name' cannot also define a default value", $self->{tok})
					if $self->{tok}->is_OP(':=');
				$param_optional{$param_name} = 1;
				$seen_optional = 1;
			}
			elsif ( $self->_maybe('OP', ':=') ) {
				$param_defaults{$param_name} = $self->parse_expression;
				$seen_optional = 1;
			}
			elsif ( $seen_optional ) {
				$self->_err("Required parameter '$param_name' cannot follow optional/default parameters", $self->{tok});
			}

			last if $self->{tok}->is_OP(')');
			if ( $self->{tok}->is_OP('...') ) {
				next;
			}
			$self->_eat('OP', ',');
			last if $self->{tok}->is_OP(')');
		}
	}
	$self->_eat('OP', ')');
	$self->_pop_scope;

	return ( \@params, $vararg, \%param_types, $vararg_type, \%param_optional, \%param_defaults, $named_vararg, $named_vararg_type );
}

sub _parse_param_name {
	my ( $self ) = @_;

	my $first = $self->_eat('IDENT');

	if ( $self->{tok}->is_IDENT ) {
		my $name_tok = $self->_eat('IDENT');
		return ( $first->value, $name_tok->value );
	}

	return ( 'Any', $first->value );
}

sub _parse_typed_identifier {
	my ( $self ) = @_;

	my $first = $self->_eat('IDENT');
	if ( $self->{tok}->is_IDENT ) {
		my $name_tok = $self->_eat('IDENT');
		return ( $first->value, $name_tok->value, $name_tok );
	}

	return ( 'Any', $first->value, $first );
}

sub _parse_block_with_decls {
	my ( $self, $decls, $extras ) = @_;

	my $lb = $self->_eat('OP', '{');
	$self->_push_scope;
	for my $n ( @{ $decls // [] }, @{ $extras // [] } ) {
		next if ! defined $n;
		my ( $name, $mutable, $declared_type );
		if ( ref($n) eq 'HASH' ) {
			$name = $n->{name};
			$mutable = defined $n->{mutable} ? $n->{mutable} : 1;
			$declared_type = $n->{declared_type} // 'Any';
		}
		else {
			$name = $n;
			$mutable = 1;
			$declared_type = 'Any';
		}
		next if ! defined $name || $name eq '';
		my $scope = $self->{scopes}[-1];
		next if exists $scope->{$name};
		$scope->{$name} = {
			kind => 'local',
			mutable => $mutable ? 1 : 0,
			declared_type => $declared_type,
		};
	}
	my @stmts;
	while ( ! $self->{tok}->is_OP('}') ) {
		$self->_err("Unterminated block", $self->{tok}) if $self->{tok}->is_EOF;
		$self->_eat_optional_statement_separators;
		last if $self->{tok}->is_OP('}');
		push @stmts, $self->parse_statement;
	}
	$self->_eat('OP', '}');
	$self->_pop_scope;

	return Zuzu::AST::Block->new(file => $lb->file, line => $lb->line, statements => \@stmts);
}

sub parse_if {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'if');
	$self->_eat('OP', '(');
	my $cond = $self->parse_expression;
	$self->_eat('OP', ')');
	my $then = $self->parse_block;

	my $else_branch;
	if ($self->_maybe('KW', 'else')) {
		if ($self->{tok}->is_KW && $self->{tok}->value eq 'if') {
			$else_branch = $self->parse_if;
		} else {
			$else_branch = $self->parse_block;
		}
	}

	return Zuzu::AST::Stmt::If->new(
		file => $kw->file, line => $kw->line,
		cond => $cond, then_block => $then, else_branch => $else_branch
	);
}

sub parse_while {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'while');
	$self->_eat('OP', '(');
	my $cond = $self->parse_expression;
	$self->_eat('OP', ')');
	my $body = $self->parse_block;

	return Zuzu::AST::Stmt::While->new(file => $kw->file, line => $kw->line, cond => $cond, body => $body);
}

sub parse_for {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'for');
	$self->_eat('OP', '(');
	my $loop_var_kind;
	if ( $self->_maybe('KW', 'let') ) {
		$loop_var_kind = 'let';
	}
	elsif ( $self->_maybe('KW', 'const') ) {
		$loop_var_kind = 'const';
	}
	my $declares_loop_var = defined $loop_var_kind ? 1 : 0;
	my ( $id, $var, $col );
	if ($declares_loop_var) {
		$id = $self->_eat('IDENT');
		$var = $id->value;
		$self->_eat('KW', 'in');
		$col = $self->parse_expression;
	}
	elsif ( $self->{tok}->is_IDENT and $self->_peek_token->is_KW('in') ) {
		$id = $self->_eat('IDENT');
		$var = $id->value;
		if ( !$self->_lookup($var) and !$self->_has_wildcard_import_in_scope ) {
			$self->_err("Use of undeclared identifier '$var' (compile-time)", $id);
		}
		$self->_eat('KW', 'in');
		$col = $self->parse_expression;
	}
	else {
		$id = $self->{tok};
		$var = '^^';
		$declares_loop_var = 1;
		$loop_var_kind = 'const';
		$col = $self->parse_expression;
	}
	$self->_eat('OP', ')');

	my $body;
	if ($declares_loop_var) {
		# Loop variable is scoped to body only when declared in header.
		$self->_push_scope;
		if ( $var ne '^^' ) {
			$self->_declare(
				$var,
				{
					kind => $loop_var_kind,
					mutable => ( $loop_var_kind eq 'let' ? 1 : 0 ),
				},
				$id
			);
		}
		$body = $self->parse_block;
		$self->_pop_scope;
	}
	else {
		$body = $self->parse_block;
	}

	my $else_block;
	if ($self->{tok}->is_KW && $self->{tok}->value eq 'else') {
		$self->_eat('KW', 'else');
		$else_block = $self->parse_block;
	}

	return Zuzu::AST::Stmt::For->new(
		file => $kw->file, line => $kw->line,
		var => $var,
		declare_loop_var => $declares_loop_var,
		loop_var_kind => $loop_var_kind,
		collection => $col,
		body => $body,
		else_block => $else_block
	);
}

sub parse_switch {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'switch');
	$self->_eat('OP', '(');
	my $value_expr = $self->parse_expression;
	my $comparator = '==';
	if ( $self->_maybe('OP', ':') ) {
		my $tok = $self->{tok};
		if ( $tok->is_OP or $tok->is_KW or $tok->is_IDENT ) {
			$comparator = $tok->value;
			$self->{tok} = $self->{lexer}->next_token;
		}
		else {
			$self->_err("Expected switch comparator operator", $tok);
		}
	}
	$self->_eat('OP', ')');
	$self->_eat('OP', '{');

	my @cases;
	my $default_block;

	while ( ! $self->{tok}->is_OP('}') ) {
		$self->_err("Unterminated switch", $self->{tok}) if $self->{tok}->is_EOF;
		if ( $self->{tok}->is_KW('case') ) {
			my $case_kw = $self->_eat('KW', 'case');
			my @values = ( $self->parse_expression );
			while ( $self->_maybe('OP', ',') ) {
				push @values, $self->parse_expression;
			}
			$self->_eat('OP', ':');
			my $body = $self->_parse_switch_body_until_labels;
			push @cases, {
				file => $case_kw->file,
				line => $case_kw->line,
				values => \@values,
				body => $body,
			};
			next;
		}
		if ( $self->{tok}->is_KW('default') ) {
			my $default_kw = $self->_eat('KW', 'default');
			$self->_err("Duplicate default case in switch", $default_kw) if defined $default_block;
			$self->_eat('OP', ':');
			$default_block = $self->_parse_switch_body_until_end;
			next;
		}
		$self->_err("Expected 'case', 'default', or '}' in switch", $self->{tok});
	}

	$self->_eat('OP', '}');

	return Zuzu::AST::Stmt::Switch->new(
		file => $kw->file,
		line => $kw->line,
		value_expr => $value_expr,
		comparator => $comparator,
		cases => \@cases,
		default_block => $default_block,
	);
}

sub _parse_switch_body_until_labels {
	my ($self) = @_;

	my @stmts;
	while ( 1 ) {
		last if $self->{tok}->is_OP('}');
		last if $self->{tok}->is_KW('case');
		last if $self->{tok}->is_KW('default');
		$self->_eat_optional_statement_separators;
		last if $self->{tok}->is_OP('}');
		last if $self->{tok}->is_KW('case');
		last if $self->{tok}->is_KW('default');
		push @stmts, $self->parse_statement;
	}

	return Zuzu::AST::Block->new(
		file => @stmts ? $stmts[0]->file : $self->{tok}->file,
		line => @stmts ? $stmts[0]->line : $self->{tok}->line,
		statements => \@stmts,
	);
}

sub _parse_switch_body_until_end {
	my ($self) = @_;

	my @stmts;
	while ( ! $self->{tok}->is_OP('}') ) {
		$self->_err("Unterminated switch", $self->{tok}) if $self->{tok}->is_EOF;
		$self->_eat_optional_statement_separators;
		last if $self->{tok}->is_OP('}');
		push @stmts, $self->parse_statement;
	}

	return Zuzu::AST::Block->new(
		file => @stmts ? $stmts[0]->file : $self->{tok}->file,
		line => @stmts ? $stmts[0]->line : $self->{tok}->line,
		statements => \@stmts,
	);
}

sub parse_try {
	my ( $self ) = @_;

	my $kw = $self->_eat('KW', 'try');
	my $block = $self->parse_block;
	my @catches;
	while ( $self->_maybe('KW', 'catch') ) {
		my ( $type_expr, $name );
		if ( $self->_maybe('OP', '(') ) {
			if ( $self->_maybe('OP', ')') ) {
				$type_expr = Zuzu::AST::Expr::TypeRef->new(
					file => $kw->file,
					line => $kw->line,
					root => 'Exception',
					member => undef,
				);
				$name = 'e';
			}
			else {
				my $first = $self->_eat('IDENT');
				if ( $self->_maybe('OP', ')') ) {
					$type_expr = Zuzu::AST::Expr::TypeRef->new(
						file => $first->file,
						line => $first->line,
						root => 'Exception',
						member => undef,
					);
					$name = $first->value;
				}
				else {
					my $info = $self->_lookup( $first->value );
					if ( !$info and !$self->_has_wildcard_import_in_scope ) {
						$self->_err("Use of undeclared identifier '".$first->value."' (compile-time)", $first);
					}
					$type_expr = Zuzu::AST::Expr::TypeRef->new(
						file => $first->file,
						line => $first->line,
						root => $first->value,
						member => undef,
					);
					$name = $self->_eat('IDENT')->value;
					$self->_eat('OP', ')');
				}
			}
		}
		else {
			$type_expr = Zuzu::AST::Expr::TypeRef->new(
				file => $kw->file,
				line => $kw->line,
				root => 'Exception',
				member => undef,
			);
			$name = 'e';
		}
		$self->_push_scope;
		$self->_declare($name, { kind => 'let', mutable => 1 }, $kw);
		my $catch_block = $self->parse_block;
		$self->_pop_scope;
		push @catches, Zuzu::AST::Stmt::Catch->new(
			file => $kw->file,
			line => $kw->line,
			type_expr => $type_expr,
			name => $name,
			block => $catch_block,
		);
	}

	$self->_err("try requires at least one catch clause", $self->{tok}) if !@catches;

	return Zuzu::AST::Stmt::Try->new(
		file => $kw->file,
		line => $kw->line,
		block => $block,
		catches => \@catches,
	);
}

sub parse_return {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'return');
	my $expr;
	$expr = $self->parse_expression unless (
		$self->{tok}->is_OP(';')
		or $self->{tok}->is_OP('}')
		or $self->{tok}->is_EOF
		or $self->{tok}->is_KW('if')
		or $self->{tok}->is_KW('unless')
	);
	my $stmt = Zuzu::AST::Stmt::Return->new(file => $kw->file, line => $kw->line, expr => $expr);

	return $self->_finish_with_postfix_condition($stmt);
}

sub parse_import {
	my ($self) = @_;

	my $kw = $self->_eat('KW', 'from');
	my $mod_tok = $self->_eat('IDENT');
	my $module = $mod_tok->value;

	while ($self->_maybe('OP', '/')) {
		if ( $self->{tok}->is_OP and $self->{tok}->value eq '.' ) {
			$self->_err(
				"Import module path cannot contain '..' segments",
				$self->{tok},
			);
		}
		my $seg = $self->_eat_import_path_segment;
		$module .= '/' . $seg->value;
	}

	my $try_mode = $self->_maybe('KW', 'try') ? 1 : 0;
	$self->_eat('KW', 'import');

	my @items;
	my $saw_star = 0;
	while (1) {
		if ( $self->_maybe('OP', '*') ) {
			push @items, { star => 1 };
			$saw_star = 1;
		}
		else {
			my $name = $self->_eat('IDENT')->value;
			my $alias = $name;
			if ( $self->{tok}->is_KW and $self->{tok}->value eq 'as' ) {
				$self->_eat('KW', 'as');
				$alias = $self->_eat('IDENT')->value;
			}
			push @items, { name => $name, alias => $alias };
		}
		last if !$self->_maybe('OP', ',');
		next if $self->{tok}->is_OP and $self->{tok}->value eq ';';
	}

	my $condition_expr;
	my $condition_positive = 1;
	if ( $self->{tok}->is_KW('if') ) {
		$self->_eat('KW', 'if');
		$condition_expr = $self->parse_expression;
	}
	elsif ( $self->{tok}->is_KW('unless') ) {
		$self->_eat('KW', 'unless');
		$condition_positive = 0;
		$condition_expr = $self->parse_expression;
	}

	if ( $saw_star and ( $try_mode or defined $condition_expr ) ) {
		$self->_err(
			"Wildcard import '*' cannot be combined with try import or postfix if/unless",
			$self->{tok},
		);
	}

	$self->_mark_wildcard_import_in_scope if $saw_star;
	$self->_eat_statement_separator;

	# Declare imported aliases at compile-time as "import" (mutable depends on source at runtime)
	for my $it (@items) {
		next if $it->{star};
		$self->_declare(
			$it->{alias},
			{ kind => 'import', mutable => 1 },
			$kw,
			{ allow_builtin_shadow => 1 },
		);
	}

	return Zuzu::AST::Stmt::Import->new(
		file => $kw->file,
		line => $kw->line,
		module => $module,
		items => \@items,
		try_mode => $try_mode,
		condition_expr => $condition_expr,
		condition_positive => $condition_positive,
	);
}

sub _eat_import_path_segment {
	my ( $self ) = @_;

	return $self->_eat('IDENT')
		if $self->{tok}->is_IDENT;
	return $self->_eat('KW')
		if $self->{tok}->is_KW;

	return $self->_eat('IDENT');
}

# Expression parsing (Pratt)

sub parse_expression {
	my ($self) = @_;

	my $cond = $self->parse_chain_expression;

	my $assign_op = $self->_maybe('OP', ':=')
		|| $self->_maybe('OP', '~=')
		|| $self->_maybe('OP', '+=')
		|| $self->_maybe('OP', '-=')
		|| $self->_maybe('OP', '*=')
		|| $self->_maybe('OP', '×=')
		|| $self->_maybe('OP', '/=')
		|| $self->_maybe('OP', '÷=')
		|| $self->_maybe('OP', '**=')
		|| $self->_maybe('OP', '_=')
		|| $self->_maybe('OP', '?:=');
	if ( $assign_op ) {
		$self->_assert_mutable_target( $cond, $assign_op );
		if ( $assign_op->value eq '~=' ) {
			my $match_expr = $self->parse_expression;
			my $arrow = $self->_maybe( 'OP', '->' ) || $self->_maybe( 'OP', '→' );
			$self->_err( "Regexp replacement expects '->' or '→'", $self->{tok} ) if ! $arrow;
			$self->_push_scope;
			$self->_declare( 'm', { mutable => 0 }, $arrow );
			my $replace_expr = $self->parse_expression;
			$self->_pop_scope;

			return Zuzu::AST::Stmt::Assign->new(
				file => $assign_op->file,
				line => $assign_op->line,
				target => $cond,
				op => $assign_op->value,
				match_expr => $match_expr,
				replace_expr => $replace_expr,
			);
			}
			my $rhs = $self->parse_expression;
			my $is_weak_write = $self->_parse_optional_weak_modifier('assignment');
			if ( $is_weak_write and $assign_op->value ne ':=' ) {
				$self->_err("but weak is only valid on ':=' assignments", $assign_op);
			}
			if (
				$is_weak_write
				and blessed($cond)
				and $cond->isa('Zuzu::AST::Expr::Binary')
				and defined $cond->op
				and $cond->op eq '@?'
			) {
				$self->_err("but weak is not valid on @? path assignments", $assign_op);
			}

			return Zuzu::AST::Stmt::Assign->new(
				file => $assign_op->file,
				line => $assign_op->line,
				target => $cond,
				op => $assign_op->value,
				expr => $rhs,
				is_weak_write => $is_weak_write ? 1 : 0,
			);
		}

	return $cond;
}

sub parse_ternary_expression {
	my ($self) = @_;

	my $cond = $self->_parse_prec(0);

	if ( $self->_maybe('OP', '?') ) {
		my $if_true = $self->parse_expression;
		$self->_eat('OP', ':');
		my $if_false = $self->parse_expression;

		return Zuzu::AST::Expr::Ternary->new(
			file => $cond->file,
			line => $cond->line,
			cond => $cond,
			if_true => $if_true,
			if_false => $if_false,
		);
	}

	if ( $self->_maybe('OP', '?:') ) {
		my $if_false = $self->parse_expression;

		return Zuzu::AST::Expr::Ternary->new(
			file => $cond->file,
			line => $cond->line,
			cond => $cond,
			if_true => undef,
			if_false => $if_false,
		);
	}

	return $cond;
}

sub _chain_direction {
	my ( $self, $op ) = @_;

	return 'right' if $op eq '▷' or $op eq '|>';
	return 'left'  if $op eq '◁' or $op eq '<|';

	return undef;
}

sub parse_chain_expression {
	my ($self) = @_;

	my $left = $self->parse_ternary_expression;
	my $op_tok = $self->{tok};
	return $left if !$op_tok->is_OP;

	my $direction = $self->_chain_direction( $op_tok->value );
	return $left if !$direction;

	$self->{tok} = $self->{lexer}->next_token;
	my $right = $direction eq 'left'
		? $self->_parse_leftward_chain_rhs
		: $self->parse_ternary_expression;
	$left = Zuzu::AST::Expr::Binary->new(
		file => $op_tok->file,
		line => $op_tok->line,
		op => $op_tok->value,
		left => $left,
		right => $right,
	);

	while ( $direction eq 'right' and $self->{tok}->is_OP ) {
		my $next_dir = $self->_chain_direction( $self->{tok}->value );
		last if !$next_dir;
		$self->_err("Mixed chain directions require parentheses", $self->{tok})
			if $next_dir ne $direction;
		$op_tok = $self->{tok};
		$self->{tok} = $self->{lexer}->next_token;
		$right = $self->parse_ternary_expression;
		$left = Zuzu::AST::Expr::Binary->new(
			file => $op_tok->file,
			line => $op_tok->line,
			op => $op_tok->value,
			left => $left,
			right => $right,
		);
	}

	if ( $direction eq 'left' and $self->{tok}->is_OP ) {
		my $next_dir = $self->_chain_direction( $self->{tok}->value );
		$self->_err("Mixed chain directions require parentheses", $self->{tok})
			if defined $next_dir;
	}

	return $left;
}

sub _parse_leftward_chain_rhs {
	my ($self) = @_;

	my $left = $self->parse_ternary_expression;
	my $op_tok = $self->{tok};
	return $left if !$op_tok->is_OP;

	my $direction = $self->_chain_direction( $op_tok->value );
	return $left if !$direction;
	$self->_err("Mixed chain directions require parentheses", $op_tok)
		if $direction ne 'left';

	$self->{tok} = $self->{lexer}->next_token;
	my $right = $self->_parse_leftward_chain_rhs;

	return Zuzu::AST::Expr::Binary->new(
		file => $op_tok->file,
		line => $op_tok->line,
		op => $op_tok->value,
		left => $left,
		right => $right,
	);
}

sub _prec {
	my ($self, $op) = @_;

	return 1 if $op eq 'or' || $op eq '⋁';

	return 2 if $op eq 'xor' || $op eq '⊻';

	return 3 if $op eq 'and' || $op eq '⋀' || $op eq 'nand' || $op eq '⊼';

	return 4 if $op eq 'default';

	return 4 if $op eq '==' || $op eq '≡' || $op eq '!=' || $op eq '≢';

	return 5 if $op eq '=' || $op eq '≠' || $op eq '<' || $op eq '>' || $op eq '<=' || $op eq '≤' || $op eq '>=' || $op eq '≥' || $op eq '<=>' || $op eq '≶' || $op eq '≷' || $op eq 'eq' || $op eq 'ne' || $op eq 'gt' || $op eq 'ge' || $op eq 'lt' || $op eq 'le' || $op eq 'cmp' || $op eq 'eqi' || $op eq 'nei' || $op eq 'gti' || $op eq 'gei' || $op eq 'lti' || $op eq 'lei' || $op eq 'cmpi' || $op eq 'in' || $op eq '∈' || $op eq '∉' || $op eq 'subsetof' || $op eq '⊂' || $op eq 'supersetof' || $op eq '⊃' || $op eq 'equivalentof' || $op eq '⊂⊃' || $op eq 'instanceof' || $op eq 'does' || $op eq 'can' || $op eq '~' || $op eq '@' || $op eq '@?' || $op eq '@@';

	return 6 if $op eq '|';

	return 7 if $op eq '^';

	return 8 if $op eq '&';

	return 9 if $op eq 'union' || $op eq '⋃' || $op eq 'intersection' || $op eq '⋂' || $op eq '\\' || $op eq '∖';

	return 10 if $op eq '_' ;

	return 11 if $op eq '+' || $op eq '-' ;

	return 12 if $op eq '*' || $op eq '/' || $op eq '×' || $op eq '÷' || $op eq 'mod';

	return 13 if $op eq '**';

	return 0;
}

sub _parse_prec {
	my ($self, $min_prec) = @_;

	my $t = $self->{tok};
	my $left = $self->parse_prefix;

	while (1) {
		my $op_tok = $self->{tok};
		my $op;

		if ($op_tok->is_OP || $op_tok->is_KW) {
			$op = $op_tok->value;
		} else {
			last;
		}

		# stop at statement terminators / closers
		last if $op_tok->is_OP && ($op eq ';' || $op eq ')' || $op eq ']' || $op eq '}' || $op eq ',' || $op eq ':');

		my $prec = $self->_prec($op);
		last if $prec < $min_prec || $prec == 0;

		# right-assoc power
		my $next_min = ($op eq '**') ? $prec : ($prec + 1);

		$self->{tok} = $self->{lexer}->next_token; # consume op
		my $right;
		if ( $op eq 'can' and ( $self->{tok}->is_IDENT or $self->{tok}->is_KW ) ) {
			my $name_tok = $self->{tok};
			$self->{tok} = $self->{lexer}->next_token;
			$right = Zuzu::AST::Expr::Literal->new(
				file => $name_tok->file,
				line => $name_tok->line,
				value => $name_tok->value,
			);
		}
		else {
			$right = $self->_parse_prec($next_min);
		}

		$left = Zuzu::AST::Expr::Binary->new(
			file => $op_tok->file, line => $op_tok->line,
			op => $op, left => $left, right => $right
		);
	}

	return $left;
}

sub parse_prefix {
	my ($self) = @_;

	my $t = $self->{tok};

	if ( $t->is_OP and ( $t->value eq '->' or $t->value eq '→' ) ) {
		my $arrow = $self->_eat('OP');
		my $expr = $self->parse_expression;
		my $ret = Zuzu::AST::Stmt::Return->new(
			file => $arrow->file,
			line => $arrow->line,
			expr => $expr,
		);
		my $body = Zuzu::AST::Block->new(
			file => $arrow->file,
			line => $arrow->line,
			statements => [ $ret ],
		);

		return Zuzu::AST::Expr::Function->new(
			file => $arrow->file,
			line => $arrow->line,
			params => [ '^^' ],
			vararg => undef,
			body => $body,
			param_types => { '^^' => 'Any' },
			vararg_type => 'Any',
			named_vararg => undef,
			named_vararg_type => 'PairList',
			param_optional => { '^^' => 1 },
			param_defaults => {},
			return_type => 'Any',
			is_async => 0,
		);
	}

	if (
		$t->is_OP
		and (
			$t->value eq '+'
			or $t->value eq '-'
			or $t->value eq '!'
			or $t->value eq '¬'
			or $t->value eq '~'
			or $t->value eq '√'
			or $t->value eq '\\'
		)
	) {
		$self->{tok} = $self->{lexer}->next_token;
		my $expr = $self->parse_prefix;
		if ( $t->value eq '\\' ) {
			$self->_assert_reference_target( $expr, $t );
		}

		return Zuzu::AST::Expr::Unary->new(file => $t->file, line => $t->line, op => $t->value, expr => $expr);
	}
	if ( $t->is_KW and $t->value eq 'not' ) {
		$self->{tok} = $self->{lexer}->next_token;
		my $expr = $self->parse_prefix;

		return Zuzu::AST::Expr::Unary->new(file => $t->file, line => $t->line, op => 'not', expr => $expr);
	}
	if ( $t->is_KW('let') or $t->is_KW('const') ) {
		return $self->_parse_let_decl(0);
	}
	if ( $t->is_KW('try') ) {
		return $self->parse_try;
	}
	if ( $t->is_KW('await') ) {
		my $kw = $self->_eat( 'KW', 'await' );
		$self->_err("await may only be used inside async code", $kw)
			if !( $self->{_async_context_depth} // 0 );
		my $block = $self->parse_block;

		return Zuzu::AST::Expr::Await->new(
			file => $kw->file,
			line => $kw->line,
			block => $block,
		);
	}
	if ( $t->is_KW('spawn') ) {
		my $kw = $self->_eat( 'KW', 'spawn' );
		my $block = $self->parse_block;

		return Zuzu::AST::Expr::Spawn->new(
			file => $kw->file,
			line => $kw->line,
			block => $block,
		);
	}
	if ( $t->is_KW('do') ) {
		$self->_eat( 'KW', 'do' );

		return $self->parse_block;
	}
	if ( $t->is_KW('async') ) {
		my $kw = $self->_eat( 'KW', 'async' );
		$self->_err("Expected function or fn after async", $self->{tok})
			if !$self->{tok}->is_KW('function')
			and !$self->{tok}->is_KW('fn');
		local $self->{_next_function_expr_async} = 1;
		my $prim = $self->parse_primary;

		return $self->parse_postfix($prim);
	}
	if (
		$t->is_KW
		and (
			$t->value eq 'abs'
			or $t->value eq 'sqrt'
			or $t->value eq 'floor'
			or $t->value eq 'ceil'
			or $t->value eq 'round'
			or $t->value eq 'int'
			or $t->value eq 'uc'
			or $t->value eq 'lc'
			or $t->value eq 'length'
			or $t->value eq 'typeof'
		)
	) {
		$self->{tok} = $self->{lexer}->next_token;
		my $expr = $self->parse_prefix;

		return Zuzu::AST::Expr::Unary->new(
			file => $t->file,
			line => $t->line,
			op => $t->value,
			expr => $expr,
		);
	}
	if ($t->is_OP && ($t->value eq '++' || $t->value eq '--')) {
		$self->{tok} = $self->{lexer}->next_token;
		my $target = $self->parse_prefix;
		$self->_assert_mutable_target($target, $t);

		return Zuzu::AST::Expr::IncDec->new(
			file => $t->file,
			line => $t->line,
			op => $t->value,
			target => $target,
			postfix => 0,
		);
	}

	my $prim = $self->parse_primary;

	return $self->parse_postfix($prim);
}

sub parse_primary {
	my ($self) = @_;

	my $t = $self->{tok};

	if ($t->is_NUMBER) {
		$self->{tok} = $self->{lexer}->next_token;
		my $v = $t->value;
		$v = ($v =~ /\./) ? 0.0 + $v : 0 + $v;

		return Zuzu::AST::Expr::Literal->new(file => $t->file, line => $t->line, value => $v);
	}
	if ($t->is_STRING) {
		$self->{tok} = $self->{lexer}->next_token;

		return Zuzu::AST::Expr::Literal->new(file => $t->file, line => $t->line, value => $t->value);
	}
	if ( $t->is_type('BINARY_STRING') ) {
		$self->{tok} = $self->{lexer}->next_token;

		return Zuzu::AST::Expr::Literal->new(
			file => $t->file,
			line => $t->line,
			value => Zuzu::Value::BinaryString->new( bytes => $t->value ),
		);
	}
	if ( $t->is_type('TEMPLATE') ) {
		$self->{tok} = $self->{lexer}->next_token;

		return $self->_parse_template_expression($t);
	}
		if ($t->is_REGEXP) {
			$self->{tok} = $self->{lexer}->next_token;
			my $spec = $t->value // {};
			my $parts = $spec->{parts} // [ { text => $spec->{pattern} // '' } ];
			if ( grep { ref $_ eq 'HASH' and exists $_->{expr} } @{$parts} ) {
				my @parsed_parts = map {
					ref $_ eq 'HASH' && exists $_->{expr}
						? { expr => $self->_parse_embedded_expression( $_->{expr}, $t ) }
						: $_
				} @{$parts};
				return Zuzu::AST::Expr::Regexp->new(
					file => $t->file,
					line => $t->line,
					parts => \@parsed_parts,
					flags => $spec->{flags} // '',
				);
			}

			return Zuzu::AST::Expr::Literal->new(
				file => $t->file,
			line => $t->line,
			value => Zuzu::Value::Regexp->new(
				pattern => $spec->{pattern} // '',
				flags => $spec->{flags} // '',
			),
		);
	}
	if ($t->is_BOOL) {
		$self->{tok} = $self->{lexer}->next_token;

		return Zuzu::AST::Expr::Literal->new(
			file => $t->file,
			line => $t->line,
			value => Zuzu::Value::Boolean->new( value => $t->value ? 1 : 0 ),
		);
	}
	if ($t->is_NULL) {
		$self->{tok} = $self->{lexer}->next_token;

		return Zuzu::AST::Expr::Literal->new(file => $t->file, line => $t->line, value => undef);
	}
	if ($t->is_IDENT) {
		my $id = $self->_eat('IDENT');
		my $name = $id->value;
		my $info = $self->_lookup($name);
		my $is_named_arg_label
			= ( $self->{_invocation_arg_depth} // 0 )
			and $self->{tok}->is_OP(':');
		my $is_chain_placeholder = $name eq '^^';
		if ( !$info and !$is_chain_placeholder and !$self->_has_wildcard_import_in_scope and !$is_named_arg_label ) {
			$self->_err("Use of undeclared identifier '$name' (compile-time)", $id);
		}

		return Zuzu::AST::Expr::Var->new(file => $id->file, line => $id->line, name => $name);
	}
	if ($t->is_KW('self')) {
		my $id = $self->_eat('KW', 'self');
		my $name = $id->value;
		my $info = $self->_lookup($name);
		$self->_err("Use of undeclared identifier '$name' (compile-time)", $id) if !$info;

		return Zuzu::AST::Expr::Var->new(file => $id->file, line => $id->line, name => $name);
	}
	if ($t->is_KW('super')) {
		my $id = $self->_eat('KW', 'super');
		my $name = $id->value;
		my $info = $self->_lookup($name);
		$self->_err("Use of undeclared identifier '$name' (compile-time)", $id) if !$info;

		return Zuzu::AST::Expr::Var->new(file => $id->file, line => $id->line, name => $name);
	}
	if ($t->is_OP && $t->value eq '(') {
		$self->_eat('OP', '(');
		my $e = $self->parse_expression;
		$self->_eat('OP', ')');

		return $e;
	}
	if ( $t->is_OP('...') ) {
		$self->_err("Spread argument '...' is only valid in call argument lists", $t);
	}
	if ( $t->is_OP('⌊') ) {
		my $tok = $self->_eat('OP', '⌊');
		my $expr = $self->parse_expression;
		$self->_eat('OP', '⌋');

		return Zuzu::AST::Expr::Unary->new(
			file => $tok->file,
			line => $tok->line,
			op => 'floor',
			expr => $expr,
		);
	}
	if ( $t->is_OP('⌈') ) {
		my $tok = $self->_eat('OP', '⌈');
		my $expr = $self->parse_expression;
		$self->_eat('OP', '⌉');

		return Zuzu::AST::Expr::Unary->new(
			file => $tok->file,
			line => $tok->line,
			op => 'ceil',
			expr => $expr,
		);
	}
	if ($t->is_OP && $t->value eq '[') {

		return $self->parse_array_literal;
	}
	if ($t->is_OP('<<') or $t->is_OP('«')) {

		return $self->parse_set_literal;
	}
	if ($t->is_OP('<<<')) {

		return $self->parse_bag_literal;
	}
	if ($t->is_EMPTY_SET) {
		my $tok = $self->_eat('EMPTY_SET');

		return Zuzu::AST::Expr::Set->new(
			file => $tok->file,
			line => $tok->line,
			items => [],
		);
	}
	if ($t->is_OP && $t->value eq '{') {

		return $self->parse_dict_literal;
	}
	if ( $t->is_OP('{{') ) {

		return $self->parse_pairlist_literal;
	}
	if ($t->is_KW('new')) {
		my $kw = $self->_eat('KW', 'new');
		my $class_expr = $self->parse_primary;
		while (1) {
			if ( $self->{tok}->is_OP('.') ) {
				my $dot = $self->_eat('OP', '.');
				my $m = $self->_eat_member_name;
				$class_expr = Zuzu::AST::Expr::MemberCall->new(
					file => $dot->file,
					line => $dot->line,
					object => $class_expr,
					method => $m,
					args => [],
				);
				next;
			}
			if ( $self->{tok}->is_OP('{') ) {
				my $lb = $self->_eat('OP', '{');
				my $key = $self->_parse_dict_key_expr;
				$self->_eat('OP', '}');
				$class_expr = Zuzu::AST::Expr::DictGet->new(file => $lb->file, line => $lb->line, dict => $class_expr, key => $key);
				next;
			}
			last;
		}
		my @traits;
		if ( $self->{tok}->is_KW('with') or $self->{tok}->is_KW('but') ) {
			$self->_eat('KW');
			push @traits, $self->parse_type_ref;
			while ( $self->_maybe('OP', ',') ) {
				push @traits, $self->parse_type_ref;
			}
		}
		$self->_eat('OP', '(');
		my @args = $self->_parse_invocation_args;
		$self->_eat('OP', ')');

		return Zuzu::AST::Expr::New->new(
			file => $kw->file,
			line => $kw->line,
			class_expr => $class_expr,
			traits => \@traits,
			args => \@args,
		);
	}
	if ($t->is_KW('function')) {
		my $kw = $self->_eat('KW', 'function');
		my $is_async = $self->{_next_function_expr_async} ? 1 : 0;
		my ( $params, $vararg, $param_types, $vararg_type, $param_optional, $param_defaults, $named_vararg, $named_vararg_type ) = $self->_parse_param_list;
		my $return_type = $self->_parse_optional_return_type;
		my @arg_decls = map {
			{
				name => $_,
				mutable => 0,
				declared_type => $param_types->{$_} // 'Any',
			}
		} @{ $params // [] };
		if ( defined $vararg ) {
			push @arg_decls, {
				name => $vararg,
				mutable => 0,
				declared_type => $vararg_type // 'Any',
			};
		}
		if ( defined $named_vararg ) {
			push @arg_decls, {
				name => $named_vararg,
				mutable => 0,
				declared_type => $named_vararg_type // 'PairList',
			};
		}
		my $body = $self->_parse_block_in_async_context(
			$is_async,
			\@arg_decls,
			[],
		);

		return Zuzu::AST::Expr::Function->new(
			file => $kw->file,
			line => $kw->line,
			params => $params,
			vararg => $vararg,
			body => $body,
			param_types => $param_types,
			vararg_type => $vararg_type,
			named_vararg => $named_vararg,
			named_vararg_type => $named_vararg_type,
			param_optional => $param_optional,
			param_defaults => $param_defaults,
			return_type => $return_type,
			is_async => $is_async,
		);
	}
	if ($t->is_KW('fn')) {
		my $kw = $self->_eat('KW', 'fn');
		my $is_async = $self->{_next_function_expr_async} ? 1 : 0;
		my ( $params, $vararg, $param_types, $vararg_type, $param_optional, $param_defaults, $named_vararg, $named_vararg_type );
		if ( $self->{tok}->is_IDENT ) {
			my ( $type_name, $param_name ) = $self->_parse_param_name;
			$params = [ $param_name ];
			$vararg = undef;
			$param_types = { $param_name => $type_name };
			$vararg_type = 'Any';
			$param_optional = {};
			$param_defaults = {};
			$named_vararg = undef;
			$named_vararg_type = 'PairList';
		}
		elsif ( $self->{tok}->is_OP('(') ) {
			( $params, $vararg, $param_types, $vararg_type, $param_optional, $param_defaults, $named_vararg, $named_vararg_type ) = $self->_parse_param_list;
		}
		else {
			$self->_err("Expected identifier or '(' after fn", $self->{tok});
		}

		if ( ! $self->_maybe('OP', '->') ) {
			$self->_eat('OP', '→');
		}

		$self->_push_scope;
		for my $n ( @{ $params // [] } ) {
			$self->_declare(
				$n,
				{
					kind => 'local',
					mutable => 0,
					declared_type => $param_types->{$n} // 'Any',
				},
				$kw,
			);
		}
		if ( defined $vararg ) {
			$self->_declare(
				$vararg,
				{
					kind => 'local',
					mutable => 0,
					declared_type => $vararg_type // 'Any',
				},
				$kw,
			);
		}
		if ( defined $named_vararg ) {
			$self->_declare(
				$named_vararg,
				{
					kind => 'local',
					mutable => 0,
					declared_type => $named_vararg_type // 'PairList',
				},
				$kw,
			);
		}
		my $expr;
		if ( $is_async ) {
			local $self->{_async_context_depth} =
				( $self->{_async_context_depth} // 0 ) + 1;
			$expr = $self->parse_expression;
		}
		else {
			local $self->{_async_context_depth} = 0;
			$expr = $self->parse_expression;
		}
		$self->_pop_scope;
		my $ret = Zuzu::AST::Stmt::Return->new(
			file => $kw->file,
			line => $kw->line,
			expr => $expr,
		);
		my $body = Zuzu::AST::Block->new(
			file => $kw->file,
			line => $kw->line,
			statements => [ $ret ],
		);

		return Zuzu::AST::Expr::Function->new(
			file => $kw->file,
			line => $kw->line,
			params => $params,
			vararg => $vararg,
			body => $body,
			param_types => $param_types,
			vararg_type => $vararg_type,
			named_vararg => $named_vararg,
			named_vararg_type => $named_vararg_type,
			param_optional => $param_optional,
			param_defaults => $param_defaults,
			return_type => 'Any',
			is_async => $is_async,
		);
	}

	$self->_err("Unexpected token in expression: ".$t->type." ".($t->value // ''), $t);
}

sub _parse_template_expression {
	my ( $self, $tok ) = @_;

	my @parts = ref( $tok->value ) eq 'ARRAY'
		? @{ $tok->value }
		: $self->_split_template_parts( $tok->value // '', $tok );
	my $expr;

	for my $part ( @parts ) {
		my $piece;
		if ( ref $part eq 'HASH' and exists $part->{expr} ) {
			$piece = $self->_parse_embedded_expression( $part->{expr}, $tok );
		}
		else {
			my $text = ref $part eq 'HASH' && exists $part->{text}
				? $part->{text}
				: $part;
			$piece = Zuzu::AST::Expr::Literal->new(
				file => $tok->file,
				line => $tok->line,
				value => $text,
			);
		}
		if ( ! defined $expr ) {
			$expr = $piece;
			next;
		}
		$expr = Zuzu::AST::Expr::Binary->new(
			file => $tok->file,
			line => $tok->line,
			op => '_',
			left => $expr,
			right => $piece,
		);
	}

	return $expr // Zuzu::AST::Expr::Literal->new(
		file => $tok->file,
		line => $tok->line,
		value => '',
	);
}

sub _split_template_parts {
	my ( $self, $src, $tok ) = @_;

	my @parts;
	my $text = '';
	my $i = 0;
	my $len = length $src;

	while ( $i < $len ) {
		my $ch = substr( $src, $i, 1 );
		if ( $ch eq '$' and $i + 1 < $len and substr( $src, $i + 1, 1 ) eq '{' ) {
			push @parts, $text if $text ne '';
			$text = '';
			$i += 2;
			my $start = $i;
			my $depth = 1;
			my $in_string = 0;
			my $escaped = 0;
			while ( $i < $len ) {
				my $c = substr( $src, $i, 1 );
				if ( $in_string ) {
					if ( $escaped ) {
						$escaped = 0;
					}
					elsif ( $c eq '\\' ) {
						$escaped = 1;
					}
					elsif ( $c eq '"' ) {
						$in_string = 0;
					}
					$i++;
					next;
				}
				if ( $c eq '"' ) {
					$in_string = 1;
					$i++;
					next;
				}
				if ( $c eq '{' ) {
					$depth++;
					$i++;
					next;
				}
				if ( $c eq '}' ) {
					$depth--;
					last if $depth == 0;
					$i++;
					next;
				}
				$i++;
			}
			$self->_err( "Unterminated template interpolation", $tok ) if $i >= $len;
			my $expr_src = substr( $src, $start, $i - $start );
			push @parts, { expr => $expr_src };
			$i++;
			next;
		}
		$text .= $ch;
		$i++;
	}

	push @parts, $text if $text ne '' or !@parts;

	return @parts;
}

sub _parse_embedded_expression {
	my ( $self, $src, $tok ) = @_;

	my $lexer = Zuzu::Lexer->new(
		src => $src,
		filename => $tok->file,
	);
	my $parser = __PACKAGE__->new(
		lexer => $lexer,
		filename => $tok->file,
		scopes => $self->{scopes},
	);
	my $expr = $parser->parse_expression;
	$parser->_err( "Unexpected trailing tokens in template interpolation", $parser->{tok} ) if ! $parser->{tok}->is_EOF;

	return $expr;
}

sub parse_postfix {
	my ($self, $expr) = @_;

	while (1) {
		my $t = $self->{tok};

		# function call
		if ($t->is_OP && $t->value eq '(') {
			my $lp = $self->_eat('OP', '(');
			my @args = $self->_parse_invocation_args;
			$self->_eat('OP', ')');
			$expr = Zuzu::AST::Expr::Call->new(file => $lp->file, line => $lp->line, callee => $expr, args => \@args);
			next;
		}

		# member call: obj.method(...) or obj.method (no-arg call handled at runtime by allowing method without ())
		if ($t->is_OP && $t->value eq '.') {
			my $dot = $self->_eat('OP', '.');
			if ( $self->_maybe('OP', '(') ) {
				my $method_expr = $self->parse_expression;
				$self->_eat('OP', ')');
				$self->_eat('OP', '(');
				my @args = $self->_parse_invocation_args;
				$self->_eat('OP', ')');
				$expr = Zuzu::AST::Expr::DynamicMemberCall->new(
					file => $dot->file,
					line => $dot->line,
					object => $expr,
					method_expr => $method_expr,
					args => \@args,
				);
				next;
			}
			my $method = $self->_eat_member_name;
			my @args;
			if ($self->{tok}->is_OP && $self->{tok}->value eq '(') {
				$self->_eat('OP', '(');
				@args = $self->_parse_invocation_args;
				$self->_eat('OP', ')');
			}
			$expr = Zuzu::AST::Expr::MemberCall->new(
				file => $dot->file, line => $dot->line,
				object => $expr, method => $method, args => \@args
			);
			next;
		}

		# index: a[expr]
		if ($t->is_OP && $t->value eq '[') {
			my $lb = $self->_eat('OP', '[');
			my ( $first, $is_slice );
			if ( ! $self->{tok}->is_OP(':') and ! $self->{tok}->is_OP(']') ) {
				$first = $self->parse_expression;
			}
			if ( $self->_maybe('OP', ':') ) {
				$is_slice = 1;
			}
			if ( $is_slice ) {
				my $length;
				if ( ! $self->{tok}->is_OP(']') ) {
					$length = $self->parse_expression;
				}
				$self->_eat('OP', ']');
				$expr = Zuzu::AST::Expr::Slice->new(
					file => $lb->file,
					line => $lb->line,
					collection => $expr,
					start => $first,
					length => $length,
				);
				next;
			}
			my $idx = $first;
			$self->_eat('OP', ']');
			$expr = Zuzu::AST::Expr::Index->new(file => $lb->file, line => $lb->line, array => $expr, index => $idx);
			next;
		}

		# postfix increment/decrement
		if ($t->is_OP && ($t->value eq '++' || $t->value eq '--')) {
			my $op = $self->_eat('OP');
			$self->_assert_mutable_target($expr, $op);
			$expr = Zuzu::AST::Expr::IncDec->new(
				file => $op->file,
				line => $op->line,
				op => $op->value,
				target => $expr,
				postfix => 1,
			);
			next;
		}

		# dict access: d{expr} or d{ident}
		if ($t->is_OP && $t->value eq '{') {
			my $lb = $self->_eat('OP', '{');
			my $key = $self->_parse_dict_key_expr;
			$self->_eat('OP', '}');
			$expr = Zuzu::AST::Expr::DictGet->new(file => $lb->file, line => $lb->line, dict => $expr, key => $key);
			next;
		}

		last;
	}

	return $expr;
}

sub _parse_invocation_args {
	my ( $self ) = @_;

	my @args;
	$self->{_invocation_arg_depth}++;
	while ( ! $self->{tok}->is_OP(')') ) {
		# ignore superfluous commas between arguments
		if ( $self->_maybe('OP', ',') ) { next; }

		if ( $self->{tok}->is_OP('...') ) {
			my $spread_tok = $self->_eat('OP', '...');
			my $expr = $self->parse_expression;
			if ( $self->{tok}->is_OP('...') ) {
				$self->_err("Range syntax '...' is only valid in collection literals", $self->{tok});
			}
			push @args, [
				undef,
				Zuzu::AST::Expr::Spread->new(
					file => $spread_tok->file,
					line => $spread_tok->line,
					expr => $expr,
				),
			];
			$self->_maybe('OP', ',');
			next;
		}

		my $expr = $self->parse_expression;
		if ( $self->_maybe('OP', ':') ) {
			if ( $self->{tok}->is_OP('...') ) {
				$self->_err("Spread arguments cannot be named", $self->{tok});
			}
			my $value_expr = $self->parse_expression;
			if ( $expr and blessed($expr) and $expr->isa('Zuzu::AST::Expr::Var') ) {
				push @args, [ $expr->name, $value_expr ];
			}
			else {
				push @args, [ $expr, $value_expr, 1 ];
			}
		}
		else {
			if ( $self->{tok}->is_OP('...') ) {
				$self->_err("Range syntax '...' is only valid in collection literals", $self->{tok});
			}
			push @args, [ undef, $expr ];
		}
		$self->_maybe('OP', ',');
	}
	$self->{_invocation_arg_depth}--;

	return @args;
}

sub _assert_mutable_target {
	my ( $self, $expr, $tok ) = @_;

	return if ! blessed($expr) or ! $expr->isa('Zuzu::AST::Expr::Var');

	my $info = $self->_lookup($expr->name);
	return if ! $info;
	return if ! exists $info->{mutable};
	return if $info->{mutable};

	$self->_err("Cannot assign to const '".$expr->name."' (compile-time)", $tok);
}

sub _assert_reference_target {
	my ( $self, $expr, $tok ) = @_;

	my $ok
		= blessed($expr)
		&& (
			$expr->isa('Zuzu::AST::Expr::Var')
			or $expr->isa('Zuzu::AST::Expr::Index')
			or $expr->isa('Zuzu::AST::Expr::DictGet')
			or $expr->isa('Zuzu::AST::Expr::Slice')
			or (
				$expr->isa('Zuzu::AST::Expr::Binary')
				and defined $expr->op
				and (
					$expr->op eq '@'
					or $expr->op eq '@@'
					or $expr->op eq '@?'
				)
			)
		);
	return if $ok;

	$self->_err("Reference operator expects an assignable target", $tok);
}

sub _parse_dict_key_expr {
	my ( $self ) = @_;

	if ( $self->{tok}->is_IDENT ) {
		my $id = $self->_eat('IDENT');

		return Zuzu::AST::Expr::Literal->new(
			file => $id->file,
			line => $id->line,
			value => $id->value,
		);
	}
	if ( $self->{tok}->is_KW ) {
		my $kw = $self->_eat('KW');

		return Zuzu::AST::Expr::Literal->new(
			file => $kw->file,
			line => $kw->line,
			value => $kw->value,
		);
	}

	return $self->parse_expression;
}

sub parse_array_literal {
	my ($self) = @_;

	my $lb = $self->_eat('OP', '[');
	my @items;
	while (!($self->{tok}->is_OP && $self->{tok}->value eq ']')) {
		# ignore duplicate/trailing commas
		if ($self->_maybe('OP', ',')) { next; }
		my $start = $self->parse_expression;
		if ( $self->_maybe('OP', '...') ) {
			my $end = $self->parse_expression;
			push @items, Zuzu::AST::Expr::Range->new(
				file => $lb->file,
				line => $lb->line,
				start => $start,
				end => $end,
			);
		}
		else {
			push @items, $start;
		}
		$self->_maybe('OP', ',');
	}
	$self->_eat('OP', ']');

	return Zuzu::AST::Expr::Array->new(file => $lb->file, line => $lb->line, items => \@items);
}

sub parse_dict_literal {
	my ($self) = @_;

	my $lb = $self->_eat('OP', '{');
	my @pairs;
	while (!($self->{tok}->is_OP && $self->{tok}->value eq '}')) {
		if ($self->_maybe('OP', ',')) { next; }
		my $key;
		$key = $self->_parse_dict_key_expr;
		$self->_eat('OP', ':');
		my $val = $self->parse_expression;
		push @pairs, [ $key, $val ];
		$self->_maybe('OP', ',');
	}
	$self->_eat('OP', '}');

	return Zuzu::AST::Expr::Dict->new(file => $lb->file, line => $lb->line, pairs => \@pairs);
}

sub parse_pairlist_literal {
	my ( $self ) = @_;

	my $lb = $self->_eat( 'OP', '{{' );
	my @pairs;
	while ( ! $self->{tok}->is_OP('}}') ) {
		if ( $self->_maybe('OP', ',') ) {
			next;
		}
		my $key = $self->_parse_dict_key_expr;
		$self->_eat( 'OP', ':' );
		my $value = $self->parse_expression;
		push @pairs, [ $key, $value ];
		$self->_maybe( 'OP', ',' );
	}
	$self->_eat( 'OP', '}}' );

	return Zuzu::AST::Expr::PairList->new(
		file => $lb->file,
		line => $lb->line,
		pairs => \@pairs,
	);
}

sub parse_set_literal {
	my ( $self ) = @_;

	my $open = $self->{tok}->value;
	my $close = $open eq '<<' ? '>>' : '»';
	my $lb = $self->_eat('OP', $open);
	my @items;
	while ( ! $self->{tok}->is_OP($close) ) {
		if ( $self->_maybe('OP', ',') ) {
			next;
		}
		my $start = $self->parse_expression;
		if ( $self->_maybe('OP', '...') ) {
			my $end = $self->parse_expression;
			push @items, Zuzu::AST::Expr::Range->new(
				file => $lb->file,
				line => $lb->line,
				start => $start,
				end => $end,
			);
		}
		else {
			push @items, $start;
		}
		$self->_maybe('OP', ',');
	}
	$self->_eat('OP', $close);

	return Zuzu::AST::Expr::Set->new(
		file => $lb->file,
		line => $lb->line,
		items => \@items,
	);
}

sub parse_bag_literal {
	my ( $self ) = @_;

	my $open = $self->{tok}->value;
	my $close = '>>>';
	my $lb = $self->_eat('OP', $open);
	my @items;
	while ( ! $self->{tok}->is_OP($close) ) {
		if ( $self->_maybe('OP', ',') ) {
			next;
		}
		my $start = $self->parse_expression;
		if ( $self->_maybe('OP', '...') ) {
			my $end = $self->parse_expression;
			push @items, Zuzu::AST::Expr::Range->new(
				file => $lb->file,
				line => $lb->line,
				start => $start,
				end => $end,
			);
		}
		else {
			push @items, $start;
		}
		$self->_maybe('OP', ',');
	}
	$self->_eat('OP', $close);

	return Zuzu::AST::Expr::Bag->new(
		file => $lb->file,
		line => $lb->line,
		items => \@items,
	);
}

=pod

=head1 NAME

Zuzu::Parser::_Impl - recursive-descent parser implementation

=head1 DESCRIPTION

Implements token-driven parsing routines that build typed AST node objects and enforce basic syntax rules.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 lexer

Type: B<InstanceOf["Zuzu::Lexer"]>.

Lexer instance that provides the token stream.

=head2 filename

Type: B<Maybe[Str]>.

Filename attached to generated tokens and parser errors.

=head2 tok

Type: B<InstanceOf["Zuzu::Token"]>.

Current lookahead token.

=head2 scopes

Type: B<ArrayRef[HashRef]>.

Stack of parser-declared symbol tables for lexical scopes.

=head1 METHODS

=head2 new

Constructs and returns a new instance of this class.

=head2 parse_program

Parses a program construct and returns its AST node.

=head2 parse_statement

Parses a statement construct and returns its AST node.

=head2 parse_block

Parses a block construct and returns its AST node.

=head2 parse_let

Parses a let construct and returns its AST node.

=head2 parse_function_def

Parses a function def construct and returns its AST node.

=head2 parse_class_def

Parses a class def construct and returns its AST node.

=head2 parse_trait_def

Parses a trait def construct and returns its AST node.

=head2 parse_type_ref

Parses a type ref construct and returns its AST node.

=head2 parse_method_def

Parses a method def construct and returns its AST node.

=head2 parse_if

Parses a if construct and returns its AST node.

=head2 parse_while

Parses a while construct and returns its AST node.

=head2 parse_for

Parses a for construct and returns its AST node.

=head2 parse_return

Parses a return construct and returns its AST node.

=head2 parse_import

Parses a import construct and returns its AST node.

=head2 parse_expression

Parses a expression construct and returns its AST node.

=head2 parse_prefix

Parses a prefix construct and returns its AST node.

=head2 parse_primary

Parses a primary construct and returns its AST node.

=head2 parse_postfix

Parses a postfix construct and returns its AST node.

=head2 parse_array_literal

Parses a array literal construct and returns its AST node.

=head2 parse_dict_literal

Parses a dict literal construct and returns its AST node.

=head2 parse_set_literal

Parses a set literal construct and returns its AST node.

=head2 parse_bag_literal

Parses a bag literal construct and returns its AST node.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Parser::_Impl >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
