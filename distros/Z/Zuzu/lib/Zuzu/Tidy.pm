package Zuzu::Tidy;

use utf8;
use strict;
use warnings;

our $VERSION = '0.007001';

use Zuzu::Lexer;
use Zuzu::Parser;
use Zuzu::Token;

my %BINARY_OP = map { $_ => 1 } qw(
	+ - * / × ÷ ** mod
	_ ~
	= == != < > <= >= <=> eq ne gt ge lt le cmp eqi nei gti gei lti lei cmpi
	and and? or or? xor xor? nand nand? nor nor? xnor xnor? onlyif onlyif? butnot butnot?
	× ÷ ≠ ≤ ≥ ≡ ≢ ≶ ≷ ⋀ ⋀? ⋁ ⋁? ⊻ ⊻? ⊼ ⊼? ⊽ ⊽? ↔ ↔? ⊨ ⊨? ⊭ ⊭?
	in ∈ ∉ union ⋃ intersection ⋂ subsetof ⊂ supersetof ⊃ equivalentof ⊂⊃ ∖
	instanceof does can
	default
	& | ^
	<< >> « »
	∣ ∤ divides
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
$UNARY_PREFIX_OP{'#'} = 1;
my %NO_SPACE_BEFORE = map { $_ => 1 } ( ',', ';', ')', ']', '}', '⌋', '⌉', '.', ':' );
my %NO_SPACE_AFTER  = map { $_ => 1 } ( '(', '[', '{', '⌊', '⌈', '.' );
my %CONTROL_KW = map { $_ => 1 } qw( if else while for switch catch unless );

# Delimiter types that can open/close a comma-separated sequence body
# (array/dict/pairlist literal, set/bag/guillemet-set literal, or a
# call/parameter argument list). << and « are ambiguous with the binary
# "shift" operator of the same spelling, so they (and their closes >> and
# ») only engage this tracking when _build_pair_map judged them to be a
# genuine literal delimiter -- i.e. when they have an entry in %pair_for.
my %_SEQUENCE_OPEN  = ( '(' => 1, '[' => 1, '{' => 1, '<<' => 1, '<<<' => 1, '«' => 1 );
my %_SEQUENCE_CLOSE = ( ')' => 1, ']' => 1, '>>' => 1, '>>>' => 1, '»' => 1 );
my %_AMBIGUOUS_ANGLE = ( '<<' => 1, '«' => 1, '>>' => 1, '»' => 1 );
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
	'divides'      => '∣',
	'and'          => '⋀',
	'and?'         => '⋀?',
	'nand'         => '⊼',
	'nand?'        => '⊼?',
	'nor'          => '⊽',
	'nor?'         => '⊽?',
	'xor'          => '⊻',
	'xor?'         => '⊻?',
	'xnor'         => '↔',
	'xnor?'        => '↔?',
	'or'           => '⋁',
	'or?'          => '⋁?',
	'onlyif'       => '⊨',
	'onlyif?'      => '⊨?',
	'butnot'       => '⊭',
	'butnot?'      => '⊭?',
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
		$tidied = _normalize_split_sequence_literals($tidied);
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
	_tag_declaration_block_braces( \@tokens );

	my %pair_for = _build_pair_map( \@tokens );
	_tag_trailing_comma_sequences( \@tokens, \%pair_for );

	my $indent = 0;
	my $paren_depth = 0;
	my $bracket_depth = 0;
	my $brace_depth = 0;
	my $inline_brace_depth = 0;
	my $angle_depth = 0;
	my @brace_kind_stack;
	my @sequence_stack;
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
		my $is_other_sequence_close = (
			$_SEQUENCE_CLOSE{$val}
			and $val ne '}'
			and ( ! $_AMBIGUOUS_ANGLE{$val} or exists $pair_for{$i} )
			and @sequence_stack
			and $sequence_stack[-1]
		);

		if (
			( $val eq '}' and ( $close_kind eq 'block' or $close_kind eq 'expr_block' ) )
			or $is_other_sequence_close
		) {
			if ( @sequence_stack and $sequence_stack[-1] and $line =~ /\S/ and $line !~ /,\s*\z/ ) {
				# Every entry, including the last, gets a trailing comma
				# when the body is split one-entry-per-line below.
				$line .= ',';
			}
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

		if ( $_SEQUENCE_OPEN{$val} and ( ! $_AMBIGUOUS_ANGLE{$val} or exists $pair_for{$i} ) ) {
			my $is_inline = 1;
			my $kind = 'inline';
			if ( $val eq '{' ) {
				$is_inline = _is_inline_brace( \@tokens, $i, \%pair_for );
				$kind = $is_inline ? 'inline'
					: _is_expression_block_brace( \@tokens, $i ) ? 'expr_block'
					: 'block';
				push @brace_kind_stack, $kind;
			}

			my $is_pairlist_body = ( $val eq '{' and defined $tok->{_pairlist_half} and $tok->{_pairlist_half} eq 'open2' ) ? 1 : 0;
			my $is_sequence_body = $is_pairlist_body || ( $tok->{_force_sequence} ? 1 : 0 );
			push @sequence_stack, $is_sequence_body;

			if ( $val eq '(' ) {
				$paren_depth++;
			}
			elsif ( $val eq '[' ) {
				$bracket_depth++;
			}
			elsif ( $val eq '{' ) {
				$brace_depth++;
				$inline_brace_depth++ if $is_inline;
			}
			else {
				# << <<< «
				$angle_depth++;
			}

			my $forces_newline = ( $val eq '{' ) ? ( ! $is_inline ) : ( $is_sequence_body ? 1 : 0 );
			if ( $forces_newline ) {
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
		if ( $val eq ',' and @sequence_stack and $sequence_stack[-1] ) {
			# Inside any sequence body (pairlist, dict, array, set, bag,
			# guillemet-set, or argument/parameter list) that must be
			# rendered one-item-per-line, each entry -- including the
			# last -- is placed on its own line, separated by the literal
			# commas already present in the source.
			push @out_lines, _rstrip($line);
			$line = '';
			$pending_indent = 1;
			$continuation_indent = 0;
			next;
		}
		if ( $val eq '}' ) {
			my $kind = @brace_kind_stack ? pop @brace_kind_stack : 'block';
			my $is_sequence_body = @sequence_stack ? pop @sequence_stack : 0;
			# A forced dict literal's } ends a value, not a statement
			# block, so (like pairlist close2, which is already 'inline'
			# kind) it must remain eligible for the same generic
			# end-of-value auto-semicolon treatment that _needs_auto_semicolon
			# otherwise blanket-excludes for 'block'/'expr_block' closes.
			$just_closed_inline = 1 if $kind eq 'inline' or $is_sequence_body;
			$brace_depth-- if $brace_depth > 0;
			$inline_brace_depth-- if $kind eq 'inline' and $inline_brace_depth > 0;
			my $is_pairlist_close1 = ( defined $tok->{_pairlist_half} && $tok->{_pairlist_half} eq 'close1' ) ? 1 : 0;
			if ( ( $kind eq 'block' or $kind eq 'expr_block' ) and ! $is_pairlist_close1 and ! $is_sequence_body ) {
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
				if (
					( $kind eq 'block' or $kind eq 'expr_block' )
					and ( $paren_depth > 0 or $bracket_depth > 0 )
					and $next
					and $next->is_OP
					and ( $next->value eq ',' or $next->value eq ')' or $next->value eq ']' )
				) {
					# A callback/anonymous-function body that is itself a
					# call argument or array item: keep its closing } glued
					# to the `,`, `)`, or `]` that follows, instead of
					# stranding the rest of the argument list or array on
					# its own line (`}, 4 );` rather than `}\n, 4, );`).
					# Falling through without flushing here, rather than
					# consuming $next directly, lets that token's own
					# normal handling run on the next iteration -- so if
					# the enclosing sequence is itself forced
					# one-item-per-line, the generic comma separator (or
					# the enclosing close's own pre-emission flush) still
					# fires for it exactly as for every other item.
					next;
				}
				if ( $kind eq 'block' and $next and $next->is_OP(';') and ! ( @sequence_stack and $sequence_stack[-1] ) ) {
					# A control construct (e.g. try/catch) used as an
					# expression value, terminated by an explicit `;`:
					# glue the semicolon to the closing } instead of
					# stranding it alone on the next line.
					$line .= ';';
					$i++;
				}
				push @out_lines, _rstrip($line);
				$line = '';
				$pending_indent = 1;
				next;
			}
		}
		elsif ( $_SEQUENCE_CLOSE{$val} and ( ! $_AMBIGUOUS_ANGLE{$val} or exists $pair_for{$i} ) ) {
			# A forced sequence's own closing delimiter never forces a new
			# line to start for whatever follows it (unlike the pre-emission
			# flush above, which only dedents the close itself onto its own
			# line). Falling through lets the close glue naturally to a
			# following `,`/`)`/`;` exactly as an ordinary, non-forced close
			# already does, and lets the bottom-of-loop auto-semicolon check
			# supply a `;` when this is the last token of a statement.
			pop @sequence_stack if @sequence_stack;
			if ( $val eq ')' ) {
				$paren_depth-- if $paren_depth > 0;
			}
			elsif ( $val eq ']' ) {
				$bracket_depth-- if $bracket_depth > 0;
			}
			else {
				# >> >>> »
				$angle_depth-- if $angle_depth > 0;
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

		if ( $next and _needs_auto_semicolon( $tok, $next, $paren_depth, $bracket_depth, $brace_depth, $inline_brace_depth, $just_closed_inline, $angle_depth ) ) {
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
			my $open1 = Zuzu::Token->new(
				type => 'OP',
				value => '{',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			my $open2 = Zuzu::Token->new(
				type => 'OP',
				value => '{',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			# Pairlist delimiter halves are tagged so formatting decisions
			# (inline-vs-block brace classification) never depend on
			# guessing from surrounding context, which previously broke
			# down for contexts such as `...{{ ... }}` spreads.
			$open1->{_pairlist_half} = 'open1';
			$open2->{_pairlist_half} = 'open2';
			push @out, $open1, $open2;
			next;
		}
		if ( $tok->is_OP('}}') ) {
			my $close1 = Zuzu::Token->new(
				type => 'OP',
				value => '}',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			my $close2 = Zuzu::Token->new(
				type => 'OP',
				value => '}',
				file => $tok->file,
				line => $tok->line,
				col => $tok->col,
			);
			$close1->{_pairlist_half} = 'close1';
			$close2->{_pairlist_half} = 'close2';
			push @out, $close1, $close2;
			next;
		}
		push @out, $tok;
	}

	return @out;
}

sub _tag_declaration_block_braces {
	# Marks the `{` that opens a class/trait/function/method body, even
	# when separated from the keyword by a variable-length clause such as
	# a return-type arrow (`-> Type`) or a trait list (`with A, B`). A
	# fixed-distance backward look from the brace can't see far enough
	# back to find the keyword in those cases, which used to leave
	# declaration bodies classified as inline. This scans forward from
	# each keyword instead, so the gap can be any length.
	my ( $tokens ) = @_;

	for my $i ( 0 .. $#$tokens ) {
		my $tok = $tokens->[$i];
		next if ! $tok->is_KW;
		my $kw = $tok->value;

		if ( $kw eq 'class' or $kw eq 'trait' ) {
			my $k = $i + 1;
			next if $k > $#$tokens or ! $tokens->[$k]->is_IDENT;
			$k++;

			my $changed = 1;
			while ( $changed ) {
				$changed = 0;
				if (
					$k <= $#$tokens and $tokens->[$k]->is_KW('extends')
					and $k + 1 <= $#$tokens and $tokens->[ $k + 1 ]->is_IDENT
				) {
					$k += 2;
					$changed = 1;
				}
				if ( $k <= $#$tokens and ( $tokens->[$k]->is_KW('with') or $tokens->[$k]->is_KW('but') ) ) {
					my $j = $k + 1;
					if ( $j <= $#$tokens and $tokens->[$j]->is_IDENT ) {
						$j++;
						while (
							$j + 1 <= $#$tokens
							and $tokens->[$j]->is_OP(',')
							and $tokens->[ $j + 1 ]->is_IDENT
						) {
							$j += 2;
						}
						$k = $j;
						$changed = 1;
					}
				}
			}

			$tokens->[$k]{_forced_block} = 1 if $k <= $#$tokens and $tokens->[$k]->is_OP('{');
			next;
		}

		if ( $kw eq 'function' or $kw eq 'method' ) {
			my $k = $i + 1;
			$k++ if $k <= $#$tokens and $tokens->[$k]->is_IDENT;
			next if $k > $#$tokens or ! $tokens->[$k]->is_OP('(');

			my $depth = 0;
			my $j = $k;
			while ( $j <= $#$tokens ) {
				$depth++ if $tokens->[$j]->is_OP('(');
				if ( $tokens->[$j]->is_OP(')') ) {
					$depth--;
					last if $depth == 0;
				}
				$j++;
			}
			next if $j > $#$tokens;
			$k = $j + 1;

			if (
				$k <= $#$tokens and $tokens->[$k]->is_OP
				and ( $tokens->[$k]->value eq '->' or $tokens->[$k]->value eq '→' )
			) {
				$k++;
				$k++ if $k <= $#$tokens and $tokens->[$k]->is_IDENT;
			}

			$tokens->[$k]{_forced_block} = 1 if $k <= $#$tokens and $tokens->[$k]->is_OP('{');
		}
	}

	return;
}

my %_PAIR_CLOSE_FOR_OPEN = (
	'(' => ')', '[' => ']', '{' => '}', '⌊' => '⌋', '⌈' => '⌉',
	'<<' => '>>', '<<<' => '>>>', '«' => '»',
);
my %_PAIR_OPEN_FOR_CLOSE = reverse %_PAIR_CLOSE_FOR_OPEN;

sub _build_pair_map {
	my ( $tokens ) = @_;
	my @stack;
	my %pair;

	for my $i ( 0 .. $#$tokens ) {
		# Guarded by is_OP so a string/binary-string literal whose decoded
		# content happens to equal a bracket character (e.g. the literal
		# string "(" in `left:"("`) isn't mistaken for that bracket.
		next if ! $tokens->[$i]->is_OP;
		my $v = $tokens->[$i]->value;

		# << and « are genuinely dual-use: the real parser treats them as a
		# set/guillemet-set literal opener in primary/operand position, but
		# they also have real binary-operator ("shift") precedence in infix
		# position (see _Impl.pm's precedence table). Only push them as
		# pairable openers when they're in operand position -- i.e. NOT
		# immediately after a token that could end an expression -- so a
		# shift expression never corrupts the stack for surrounding
		# brackets. <<< (bag) has no such binary-operator meaning and is
		# always pushed.
		if ( ( $v eq '<<' or $v eq '«' ) and $i > 0 and _can_end_statement( $tokens->[ $i - 1 ] ) ) {
			next;
		}

		if ( $_PAIR_CLOSE_FOR_OPEN{$v} ) {
			push @stack, [ $v, $i ];
			next;
		}
		if ( $_PAIR_OPEN_FOR_CLOSE{$v} ) {
			next if ! @stack;
			my ( $open, $open_i ) = @{ $stack[-1] };
			next if $_PAIR_CLOSE_FOR_OPEN{$open} ne $v;
			pop @stack;
			$pair{$open_i} = $i;
			$pair{$i} = $open_i;
		}
	}

	return %pair;
}

sub _tag_trailing_comma_sequences {
	# Marks an open delimiter of a comma-separated sequence (call/parameter
	# argument list, array, dict, set, bag, or guillemet-set literal) when
	# the token immediately before its matching close is a literal comma.
	# A literal trailing comma is a strong signal that the sequence should
	# be rendered one item per line, so this is decided once up front (like
	# _tag_declaration_block_braces) rather than guessed at format time.
	# Bare { is included for dict literals; pairlist {{ ... }} is left
	# alone since it is already unconditionally forced via _pairlist_half.
	my ( $tokens, $pair_for ) = @_;

	for my $i ( 0 .. $#$tokens ) {
		my $tok = $tokens->[$i];
		next if ! $tok->is_OP;
		my $v = $tok->value;
		next if $v ne '(' and $v ne '[' and $v ne '<<' and $v ne '<<<' and $v ne '«' and $v ne '{';
		next if $v eq '{' and defined $tok->{_pairlist_half};

		next if ! exists $pair_for->{$i};
		my $close_i = $pair_for->{$i};
		next if $close_i <= $i + 1;

		my $before_close = $tokens->[ $close_i - 1 ];
		next if ! $before_close->is_OP(',');

		$tok->{_force_sequence} = 1;
	}

	return;
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
		# Two genuinely independent adjacent closing braces (e.g. nested
		# dict literals) need a space, since re-lexing "}}" with no space
		# would produce a single pairlist-close token instead. The two
		# halves of an actual split {{ ... }} pairlist delimiter must stay
		# tight, since that is what they were before splitting.
		return 0 if defined $tok->{_pairlist_half} and $tok->{_pairlist_half} eq 'close2'
			and defined $prev->{_pairlist_half} and $prev->{_pairlist_half} eq 'close1';
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

	if ( $v eq ':' and _is_switch_comparator_colon( $tokens, $i ) ) {
		return 1;
	}
	if ( $pv eq ':' and _is_slice_colon( $tokens, $i - 1, $pair_for ) ) {
		return 0;
	}

	# Guarded by is_OP so a string/binary-string literal whose decoded
	# content happens to equal a punctuation operator (e.g. the literal
	# string ":" in `text _ ":" _ item`) isn't mistaken for that
	# operator and tightened against its neighbour.
	return 0 if $tok->is_OP and $NO_SPACE_BEFORE{$v} and $v ne ')' and $v ne ']';
	return 0 if $prev->is_OP and $NO_SPACE_AFTER{$pv} and $pv ne '(' and $pv ne '[';

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
		if ( $v eq '[' and $prev->is_OP and $pv ne '.' and $pv ne ')' and $pv ne ']' and $pv ne '}' ) {
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

sub _enclosing_open_index {
	# Returns the token index of the nearest enclosing unmatched
	# `(`/`[`/`{` before position $i, or undef at the top level.
	my ( $tokens, $i ) = @_;

	my @stack;
	for my $k ( 0 .. $i - 1 ) {
		my $v = defined $tokens->[$k]->value ? $tokens->[$k]->value : '';
		if ( $v eq '(' or $v eq '[' or $v eq '{' ) {
			push @stack, $k;
		}
		elsif ( $v eq ')' or $v eq ']' or $v eq '}' ) {
			pop @stack if @stack;
		}
	}

	return @stack ? $stack[-1] : undef;
}

sub _is_switch_comparator_colon {
	# The `:` that separates a switch subject expression from its
	# comparator operator, e.g. `switch ( n mod 4 : = )`, reads better
	# with a space on both sides, unlike every other use of `:` (case
	# labels, dict keys, ternaries, slices), which stay tight. Detected
	# by finding the nearest enclosing unmatched bracket: it must be a
	# `(` opened directly by the `switch` keyword, not some deeper
	# bracket (e.g. a slice inside the switch subject).
	my ( $tokens, $i ) = @_;
	return 0 if !$tokens->[$i]->is_OP(':');

	my $open_i = _enclosing_open_index( $tokens, $i );
	return 0 if !defined $open_i;
	return 0 if !$tokens->[$open_i]->is_OP('(');
	return 0 if $open_i == 0;
	return 1 if $tokens->[ $open_i - 1 ]->is_KW('switch');

	return 0;
}

sub _is_simple_slice_inner {
	# True if the tokens between `[` and `]` look like a slice:
	# zero or more `:`-separated parts, each either empty (an omitted
	# bound, e.g. `[:2]`) or a single simple token.
	my ( @inner ) = @_;

	my @parts = ( [] );
	for my $tok ( @inner ) {
		if ( $tok->is_OP(':') ) {
			push @parts, [];
			next;
		}
		push @{ $parts[-1] }, $tok;
	}
	return 0 if @parts < 2;

	for my $part ( @parts ) {
		return 0 if @$part > 1;
		return 0 if @$part == 1 and !_is_simple_token( $part->[0] );
	}

	return 1;
}

sub _is_slice_colon {
	# A `:` directly inside `[ ... ]` that separates simple slice bounds,
	# e.g. `text[1:2]`, stays tight on both sides, unlike a dict key's
	# `:` (`{ a: 1 }`) or the switch comparator's `:`.
	my ( $tokens, $i, $pair_for ) = @_;
	return 0 if !$tokens->[$i]->is_OP(':');

	my $open_i = _enclosing_open_index( $tokens, $i );
	return 0 if !defined $open_i;
	return 0 if !$tokens->[$open_i]->is_OP('[');
	my $close_i = $pair_for->{$open_i};
	return 0 if !defined $close_i;

	my @inner = @{$tokens}[ $open_i + 1 .. $close_i - 1 ];
	return _is_simple_slice_inner(@inner);
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
	if ( $tokens->[$open_i]->is_OP('[') and _is_simple_slice_inner(@inner) ) {
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
	my ( $tok, $next, $paren_depth, $bracket_depth, $brace_depth, $inline_brace_depth, $just_closed_inline, $angle_depth ) = @_;
	return 0 if $tok->is_OP and ( $tok->value eq ';' or $tok->value eq '{' );
	return 0 if $tok->is_OP and $tok->value eq '}' and ! $just_closed_inline;
	return 0 if $tok->is_OP and $tok->value eq ':';
	return 0 if $tok->is_KW('else');
	if ( $next->is_KW and ( $next->value eq 'if' or $next->value eq 'unless' ) ) {
		return 0;
	}
	return 0 if $next->is_OP and ( $next->value eq ';' or $next->value eq ')' or $next->value eq ']' or $next->value eq '⌋' or $next->value eq '⌉' or $next->value eq ',' or $next->value eq ':' );
	return 0 if $paren_depth > 0 or $bracket_depth > 0 or ( $angle_depth // 0 ) > 0;
	return 0 if $inline_brace_depth > 0;
	return 1 if $next->is_OP and $next->value eq '}' and _can_end_statement($tok);
	return 1 if $next->is_KW('else');
	return 1 if $tok->line < $next->line and _can_end_statement($tok) and _can_start_statement($next);

	return 0;
}

sub _is_inline_brace {
	my ( $tokens, $i, $pair_for ) = @_;
	return 0 if $i <= 0;

	return 0 if $tokens->[$i]{_forced_block};
	return 0 if $tokens->[$i]{_force_sequence};

	my $pairlist_half = $tokens->[$i]{_pairlist_half};
	if ( defined $pairlist_half ) {
		# The first half of a split {{ is always inline, so it never
		# triggers its own newline/indent; the second half is always
		# block-kind, which is what produces the indented pairlist body.
		# This is independent of whatever token precedes the pairlist
		# (e.g. a spread `...`), unlike the heuristics below.
		return 1 if $pairlist_half eq 'open1';
		return 0 if $pairlist_half eq 'open2';
	}

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
	my $paren_bracket_depth = 0;

	for my $i ( 0 .. $#lines ) {
		my $trimmed = $lines[$i];
		$trimmed =~ s/^\s+//;
		$trimmed =~ s/\s+\z//;

		# Track paren/bracket nesting across lines (approximate: doesn't
		# account for parens inside string literals) so a brace opened
		# while still inside an unclosed `(`/`[` -- e.g. a callback body
		# passed as a call argument -- can be told apart from a real
		# top-level statement block below.
		my $opens = () = $trimmed =~ /[(\[]/g;
		my $closes = () = $trimmed =~ /[)\]]/g;

		if ( $trimmed =~ /\{\z/ ) {
			my $kind = 'block';
			if ( $trimmed =~ /^(function|method)\b/ ) {
				$kind = $1;
			}
			elsif ( $trimmed =~ /^(if|else|while|for|try|catch|switch|unless)\b/ ) {
				$kind = 'statement_block';
			}
			push @stack, {
				kind             => $kind,
				start            => $i,
				is_call_argument => ( $paren_bracket_depth + $opens - $closes > 0 ) ? 1 : 0,
			};
			$open_for_line[$i] = $stack[-1];
		}

		$paren_bracket_depth += $opens - $closes;

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
			if ( ( $kind eq 'function' or $kind eq 'method' ) and ! $open_block->{is_call_argument} ) {
				$blank_before{$i} = 1;
			}
		}

		my $close_block = $close_for_line[$i];
		if ($close_block) {
			my $kind = $close_block->{kind};
			my $len = $close_block->{end} - $close_block->{start} + 1;
			if ( ( $kind eq 'function' or $kind eq 'method' ) and ! $close_block->{is_call_argument} ) {
				my $next_nonblank = _next_nonblank_line( \@lines, $i + 1 );
				if ( defined $next_nonblank and $lines[$next_nonblank] !~ /^\s*\}/ ) {
					$blank_after{$i} = 1;
				}
			}
			if ( $len >= 5 and ! $close_block->{is_call_argument} ) {
				$blank_before{ $close_block->{start} } = 1;
				my $next_nonblank = _next_nonblank_line( \@lines, $i + 1 );
				my $cuddles = defined $next_nonblank
					&& $lines[$next_nonblank] =~ /^\s*(?:catch|else)\b/;
				$blank_after{$i} = 1 if ! $cuddles;
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

sub _find_matching_sequence_close {
	# Depth-aware search for the close delimiter matching the open
	# delimiter already consumed at the start of $after_open. Unlike a
	# plain textual scan for the first occurrence of $close, this tracks
	# nesting so an inner occurrence of the same bracket type (e.g. the
	# index brackets in `async_lambdas[0]` nested inside an outer `[ ... ]`
	# array literal) is not mistaken for the outer literal's close.
	my ( $lines, $start_i, $after_open, $open, $close ) = @_;
	my $depth = 1;

	for my $j ( $start_i .. $#$lines ) {
		my $text = $j == $start_i ? $after_open : $lines->[$j];
		while ( $text =~ /(\Q$open\E|\Q$close\E)/g ) {
			if ( $1 eq $open ) {
				$depth++;
			}
			else {
				$depth--;
				if ( $depth == 0 ) {
					my $end = pos($text);
					my $before = substr( $text, 0, $end - length($1) );
					my $after = substr( $text, $end );
					return ( $j, $before, $after );
				}
			}
		}
	}

	return ();
}

sub _split_top_level_commas {
	# Splits already-joined inner sequence content on commas, but only at
	# bracket depth 0 -- a comma inside a nested array/call/set/etc item
	# (e.g. reconstructing a sequence whose items are themselves bracketed
	# sub-expressions) must stay with that item rather than being treated
	# as another top-level separator.
	my ( $text ) = @_;
	my @parts;
	my $depth = 0;
	my $current = '';
	my $pos = 0;
	my $len = length $text;

	while ( $pos < $len ) {
		my $three = substr( $text, $pos, 3 );
		if ( $three eq '<<<' or $three eq '>>>' ) {
			$depth += $three eq '<<<' ? 1 : -1;
			$current .= $three;
			$pos += 3;
			next;
		}
		my $two = substr( $text, $pos, 2 );
		if ( $two eq '<<' or $two eq '>>' ) {
			$depth += $two eq '<<' ? 1 : -1;
			$current .= $two;
			$pos += 2;
			next;
		}
		my $ch = substr( $text, $pos, 1 );
		if ( $ch eq '(' or $ch eq '[' or $ch eq '{' or $ch eq '«' or $ch eq '⌊' or $ch eq '⌈' ) {
			$depth++;
		}
		elsif ( $ch eq ')' or $ch eq ']' or $ch eq '}' or $ch eq '»' or $ch eq '⌋' or $ch eq '⌉' ) {
			$depth--;
		}
		elsif ( $ch eq ',' and $depth == 0 ) {
			push @parts, $current;
			$current = '';
			$pos++;
			next;
		}
		$current .= $ch;
		$pos++;
	}
	push @parts, $current if $current ne '';

	return @parts;
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
		if ( ! defined $open or $after_open !~ /\S/ ) {
			# Nothing after the open delimiter on this line means it was
			# already split (e.g. by the trailing-comma-forces-multi-line
			# mechanism in _tidy_code_chunk); reprocessing it would flatten
			# the already-correct nested structure onto fewer lines.
			push @out, $line;
			next;
		}

		my $close = $close_for{$open};
		my ( $j, $before_close, $after_close )
			= _find_matching_sequence_close( \@lines, $i, $after_open, $open, $close );
		if ( ! defined $j ) {
			push @out, $line;
			next;
		}
		if ( $j == $i ) {
			push @out, $line;
			next;
		}

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
		} _split_top_level_commas($inner_joined);
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
