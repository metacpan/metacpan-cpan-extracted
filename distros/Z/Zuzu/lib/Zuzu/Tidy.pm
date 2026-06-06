package Zuzu::Tidy;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001005';

use Zuzu::Lexer;
use Zuzu::Parser;
use Zuzu::Token;

my %BINARY_OP = map { $_ => 1 } qw(
	+ - * / × ÷ ** mod
	_ ~
	= == != < > <= >= <=> eq ne gt ge lt le cmp eqi nei gti gei lti lei cmpi
	and or xor nand
	× ÷ ≠ ≤ ≥ ≡ ≢ ≶ ≷ ⋀ ⋁ ⊻ ⊼
	in ∈ ∉ union ⋃ intersection ⋂ subsetof ⊂ supersetof ⊃ equivalentof ⊂⊃ ∖
	instanceof does can
	default
	& | ^
	@ @? @@
	▷ ◁ |> <|
	:= ~= += -= *= /= ×= ÷= **= _= ?:=
	=
);
$BINARY_OP{'\\'} = 1;

my %UNARY_PREFIX_OP = map { $_ => 1 } qw(
	+ - ! not ¬ ~ √ \ ++ --
	abs sqrt floor ceil round int uc lc length typeof new
);
my %NO_SPACE_BEFORE = map { $_ => 1 } ( ',', ';', ')', ']', '}', '⌋', '⌉', '.', ':' );
my %NO_SPACE_AFTER  = map { $_ => 1 } ( '(', '[', '{', '⌊', '⌈', '.' );
my %CONTROL_KW = map { $_ => 1 } qw( if else while for switch catch unless );
my %CANONICAL_OPERATOR_SPELLING = (
	'*'            => '×',
	'/'            => '÷',
	'<='           => '≤',
	'>='           => '≥',
	'<=>'          => '≶',
	'≷'            => '≶',
	'=='           => '≡',
	'!='           => '≢',
	'not'          => '¬',
	'sqrt'         => '√',
	'and'          => '⋀',
	'nand'         => '⊼',
	'xor'          => '⊻',
	'or'           => '⋁',
	'union'        => '⋃',
	'intersection' => '⋂',
	'\\'           => '∖',
	'in'           => '∈',
	'subsetof'     => '⊂',
	'supersetof'   => '⊃',
	'equivalentof' => '⊂⊃',
	'|>'           => '▷',
	'<|'           => '◁',
	'*='           => '×=',
	'/='           => '÷=',
);

sub tidy {
	my ( $class, $src, %opts ) = @_;
	$src //= '';
	my $comment_map = {};
	$src = _stash_multiline_comments( $src, $comment_map );

	my @segments = _split_pod_segments($src);
	my @out;
	for my $segment ( @segments ) {
		if ( $segment->{is_pod} ) {
			push @out, { is_pod => 1, text => $segment->{text} };
			next;
		}

		my $chunk = $segment->{text};
		next if $chunk eq '';

		my $tidied = _tidy_code_chunk( $chunk, %opts );
		$tidied = _restore_multiline_comments( $tidied, $comment_map );
		$tidied = _apply_vertical_spacing_rules($tidied);
		$tidied = _normalize_split_brace_literals($tidied);
		$tidied = _normalize_split_sequence_literals($tidied);
		$tidied = _strip_single_line_trailing_literal_commas($tidied);
		my $parser = Zuzu::Parser->new;
		eval {
			$parser->parse(
				_strip_multiline_comments_for_parse($tidied),
				$opts{filename} // '<tidy>'
			);
			1;
		};
		push @out, { is_pod => 0, text => $tidied };
	}

	return _join_segments_with_pod_spacing(@out);
}

sub _join_segments_with_pod_spacing {
	my ( @segments ) = @_;
	my $out = '';

	for ( my $i = 0; $i <= $#segments; $i++ ) {
		my $segment = $segments[$i];
		my $text = $segment->{text} // '';
		next if $text eq '';

		if ( $i > 0 ) {
			my $prev = $segments[$i - 1];
				my $crosses_pod_boundary
					= ( ( $prev->{is_pod} and ! $segment->{is_pod} )
					or ( ! $prev->{is_pod} and $segment->{is_pod} ) );
			if ( $crosses_pod_boundary ) {
				$out =~ s/\n*\z/\n\n/s;
				$text =~ s/\A\n+//s;
			}
		}

		$out .= $text;
	}

	return $out;
}

sub _tidy_code_chunk {
	my ( $src, %opts ) = @_;

	my $lexer = Zuzu::Lexer->new( src => $src, filename => $opts{filename} // '<tidy>' );
	my @tokens;
	while (1) {
		my $tok = $lexer->next_token;
		last if $tok->is_EOF;
		push @tokens, $tok;
	}
	@tokens = _normalize_tokens(@tokens);

	my %pair_for = _build_pair_map( \@tokens );

	my $indent = 0;
	my $paren_depth = 0;
	my $bracket_depth = 0;
	my $brace_depth = 0;
	my $inline_brace_depth = 0;
	my @brace_kind_stack;
	my $line = '';
	my @out_lines;
	my $pending_indent = 1;
	my $continuation_indent = 0;

	for ( my $i = 0; $i <= $#tokens; $i++ ) {
		my $tok = $tokens[$i];
		my $val = _token_text($tok);
		my $emit_val = _display_token_text( \@tokens, $i, %opts );
		my $prev = $i > 0 ? $tokens[$i - 1] : undef;
		my $next = $i < $#tokens ? $tokens[$i + 1] : undef;
		my $just_closed_inline = 0;

		my $close_kind = ( $val eq '}' and @brace_kind_stack ) ? $brace_kind_stack[-1] : 'block';

		if ( $val eq '}' and ( $close_kind eq 'block' or $close_kind eq 'expr_block' ) ) {
			if ( $line =~ /\S/ ) {
				push @out_lines, _rstrip($line);
				$line = '';
			}
			$indent-- if $indent > 0;
			$pending_indent = 1;
		}

		if ( $pending_indent ) {
			$line .= ("\t" x $indent);
			$line .= (' ' x $continuation_indent) if $continuation_indent > 0;
			$pending_indent = 0;
		}

		if ( _is_chain_op($val) and $line =~ /\S/ ) {
			push @out_lines, _rstrip($line);
			$line = ("\t" x ( $indent + 1 ));
		}

			my $need_before = _need_space_before( \@tokens, $i, \%pair_for );
			$line .= ' ' if $need_before and $line =~ /\S/ and $line !~ /[ \t]\z/;
		$line .= $emit_val;

		if ( $val eq '{' ) {
			my $is_inline = _is_inline_brace( \@tokens, $i, \%pair_for );
			my $kind = $is_inline ? 'inline'
				: _is_expression_block_brace( \@tokens, $i ) ? 'expr_block'
				: 'block';
			push @brace_kind_stack, $kind;
			$brace_depth++;
			$inline_brace_depth++ if $is_inline;
			if ( ! $is_inline ) {
				push @out_lines, _rstrip($line);
				$line = '';
				$indent++;
				$pending_indent = 1;
				$continuation_indent = 0;
				next;
			}
		}
		if ( $val eq ';' ) {
			push @out_lines, _rstrip($line);
			$line = '';
			$pending_indent = 1;
			$continuation_indent = 0;
			next;
		}
		if ( $val eq '}' ) {
			my $kind = @brace_kind_stack ? pop @brace_kind_stack : 'block';
			$just_closed_inline = 1 if $kind eq 'inline';
			$brace_depth-- if $brace_depth > 0;
			$inline_brace_depth-- if $kind eq 'inline' and $inline_brace_depth > 0;
			if ( $kind eq 'block' or $kind eq 'expr_block' ) {
				if ( $kind eq 'expr_block' ) {
					if ( $next and $next->is_OP(';') ) {
						$line .= ';';
						$i++;
					}
					elsif (
						!$next
						or ( $next->is_OP and $next->value eq '}' )
						or _can_start_statement($next)
					) {
						$line .= ';';
					}
				}
				if ( $next and $next->is_KW('else') ) {
					push @out_lines, _rstrip($line);
					$line = '';
					$pending_indent = 1;
					next;
				}
				push @out_lines, _rstrip($line);
				$line = '';
				$pending_indent = 1;
				next;
			}
		}

		# wrap long lines conservatively at commas and binary operators.
		my $col = _visual_length($line);
		my $wrap_limit = $continuation_indent > 0 ? 80 : 100;
		if ( $col > $wrap_limit and ( $val eq ',' or _is_binary_op( \@tokens, $i ) ) ) {
			push @out_lines, _rstrip($line);
			$line = '';
			$pending_indent = 1;
			$continuation_indent = 4;
		}

		if ( $val eq '(' ) {
			$paren_depth++;
		}
		elsif ( $val eq ')' ) {
			$paren_depth-- if $paren_depth > 0;
		}
		elsif ( $val eq '[' ) {
			$bracket_depth++;
		}
		elsif ( $val eq ']' ) {
			$bracket_depth-- if $bracket_depth > 0;
		}

		if ( $next and _needs_auto_semicolon( $tok, $next, $paren_depth, $bracket_depth, $brace_depth, $inline_brace_depth, $just_closed_inline ) ) {
			$line .= ';';
			push @out_lines, _rstrip($line);
			$line = '';
			$pending_indent = 1;
			$continuation_indent = 0;
		}
	}

	if ( $line =~ /\S/ ) {
		if ( $line !~ /;\z/ and @tokens and _can_end_statement( $tokens[-1] ) ) {
			$line .= ';';
		}
		push @out_lines, _rstrip($line);
	}

	return join( "\n", @out_lines ) . "\n";
}

sub _split_pod_segments {
	my ( $src ) = @_;
	my @lines = split /(?<=\n)/, $src;
	my @segments;
	my $buf = '';
	my $in_pod = 0;

	for my $line ( @lines ) {
		if ( ! $in_pod and $line =~ /^=(\w+)/ ) {
			my $word = $1;
			if ( $word ne 'cut' ) {
				if ( $buf ne '' ) {
					push @segments, { is_pod => 0, text => $buf };
					$buf = '';
				}
				$in_pod = 1;
			}
		}

		$buf .= $line;

		if ( $in_pod and $line =~ /^=cut(?:\r?\n)?\z/ ) {
			push @segments, { is_pod => 1, text => $buf };
			$buf = '';
			$in_pod = 0;
		}
	}

	if ( $buf ne '' ) {
		push @segments, { is_pod => ( $in_pod ? 1 : 0 ), text => $buf };
	}

	return @segments;
}

sub _is_chain_op {
	my ( $val ) = @_;

	return $val eq '▷' || $val eq '◁' || $val eq '|>' || $val eq '<|';
}

sub _normalize_tokens {
	my ( @tokens ) = @_;
	my @out;

	for my $tok ( @tokens ) {
		if ( $tok->is_OP('{{') ) {
			push @out, Zuzu::Token->new(
				type => 'OP',
				value => '{',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			push @out, Zuzu::Token->new(
				type => 'OP',
				value => '{',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			next;
		}
		if ( $tok->is_OP('}}') ) {
			push @out, Zuzu::Token->new(
				type => 'OP',
				value => '}',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			push @out, Zuzu::Token->new(
				type => 'OP',
				value => '}',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			next;
		}
		push @out, $tok;
	}

	return @out;
}

sub _build_pair_map {
	my ( $tokens ) = @_;
	my @stack;
	my %pair;

	for my $i ( 0 .. $#$tokens ) {
		my $v = defined $tokens->[$i]->value ? $tokens->[$i]->value : '';
		if ( $v eq '(' or $v eq '[' or $v eq '{' or $v eq '⌊' or $v eq '⌈' ) {
			push @stack, [ $v, $i ];
			next;
		}
		if ( $v eq ')' or $v eq ']' or $v eq '}' or $v eq '⌋' or $v eq '⌉' ) {
			next if ! @stack;
			my $entry = pop @stack;
			my ( $open, $open_i ) = @$entry;
			next if ( $open eq '(' and $v ne ')' )
				or ( $open eq '[' and $v ne ']' )
				or ( $open eq '{' and $v ne '}' )
				or ( $open eq '⌊' and $v ne '⌋' )
				or ( $open eq '⌈' and $v ne '⌉' );
			$pair{$open_i} = $i;
			$pair{$i} = $open_i;
		}
	}

	return %pair;
}

sub _need_space_before {
	my ( $tokens, $i, $pair_for ) = @_;
	my $tok = $tokens->[$i];
	my $v = defined $tok->value ? $tok->value : '';
	return 0 if $i == 0;

	my $prev = $tokens->[ $i - 1 ];
	my $pv = defined $prev->value ? $prev->value : '';

	if ( _is_module_path_slash( $tokens, $i ) ) {
		return 0;
	}
	if ( _is_module_path_slash( $tokens, $i - 1 ) ) {
		return 0;
	}

	if ( $v eq '...' and _is_call_spread_operator( $tokens, $i ) ) {
		return 0;
	}
	if ( $pv eq '...' and _is_call_spread_operator( $tokens, $i - 1 ) ) {
		return 0;
	}

	if ( $v eq '{' and $pv eq '{' ) {
		return 0;
	}
	if ( $v eq '}' and $pv eq '}' ) {
		return 1;
	}

	if ( $v eq '?' and $prev->is_IDENT ) {
		my $next = $i < $#$tokens ? $tokens->[ $i + 1 ] : undef;
		if ( $next and $next->is_OP and ( $next->value eq ',' or $next->value eq ')' ) ) {
			return 0;
		}
	}

	return 0 if _is_unary_punct_operator( $tokens, $i - 1 );
	if (
		( $v eq '++' or $v eq '--' )
		and (
			$prev->is_IDENT
			or ( $prev->is_OP and ( $pv eq ')' or $pv eq ']' or $pv eq '}' ) )
		)
	) {
		return 0;
	}

	if (
		$v eq '{'
		and _is_inline_brace( $tokens, $i, $pair_for )
		and (
			$prev->is_IDENT
			or ( $prev->is_OP and ( $pv eq ')' or $pv eq ']' or $pv eq '}' ) )
		)
	) {
		return 0;
	}

	if ( $pv eq '{' ) {
		my $open_i = $i - 1;
		if (
			defined $pair_for->{$open_i}
			and _is_inline_brace( $tokens, $open_i, $pair_for )
			and ! _brace_needs_inner_space( $tokens, $open_i, $pair_for->{$open_i} )
		) {
			return 0;
		}
		return 1;
	}

	if ( $v eq '}' ) {
		my $open_i = $pair_for->{$i};
		if (
			defined $open_i
			and _is_inline_brace( $tokens, $open_i, $pair_for )
			and ! _brace_needs_inner_space( $tokens, $open_i, $i )
		) {
			return 0;
		}
		return 1;
	}

	return 0 if $NO_SPACE_BEFORE{$v} and $v ne ')' and $v ne ']';
	return 0 if $NO_SPACE_AFTER{$pv} and $pv ne '(' and $pv ne '[';

	if ( $v eq '(' or $v eq '[' ) {
		if ( $pv eq ',' ) {
			return 1;
		}
		if ( _is_binary_op( $tokens, $i - 1 ) ) {
			return 1;
		}
		if ( $prev->is_KW and $CONTROL_KW{ $prev->value } ) {
			return 1;
		}
		if ( $v eq '[' and $prev->is_OP and $pv ne '.' and $pv ne ')' and $pv ne ']' ) {
			return 1;
		}
		if ( $v eq '(' and $prev->is_IDENT and $i >= 2 ) {
			my $before_prev = $tokens->[ $i - 2 ];
			if ( $before_prev->is_KW('function') or $before_prev->is_KW('method') ) {
				return 1;
			}
		}
		if ( defined $pair_for->{$i} and ! _paren_needs_inner_space( $tokens, $i, $pair_for->{$i} ) ) {
			return 0;
		}
		if ( $pv eq ')' or $pv eq ']' ) {
			return 0;
		}
		if ( $pv eq '}' or $pv eq '.' ) {
			return 0;
		}
		return 0;
	}

	if ( $pv eq '(' or $pv eq '[' ) {
		my $open_i = $i - 1;
		if ( defined $pair_for->{$open_i} and ! _paren_needs_inner_space( $tokens, $open_i, $pair_for->{$open_i} ) ) {
			return 0;
		}
		return 1;
	}

	if ( $v eq ')' or $v eq ']' ) {
		my $open_i = $pair_for->{$i};
		if ( defined $open_i and ! _paren_needs_inner_space( $tokens, $open_i, $i ) ) {
			return 0;
		}
		return 1;
	}

	if ( $pv eq '⌊' or $pv eq '⌈' ) {
		my $open_i = $i - 1;
		if ( defined $pair_for->{$open_i} and ! _paren_needs_inner_space( $tokens, $open_i, $pair_for->{$open_i} ) ) {
			return 0;
		}
		return 1;
	}

	if ( $v eq '⌋' or $v eq '⌉' ) {
		my $open_i = $pair_for->{$i};
		if ( defined $open_i and ! _paren_needs_inner_space( $tokens, $open_i, $i ) ) {
			return 0;
		}
		return 1;
	}

	if ( _is_binary_op( $tokens, $i ) ) {
		return 1;
	}
	if ( _is_binary_op( $tokens, $i - 1 ) ) {
		return 1;
	}

	return 1;
}

sub _is_module_path_slash {
	my ( $tokens, $i ) = @_;
	return 0 if $i < 0 or $i > $#$tokens;
	my $tok = $tokens->[$i];
	return 0 if ! $tok->is_OP or $tok->value ne '/';

	my $stmt_start = 0;
	for ( my $k = $i - 1; $k >= 0; $k-- ) {
		my $v = defined $tokens->[$k]->value ? $tokens->[$k]->value : '';
		if ( $v eq ';' or $v eq '{' or $v eq '}' ) {
			$stmt_start = $k + 1;
			last;
		}
	}

	my $from_i = -1;
	for ( my $k = $i - 1; $k >= $stmt_start; $k-- ) {
		if ( $tokens->[$k]->is_KW('from') ) {
			$from_i = $k;
			last;
		}
	}
	return 0 if $from_i < 0;

	my $stmt_end = $#$tokens;
	for ( my $k = $i + 1; $k <= $#$tokens; $k++ ) {
		my $v = defined $tokens->[$k]->value ? $tokens->[$k]->value : '';
		if ( $v eq ';' or $v eq '{' or $v eq '}' ) {
			$stmt_end = $k - 1;
			last;
		}
	}

	my $import_i = -1;
	for ( my $k = $from_i + 1; $k <= $stmt_end; $k++ ) {
		if ( $tokens->[$k]->is_KW('import') ) {
			$import_i = $k;
			last;
		}
	}
	return 0 if $import_i < 0;
	return 0 if $i <= $from_i or $i >= $import_i;

	for my $k ( $from_i + 1 .. $import_i - 1 ) {
		my $t = $tokens->[$k];
		next if $t->is_IDENT;
		next if $t->is_KW('try');
		next if $t->is_OP and $t->value eq '/';
		return 0;
	}

	return 1;
}

sub _display_token_text {
	my ( $tokens, $i, %opts ) = @_;
	my $tok = $tokens->[$i];
	my $raw = _token_text($tok);

	return $raw if !$opts{canonical_operators};
	return $raw if !exists $CANONICAL_OPERATOR_SPELLING{$raw};
	return $raw if !_can_canonicalize_operator( $tokens, $i );

	return $CANONICAL_OPERATOR_SPELLING{$raw};
}

sub _can_canonicalize_operator {
	my ( $tokens, $i ) = @_;
	my $tok = $tokens->[$i];
	my $raw = _token_text($tok);

	return 0 if !$tok->is_OP and !$tok->is_KW;
	return 0 if _is_module_path_slash( $tokens, $i );
	return 0 if _is_import_wildcard( $tokens, $i );
	return 0 if $raw eq 'in' and _is_for_loop_in_keyword( $tokens, $i );
	return 1 if $raw eq '*=' or $raw eq '/=';
	return 1 if _is_chain_op($raw);
	return 1 if _is_unary_operator( $tokens, $i );
	return 1 if _is_binary_op( $tokens, $i );

	return 0;
}

sub _is_import_wildcard {
	my ( $tokens, $i ) = @_;
	return 0 if $i < 0 or $i > $#$tokens;
	return 0 if !$tokens->[$i]->is_OP('*');

	for ( my $k = $i - 1; $k >= 0; $k-- ) {
		my $v = defined $tokens->[$k]->value ? $tokens->[$k]->value : '';
		return 0 if $v eq ';' or $v eq '{' or $v eq '}';
		return 1 if $tokens->[$k]->is_KW('import');
	}

	return 0;
}

sub _is_for_loop_in_keyword {
	my ( $tokens, $i ) = @_;
	return 0 if $i < 0 or $i > $#$tokens;
	return 0 if !$tokens->[$i]->is_KW('in');

	my @stack;
	for my $k ( 0 .. $i - 1 ) {
		my $v = defined $tokens->[$k]->value ? $tokens->[$k]->value : '';
		if ( $v eq '(' ) {
			push @stack, $k;
			next;
		}
		if ( $v eq ')' ) {
			pop @stack if @stack;
		}
	}
	return 0 if !@stack;

	my $open_i = $stack[-1];
	return 0 if $open_i == 0;
	return 1 if $tokens->[ $open_i - 1 ]->is_KW('for');

	return 0;
}

sub _is_binary_op {
	my ( $tokens, $i ) = @_;
	return 0 if $i < 0 or $i > $#$tokens;
	my $tok = $tokens->[$i];
	return 0 if ! $tok->is_OP and ! $tok->is_KW;
	my $v = $tok->value;
	return 0 if ! $BINARY_OP{$v};
	return 0 if _is_unary_operator( $tokens, $i );

	return 1;
}

sub _is_call_spread_operator {
	my ( $tokens, $i ) = @_;
	return 0 if $i < 0 or $i > $#$tokens;
	my $tok = $tokens->[$i];
	return 0 if ! $tok->is_OP or $tok->value ne '...';

	my $prev = $i > 0 ? $tokens->[ $i - 1 ] : undef;
	return 0 if !$prev;
	return 1 if $prev->is_OP and ( $prev->value eq '(' or $prev->value eq ',' );

	return 0;
}

sub _is_unary_operator {
	my ( $tokens, $i ) = @_;
	my $tok = $tokens->[$i];
	return 0 if ! $tok->is_OP and ! $tok->is_KW;
	my $v = $tok->value;
	return 0 if ! $UNARY_PREFIX_OP{$v};

	return 1 if $i == 0;
	my $prev = $tokens->[ $i - 1 ];
	if ( $prev->is_OP ) {
		my $pv = defined $prev->value ? $prev->value : '';
		return 1 if $pv ne ')'
			and $pv ne ']'
			and $pv ne '}'
			and $pv ne '⌋'
			and $pv ne '⌉'
			and $pv ne '»'
			and $pv ne '>>'
			and $pv ne '>>>';
	}
	return 1 if $prev->is_KW and $prev->value ne 'true' and $prev->value ne 'false' and $prev->value ne 'null';

	return 0;
}

sub _is_unary_punct_operator {
	my ( $tokens, $i ) = @_;
	return 0 if $i < 0 or $i > $#$tokens;
	my $tok = $tokens->[$i];
	return 0 if ! $tok->is_OP;
	return 0 if ! _is_unary_operator( $tokens, $i );
	return $tok->value =~ /[[:alpha:]]/ ? 0 : 1;
}

sub _paren_needs_inner_space {
	my ( $tokens, $open_i, $close_i ) = @_;
	return 0 if $close_i == $open_i + 1;

	my @inner = @{$tokens}[ $open_i + 1 .. $close_i - 1 ];
	if ( @inner == 1 ) {
		return _is_simple_token( $inner[0] ) ? 0 : 1;
	}
	if (
		@inner == 2
		and $inner[0]->is_OP
		and $inner[0]->value eq '...'
		and _is_simple_token( $inner[1] )
	) {
		return 0;
	}

	return 1;
}

sub _brace_needs_inner_space {
	my ( $tokens, $open_i, $close_i ) = @_;
	return 0 if $close_i == $open_i + 1;
	my $before = $open_i > 0 ? $tokens->[ $open_i - 1 ] : undef;
	my $before_val = ( $before and defined $before->value ) ? $before->value : '';
	my $is_accessor = 0;
	if ($before) {
		$is_accessor = 1 if $before->is_IDENT;
		$is_accessor = 1 if $before->is_OP and ( $before_val eq ')' or $before_val eq ']' or $before_val eq '}' );
	}

	my @inner = @{$tokens}[ $open_i + 1 .. $close_i - 1 ];
	if ( $is_accessor ) {
		return _is_simple_token( $inner[0] ) ? 0 : 1 if @inner == 1;
		return 1;
	}

	return 1;
}

sub _is_simple_token {
	my ( $tok ) = @_;
	return 1 if $tok->is_IDENT;
	return 1 if $tok->is_NUMBER;
	return 1 if $tok->is_BOOL;
	return 1 if $tok->is_NULL;
	if ( $tok->is_STRING or $tok->is_type('BINARY_STRING') or $tok->is_type('TEMPLATE') ) {
		my $value = defined $tok->value ? $tok->value : '';
		return length($value) <= 12 ? 1 : 0;
	}

	return 0;
}

sub _needs_auto_semicolon {
	my ( $tok, $next, $paren_depth, $bracket_depth, $brace_depth, $inline_brace_depth, $just_closed_inline ) = @_;
	return 0 if $tok->is_OP and ( $tok->value eq ';' or $tok->value eq '{' );
	return 0 if $tok->is_OP and $tok->value eq '}' and ! $just_closed_inline;
	return 0 if $tok->is_OP and $tok->value eq ':';
	return 0 if $tok->is_KW('else');
	if ( $next->is_KW and ( $next->value eq 'if' or $next->value eq 'unless' ) ) {
		return 0;
	}
	return 0 if $next->is_OP and ( $next->value eq ';' or $next->value eq ')' or $next->value eq ']' or $next->value eq '⌋' or $next->value eq '⌉' or $next->value eq ',' or $next->value eq ':' );
	return 0 if $paren_depth > 0 or $bracket_depth > 0;
	return 0 if $inline_brace_depth > 0;
	return 1 if $next->is_OP and $next->value eq '}' and _can_end_statement($tok);
	return 1 if $next->is_KW('else');
	return 1 if $tok->line < $next->line and _can_end_statement($tok) and _can_start_statement($next);

	return 0;
}

sub _is_inline_brace {
	my ( $tokens, $i, $pair_for ) = @_;
	return 0 if $i <= 0;

	my $prev = $tokens->[ $i - 1 ];
	my $pv = defined $prev->value ? $prev->value : '';

	if ( $prev->is_IDENT ) {
		if ( $i >= 2 and $tokens->[ $i - 2 ]->is_KW ) {
			my $kw = $tokens->[ $i - 2 ]->value;
			return 0 if $kw eq 'class' or $kw eq 'trait';
		}
		return 1;
	}

	if ( $prev->is_KW ) {
		my $kw = $prev->value;
		return 0 if $CONTROL_KW{$kw}
			or $kw eq 'class'
			or $kw eq 'trait'
			or $kw eq 'else'
			or $kw eq 'try'
			or $kw eq 'do'
			or $kw eq 'await'
			or $kw eq 'spawn'
			or $kw eq 'function'
			or $kw eq 'method';
		return 1;
	}

	if ( $prev->is_OP and ( $pv eq ':=' or $pv eq '=' or $pv eq ',' or $pv eq '(' or $pv eq '[' or $pv eq ':' ) ) {
		return 1;
	}

	if ( $prev->is_OP and $pv eq ')' ) {
		my $open_i = defined $pair_for->{ $i - 1 } ? $pair_for->{ $i - 1 } : undef;
		if ( defined $open_i and $open_i > 0 ) {
			my $before_open = $tokens->[ $open_i - 1 ];
			if ( $before_open->is_KW ) {
				my $kw = $before_open->value;
				return 0 if $CONTROL_KW{$kw} or $kw eq 'function' or $kw eq 'method' or $kw eq 'while';
			}
			if ( $before_open->is_IDENT and $open_i > 1 and $tokens->[ $open_i - 2 ]->is_KW ) {
				my $kw = $tokens->[ $open_i - 2 ]->value;
				return 0 if $kw eq 'function' or $kw eq 'method';
			}
		}
		return 1;
	}

	if ( $prev->is_OP and ( $pv eq ']' or $pv eq '}' ) ) {
		return 1;
	}

	return 0;
}

sub _is_expression_block_brace {
	my ( $tokens, $i ) = @_;
	return 0 if $i <= 0;

	my $prev = $tokens->[ $i - 1 ];
	return 0 if !$prev->is_KW;

	my $kw = $prev->value;
	return 1 if $kw eq 'await' or $kw eq 'spawn' or $kw eq 'do';

	return 0;
}

sub _can_end_statement {
	my ( $tok ) = @_;
	return 1 if $tok->is_IDENT or $tok->is_NUMBER or $tok->is_STRING or $tok->is_BOOL or $tok->is_NULL;
	return 1 if $tok->is_type('BINARY_STRING');
	return 1 if $tok->is_REGEXP or $tok->is_type('TEMPLATE') or $tok->is_EMPTY_SET;
	return 1 if $tok->is_OP and (
		$tok->value eq ')'
		or $tok->value eq ']'
		or $tok->value eq '}'
		or $tok->value eq '⌋'
		or $tok->value eq '⌉'
		or $tok->value eq '»'
		or $tok->value eq '>>'
		or $tok->value eq '>>>'
		or $tok->value eq '++'
		or $tok->value eq '--'
	);

	return 0;
}

sub _can_start_statement {
	my ( $tok ) = @_;
	return 1 if $tok->is_IDENT or $tok->is_KW;
	return 1 if $tok->is_NUMBER or $tok->is_STRING or $tok->is_BOOL or $tok->is_NULL;
	return 1 if $tok->is_REGEXP or $tok->is_EMPTY_SET;
	return 1 if $tok->is_type('BINARY_STRING') or $tok->is_type('TEMPLATE');
	return 1 if $tok->is_OP and (
		$tok->value eq '('
		or $tok->value eq '['
		or $tok->value eq '{'
		or $tok->value eq '<<'
		or $tok->value eq '<<<'
		or $tok->value eq '«'
		or $tok->value eq '⌊'
		or $tok->value eq '⌈'
	);

	return 0;
}

sub _token_text {
	my ( $tok ) = @_;

	if ( $tok->is_STRING ) {
		my $value = defined $tok->value ? $tok->value : '';
		return '"' . _escape_literal( $value, '"' ) . '"';
	}
	if ( $tok->is_type('BINARY_STRING') ) {
		my $value = defined $tok->value ? $tok->value : '';
		return "'" . _escape_literal( $value, "'" ) . "'";
	}
	if ( $tok->is_BOOL ) {
		return $tok->value ? 'true' : 'false';
	}
	if ( $tok->is_NULL ) {
		return 'null';
	}
	if ( $tok->is_REGEXP ) {
		my $re = $tok->value;
		my $flags = $re->{flags} // '';
		my $pattern = exists $re->{parts}
			? _flatten_interpolated_parts( $re->{parts} )
			: ( $re->{pattern} // '' );
		return '/' . $pattern . '/' . $flags;
	}
	if ( $tok->is_type('TEMPLATE') ) {
		my $value = defined $tok->value ? $tok->value : '';
		return '`' . _flatten_interpolated_parts( $value, 1 ) . '`'
			if ref $value eq 'ARRAY';
		return '`' . _escape_literal( $value, '`' ) . '`';
	}
	if ( $tok->is_EMPTY_SET ) {
		return '∅';
	}

	return defined $tok->value ? $tok->value : '';
}

sub _flatten_interpolated_parts {
	my ( $parts, $escape_text ) = @_;

	return '' if ref $parts ne 'ARRAY';

	my $out = '';
	for my $part ( @$parts ) {
		if ( exists $part->{text} ) {
			my $text = $part->{text} // '';
			$text = _escape_literal( $text, '`' ) if $escape_text;
			$out .= $text;
		}
		elsif ( exists $part->{expr} ) {
			$out .= '${' . ( $part->{expr} // '' ) . '}';
		}
	}

	return $out;
}

sub _escape_literal {
	my ( $value, $quote ) = @_;
	$value =~ s/\\/\\\\/g;
	$value =~ s/\Q$quote\E/\\$quote/g;
	$value =~ s/\n/\\n/g;
	$value =~ s/\r/\\r/g;
	$value =~ s/\t/\\t/g;

	return $value;
}

sub _visual_length {
	my ( $line ) = @_;
	my $len = 0;
	for my $ch ( split //, $line ) {
		$len += ( $ch eq "\t" ) ? 4 : 1;
	}

	return $len;
}

sub _rstrip {
	my ( $value ) = @_;
	$value =~ s/[ \t]+\z//;

	return $value;
}

sub _stash_multiline_comments {
	my ( $src, $comment_map ) = @_;
	my $counter = 0;

	$src =~ s{
		/\* .*? \*/
	}{
		my $placeholder = '__ZUZU_TIDY_COMMENT_' . $counter . '__';
		$comment_map->{$placeholder} = $&;
		$counter++;
		"\n$placeholder\n";
	}egsx;

	return $src;
}

sub _restore_multiline_comments {
	my ( $src, $comment_map ) = @_;
	my @lines = split /\n/, $src, -1;
	my @out;

	for my $line ( @lines ) {
		if (
			$line =~ /^([ \t]*)(__ZUZU_TIDY_COMMENT_\d+__)(?:;)?\z/
			and exists $comment_map->{$2}
		) {
			my $indent = $1;
			my $comment = $comment_map->{$2};
			my @comment_lines = split /\n/, $comment, -1;
			for my $comment_line ( @comment_lines ) {
				push @out, $indent . $comment_line;
			}
			next;
		}

		push @out, $line;
	}

	return join "\n", @out;
}

sub _strip_multiline_comments_for_parse {
	my ( $src ) = @_;
	$src =~ s{/\* .*? \*/}{}gsx;

	return $src;
}

sub _apply_vertical_spacing_rules {
	my ( $src ) = @_;
	my @lines = split /\n/, $src, -1;
	pop @lines if @lines and $lines[-1] eq '';
	return $src if ! @lines;

	my ( @open_for_line, @close_for_line );
	my @stack;

	for my $i ( 0 .. $#lines ) {
		my $trimmed = $lines[$i];
		$trimmed =~ s/^\s+//;
		$trimmed =~ s/\s+\z//;

		if ( $trimmed =~ /\{\z/ ) {
			my $kind = 'block';
			if ( $trimmed =~ /^(function|method)\b/ ) {
				$kind = $1;
			}
			elsif ( $trimmed =~ /^(if|else|while|for|try|catch|switch|unless)\b/ ) {
				$kind = 'statement_block';
			}
			push @stack, {
				kind  => $kind,
				start => $i,
			};
			$open_for_line[$i] = $stack[-1];
		}

		if ( $trimmed =~ /^\}/ ) {
			next if ! @stack;
			my $block = pop @stack;
			$block->{end} = $i;
			$close_for_line[$i] = $block;
		}
	}

	my %blank_before;
	my %blank_after;

	for my $i ( 0 .. $#lines ) {
		my $open_block = $open_for_line[$i];
		if ($open_block) {
			my $kind = $open_block->{kind};
			if ( $kind eq 'function' or $kind eq 'method' ) {
				$blank_before{$i} = 1;
			}
		}

		my $close_block = $close_for_line[$i];
		if ($close_block) {
			my $kind = $close_block->{kind};
			my $len = $close_block->{end} - $close_block->{start} + 1;
			if ( $kind eq 'function' or $kind eq 'method' ) {
				my $next_nonblank = _next_nonblank_line( \@lines, $i + 1 );
				if ( defined $next_nonblank and $lines[$next_nonblank] !~ /^\s*\}/ ) {
					$blank_after{$i} = 1;
				}
			}
			if ( $len >= 5 ) {
				$blank_before{ $close_block->{start} } = 1;
				$blank_after{$i} = 1;
			}
		}

		if ( $lines[$i] =~ /^\s*\/\*/ ) {
			my $is_multiline = $lines[$i] !~ /\*\/\s*\z/ ? 1 : 0;
			$blank_before{$i} = 1 if $is_multiline;
		}
	}

	for my $i ( 0 .. $#lines ) {
		my $trimmed = $lines[$i];
		$trimmed =~ s/^\s+//;
		$trimmed =~ s/\s+\z//;
		next if $trimmed !~ /^return\b/;

		my $next_nonblank = _next_nonblank_line( \@lines, $i + 1 );
		next if ! defined $next_nonblank;
		next if $lines[$next_nonblank] !~ /^\s*\}/;

		my $closing_block = $close_for_line[$next_nonblank];
		next if ! $closing_block;
		next if $closing_block->{kind} ne 'function'
			and $closing_block->{kind} ne 'method';
		my $function_lines = $closing_block->{end} - $closing_block->{start} - 1;
		next if $function_lines <= 2;
		$blank_before{$i} = 1;
	}

	my @out;
	for my $i ( 0 .. $#lines ) {
		if (
			$blank_before{$i}
			and @out
			and $out[-1] =~ /\S/
		) {
			push @out, '';
		}

		push @out, $lines[$i];

		if ( $blank_after{$i} ) {
			my $next_nonblank = _next_nonblank_line( \@lines, $i + 1 );
			if ( defined $next_nonblank ) {
				push @out, '' if $out[-1] =~ /\S/;
			}
		}
	}

	my @collapsed;
	my $previous_blank = 0;
	for my $line ( @out ) {
		if ( $line !~ /\S/ ) {
			next if $previous_blank;
			$previous_blank = 1;
			push @collapsed, '';
			next;
		}
		$previous_blank = 0;
		push @collapsed, $line;
	}

	return join( "\n", @collapsed ) . "\n";
}

sub _next_nonblank_line {
	my ( $lines, $start ) = @_;
	for my $i ( $start .. $#$lines ) {
		return $i if $lines->[$i] =~ /\S/;
	}

	return undef;
}

sub _normalize_split_brace_literals {
	my ( $src ) = @_;
	my @lines = split /\n/, $src, -1;
	my @out;

	for ( my $i = 0; $i <= $#lines; $i++ ) {
		my $line = $lines[$i];
		if ( $line =~ /\{\{\s*\z/ and $i + 2 <= $#lines ) {
			my $j = $i + 1;
			while ( $j <= $#lines and $lines[$j] !~ /^\s*\};\s*\z/ ) {
				$j++;
			}
			my ( $close_indent ) = $lines[$j] =~ /^(\s*)\};\s*\z/ if $j <= $#lines;
			if (
				$j <= $#lines
				and $j > $i + 1
				and defined $close_indent
				and $lines[$j - 1] =~ /^\s*\}\s*\z/
			) {
				my @inner_lines = @lines[ $i + 1 .. $j - 2 ];
				my $inner_joined = join ' ', map { my $t = $_; $t =~ s/^\s+//; $t =~ s/\s+\z//; $t } @inner_lines;
				if ( $inner_joined =~ /,/ ) {
					my ( $inner_indent ) = $lines[ $i + 1 ] =~ /^(\s*)/;
					$inner_indent //= $close_indent . "\t";
					my @parts = grep { $_ ne '' } map { my $p = $_; $p =~ s/^\s+//; $p =~ s/\s+\z//; $p } split /\s*,\s*/, $inner_joined;
					push @out, $line;
					for my $part ( @parts ) {
						push @out, $inner_indent . $part . ',';
					}
					my $suffix = $lines[$j] =~ /;\s*\z/ ? ';' : '';
					push @out, $close_indent . '}}' . $suffix;
					$i = $j;
					next;
				}
			}
		}

		push @out, $line;
	}

	return join "\n", @out;
}

sub _strip_single_line_trailing_literal_commas {
	my ( $src ) = @_;
	my @lines = split /\n/, $src, -1;
	for my $line ( @lines ) {
		next if $line !~ /[\{\[<«]/;
		$line =~ s/,\s*\}\}(?=\s*[;)\],}]|\s*\z)/ }}/g;
		$line =~ s/,\s*\}(?=\s*[;)\],}]|\s*\z)/ }/g;
		$line =~ s/,\s*\](?=\s*[;),\]}]|\s*\z)/ ]/g;
		$line =~ s/,\s*»(?=\s*[;),\]}]|\s*\z)/ »/g;
		$line =~ s/,\s*>>>(?=\s*[;),\]}]|\s*\z)/ >>>/g;
		$line =~ s/,\s*>>(?=\s*[;),\]}]|\s*\z)/ >>/g;
	}

	return join "\n", @lines;
}

sub _normalize_split_sequence_literals {
	my ( $src ) = @_;
	my @lines = split /\n/, $src, -1;
	my @out;

	my %close_for = (
		'['   => ']',
		'<<'  => '>>',
		'<<<' => '>>>',
		'«'   => '»',
	);

	for ( my $i = 0; $i <= $#lines; $i++ ) {
		my $line = $lines[$i];
		my ( $prefix, $open, $after_open ) = $line =~ /^(.*?(?::=|[\(\[,])\s*)(<<<|<<|«|\[)(.*)\z/;
		if ( ! defined $open ) {
			push @out, $line;
			next;
		}

		my $close = $close_for{$open};
		if ( $after_open =~ /\Q$close\E/ ) {
			push @out, $line;
			next;
		}

		my $j = $i + 1;
		while ( $j <= $#lines and $lines[$j] !~ /\Q$close\E/ ) {
			$j++;
		}
		if ( $j > $#lines ) {
			push @out, $line;
			next;
		}

		my ( $before_close, $after_close ) = $lines[$j] =~ /^(.*)\Q$close\E(.*)\z/;
		my @inner_chunks = ( $after_open );
		push @inner_chunks, @lines[ $i + 1 .. $j - 1 ] if $j > $i + 1;
		push @inner_chunks, $before_close;

		my $inner_joined = join ' ', map {
			my $t = $_ // '';
			$t =~ s/^\s+//;
			$t =~ s/\s+\z//;
			$t;
		} @inner_chunks;
		my @parts = grep { $_ ne '' } map {
			my $p = $_;
			$p =~ s/^\s+//;
			$p =~ s/\s+\z//;
			$p;
		} split /\s*,\s*/, $inner_joined;
		if ( ! @parts ) {
			push @out, $line;
			next;
		}

		my ( $base_indent ) = $line =~ /^(\s*)/;
		my $inner_indent = $base_indent . "\t";
		push @out, $prefix . $open;
		for my $part ( @parts ) {
			push @out, $inner_indent . $part . ',';
		}
		my $tail = defined $after_close ? $after_close : '';
		$tail =~ s/^\s+//;
		my $extra_skip = 0;
		if ( $tail eq '' and $j + 1 <= $#lines and $lines[ $j + 1 ] =~ /^\s*;\s*\z/ ) {
			$tail = ';';
			$extra_skip = 1;
		}
		push @out, $base_indent . $close . $tail;
		$i = $j + $extra_skip;
	}

	return join "\n", @out;
}

=pod

=head1 NAME

Zuzu::Tidy - format ZuzuScript source with consistent style

=head1 SYNOPSIS

  use Zuzu::Tidy;

  my $tidied = Zuzu::Tidy->tidy( $source, filename => 'main.zzs' );
  my $canonical = Zuzu::Tidy->tidy(
      $source,
      filename => 'main.zzs',
      canonical_operators => 1,
  );

=head1 DESCRIPTION

C<Zuzu::Tidy> rewrites ZuzuScript text into a consistent house style.
It tokenizes with C<Zuzu::Lexer> and validates syntax with C<Zuzu::Parser>
before rewriting. Pod sections are passed through unchanged.

The tidier applies indentation, brace placement, operator spacing,
parenthesis/bracket spacing, and adds trailing statement semicolons when
needed.

=head1 METHODS

=head2 tidy

Returns tidied source text as a single UTF-8 string.

Pass C<canonical_operators =E<gt> 1> to rewrite non-canonical operator
spellings such as C<*> and C<< |> >> to canonical forms such as C<×> and
C<▷>. This option is disabled by default.

=head1 SEE ALSO

L<Zuzu::Lexer>, L<Zuzu::Parser>, L<Zuzu::Tidy::CLI>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Tidy >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
