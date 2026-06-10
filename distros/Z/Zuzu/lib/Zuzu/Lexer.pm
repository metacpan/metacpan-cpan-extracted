package Zuzu::Lexer;

use utf8;

our $VERSION = '0.003000';

use Zuzu::Token ();
use Zuzu::Util ();

use Moo;

has 'src' => ( is => 'rw', default => sub { '' } );
has 'filename' => ( is => 'rw' );
has 'pos' => ( is => 'rw', default => sub { 0 } );
has 'line' => ( is => 'rw', default => sub { 1 } );
has 'col' => ( is => 'rw', default => sub { 1 } );
has 'last_token' => ( is => 'rw' );

around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;

	my $args = $class->$orig(@args);
	$args->{src} = Zuzu::Util::nfc($args->{src} // '');

	return $args;
};

sub _peek {
	my ($self, $n) = @_;

	$n //= 1;

	return substr($self->src, $self->pos, $n);
}

sub _eof { $_[0]->pos >= length($_[0]->src) }

sub _adv {
	my ($self, $n) = @_;

	$n //= 1;
	for (1..$n) {
		my $ch = substr($self->src, $self->pos, 1);
		$self->pos( $self->pos + 1 );
		if ( $ch eq "\n" ) {
			$self->line( $self->line + 1 );
			$self->col(1);
		}
		else {
			$self->col( $self->col + 1 );
		}
	}
}

sub _mk {
	my ($self, $type, $value, $line, $col) = @_;

	return Zuzu::Token->new(
		type => $type,
		value => $value,
		file => $self->filename,
		line => $line,
		col  => $col,
	);
}

sub _emit {
	my ( $self, $type, $value, $line, $col ) = @_;
	my $tok = $self->_mk( $type, $value, $line, $col );
	$self->last_token($tok) if $type ne 'EOF';

	return $tok;
}

sub _read_escape {
	my ( $self, $kind, $line, $col ) = @_;

	die "Unterminated $kind literal at line $line, col $col" if $self->_eof;
	my $e = $self->_peek(1);
	my %simple = (
		n => "\n",
		t => "\t",
		r => "\r",
		'"' => '"',
		"'" => "'",
		'`' => '`',
		'/' => '/',
		'$' => '$',
		'\\' => '\\',
	);
	if ( exists $simple{$e} ) {
		$self->_adv(1);
		return $simple{$e};
	}
	if ( $e eq 'x' ) {
		my $hex = $self->_peek(3);
		die "Invalid $kind escape at line $line, col $col"
			if $hex !~ /\Ax([0-9A-Fa-f]{2})\z/;
		$self->_adv(3);
		return $kind eq 'binary string' ? pack( 'C', hex($1) ) : chr( hex($1) );
	}
	if ( $e eq 'u' ) {
		die "Invalid $kind escape at line $line, col $col"
			if $kind eq 'binary string';
		my $hex = $self->_peek(5);
		die "Invalid $kind escape at line $line, col $col"
			if $hex !~ /\Au([0-9A-Fa-f]{4})\z/;
		my $cp = hex($1);
		die "Invalid $kind escape at line $line, col $col"
			if $cp >= 0xD800 and $cp <= 0xDFFF;
		$self->_adv(5);
		return chr($cp);
	}

	die "Invalid $kind escape at line $line, col $col";
}

sub _read_single_line_literal {
	my ( $self, $quote, $kind, $line, $col ) = @_;

	$self->_adv(1);
	my $out = '';
	while ( !$self->_eof ) {
		my $c = $self->_peek(1);
		last if $c eq $quote;
		if ( $c eq "\\" ) {
			$self->_adv(1);
			$out .= $self->_read_escape( $kind, $line, $col );
			next;
		}
		$out .= $c;
		$self->_adv(1);
	}
	die "Unterminated $kind literal at line $line, col $col" if $self->_eof;
	$self->_adv(1);

	return $out;
}

sub _split_interpolated_source {
	my ( $self, $src, $line, $col, $kind, $allow_escaped_dollar ) = @_;

	my @parts;
	my $text = '';
	my $i = 0;
	my $len = length $src;
	while ( $i < $len ) {
		my $ch = substr( $src, $i, 1 );
		if ( $allow_escaped_dollar and $ch eq "\\" and $i + 1 < $len and substr( $src, $i + 1, 1 ) eq '$' ) {
			$text .= '\\$';
			$i += 2;
			next;
		}
		if ( $ch eq '$' and $i + 1 < $len and substr( $src, $i + 1, 1 ) eq '{' ) {
			push @parts, { text => $text } if $text ne '';
			$text = '';
			$i += 2;
			my $start = $i;
			my $depth = 1;
			my $quote;
			my $line_comment = 0;
			my $block_comment = 0;
			while ( $i < $len ) {
				my $c = substr( $src, $i, 1 );
				my $next = $i + 1 < $len ? substr( $src, $i + 1, 1 ) : '';
				if ($line_comment) {
					$line_comment = 0 if $c eq "\n";
					$i++;
					next;
				}
				if ($block_comment) {
					if ( $c eq '*' and $next eq '/' ) {
						$i += 2;
						$block_comment = 0;
						next;
					}
					$i++;
					next;
				}
				if ( defined $quote ) {
					if ( $c eq "\\" ) {
						$i += 2;
						next;
					}
					if ( $c eq $quote ) {
						$quote = undef;
					}
					$i++;
					next;
				}
				if ( $c eq '"' or $c eq "'" or $c eq '`' ) {
					$quote = $c;
					$i++;
					next;
				}
				if ( $c eq '/' and $next eq '/' ) {
					$line_comment = 1;
					$i += 2;
					next;
				}
				if ( $c eq '/' and $next eq '*' ) {
					$block_comment = 1;
					$i += 2;
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
			die "Unterminated $kind interpolation at line $line, col $col" if $i >= $len;
			push @parts, { expr => substr( $src, $start, $i - $start ) };
			$i++;
			next;
		}
		$text .= $ch;
		$i++;
	}
	push @parts, { text => $text } if $text ne '' or !@parts;

	return \@parts;
}

sub _decode_interpolated_text_parts {
	my ( $self, $parts, $kind, $line, $col ) = @_;

	for my $part ( @{$parts} ) {
		next if !exists $part->{text};
		my $src = $part->{text};
		my $out = '';
		my $i = 0;
		while ( $i < length $src ) {
			my $c = substr( $src, $i, 1 );
			if ( $c eq "\\" ) {
				$i++;
				die "Unterminated $kind literal at line $line, col $col" if $i >= length $src;
				my $e = substr( $src, $i, 1 );
				my %simple = (
					n => "\n",
					t => "\t",
					r => "\r",
					'"' => '"',
					"'" => "'",
					'`' => '`',
					'/' => '/',
					'$' => '$',
					'\\' => '\\',
				);
				if ( exists $simple{$e} ) {
					$out .= $simple{$e};
					$i++;
					next;
				}
				if ( $e eq 'x' ) {
					my $hex = substr( $src, $i, 3 );
					die "Invalid $kind escape at line $line, col $col"
						if $hex !~ /\Ax([0-9A-Fa-f]{2})\z/;
					$out .= chr( hex($1) );
					$i += 3;
					next;
				}
				if ( $e eq 'u' ) {
					my $hex = substr( $src, $i, 5 );
					die "Invalid $kind escape at line $line, col $col"
						if $hex !~ /\Au([0-9A-Fa-f]{4})\z/;
					my $cp = hex($1);
					die "Invalid $kind escape at line $line, col $col"
						if $cp >= 0xD800 and $cp <= 0xDFFF;
					$out .= chr($cp);
					$i += 5;
					next;
				}
				die "Invalid $kind escape at line $line, col $col";
				next;
			}
			$out .= $c;
			$i++;
		}
		$part->{text} = $out;
	}

	return $parts;
}

sub _can_start_regexp {
	my ( $self ) = @_;
	my $prev = $self->last_token;

	return 1 if !defined $prev;
	return 0 if $prev->is_NUMBER || $prev->is_STRING || $prev->is_type('BINARY_STRING') || $prev->is_type('TEMPLATE') || $prev->is_BOOL || $prev->is_NULL || $prev->is_IDENT || $prev->is_REGEXP || $prev->is_EMPTY_SET;
	if ( $prev->is_KW ) {
		my $kw = $prev->value // '';
		return 0 if $kw eq 'self' || $kw eq 'super' || $kw eq 'true' || $kw eq 'false' || $kw eq 'null';
	}
	if ( $prev->is_OP ) {
		my $op = $prev->value // '';
		return 0 if $op eq ')' || $op eq ']' || $op eq '}';
		return 0 if $op eq '++' || $op eq '--';
	}

	return 1;
}

sub _read_regexp_literal {
	my ( $self, $line, $col ) = @_;

	$self->_adv(1); # leading /
	my $start = $self->pos;
	my $escaped = 0;
	my $in_class = 0;

	while ( !$self->_eof ) {
		my $c = $self->_peek(1);
		if ( !$escaped and !$in_class and $c eq '/' ) {
			my $pattern = substr( $self->src, $start, $self->pos - $start );
			$self->_adv(1);
			my $flags = '';
			while ( !$self->_eof ) {
				my $flag = $self->_peek(1);
				last if $flag ne 'i' and $flag ne 'g';
				last if index( $flags, $flag ) >= 0;
				$flags .= $flag;
				$self->_adv(1);
			}

			my $parts = $self->_split_interpolated_source( $pattern, $line, $col, 'regexp', 1 );
			return $self->_emit( 'REGEXP', { pattern => $pattern, parts => $parts, flags => $flags }, $line, $col );
		}
		if ( !$escaped and $c eq '[' ) {
			$in_class = 1;
		}
		elsif ( !$escaped and $c eq ']' ) {
			$in_class = 0;
		}
		$escaped = !$escaped && $c eq "\\" ? 1 : 0;
		$self->_adv(1);
	}

	die "Unterminated regexp literal at line $line, col $col";
}


sub _skip_shebang_line {
	my ( $self ) = @_;

	return 0 if $self->pos != 0;
	return 0 if $self->line != 1;
	return 0 if $self->col != 1;
	return 0 if $self->_peek(2) ne '#!';

	while ( !$self->_eof and $self->_peek(1) ne "\n" ) {
		$self->_adv(1);
	}
	$self->_adv(1) if !$self->_eof and $self->_peek(1) eq "\n";

	return 1;
}

sub _skip_pod_section {
	my ( $self ) = @_;

	return 0 if $self->col != 1;
	return 0 if $self->_peek(1) ne '=';

	my $rest = substr( $self->src, $self->pos );
	return 0 if $rest !~ /\A=(\w+)/u;

	my $word = $1;
	return 0 if $word eq 'cut';

	while ( !$self->_eof and $self->_peek(1) ne "\n" ) {
		$self->_adv(1);
	}
	$self->_adv(1) if !$self->_eof and $self->_peek(1) eq "\n";

	while ( !$self->_eof ) {
		my $line = substr( $self->src, $self->pos );
		if ( $self->col == 1 and $line =~ /\A=cut(?:\r?\n|\z)/ ) {
			$self->_adv(4);
			$self->_adv(1) if !$self->_eof and $self->_peek(1) eq "\r";
			$self->_adv(1) if !$self->_eof and $self->_peek(1) eq "\n";

			last;
		}

		$self->_adv(1);
	}

	return 1;
}

sub next_token {
	my ($self) = @_;

	while (!$self->_eof) {
		if ( $self->_skip_shebang_line ) {
			next;
		}

		if ( $self->_skip_pod_section ) {
			next;
		}

		my $ch = $self->_peek(1);

		# whitespace
		if ($ch =~ /\s/u) { $self->_adv(1); next; }

		# // comment
		if ($self->_peek(2) eq '//') {
			while (!$self->_eof && $self->_peek(1) ne "\n") { $self->_adv(1); }
			next;
		}

		# /* ... */ comment
		if ($self->_peek(2) eq '/*') {
			$self->_adv(2);
			while (!$self->_eof) {
				last if $self->_peek(2) eq '*/';
				$self->_adv(1);
			}
			$self->_adv(2) if !$self->_eof;
			next;
		}

		my ($line, $col) = ($self->line, $self->col);

		if ( $ch eq '/' and $self->_can_start_regexp ) {
			return $self->_read_regexp_literal( $line, $col );
		}
		if ( $self->_peek(2) eq '_=' ) {
			$self->_adv(2);

			return $self->_emit( 'OP', '_=', $line, $col );
		}

		if ( $ch eq '⊤' ) {
			$self->_adv(1);

			return $self->_emit('BOOL', 1, $line, $col);
		}
		if ( $ch eq '⊥' ) {
			$self->_adv(1);

			return $self->_emit('BOOL', 0, $line, $col);
		}

		# numbers: int/float
		if ($ch =~ /[0-9]/) {
			my $rest = substr($self->src, $self->pos);
			if ($rest =~ /\A([0-9]+(?:\.[0-9]+)?)/) {
				my $num = $1;
				$self->_adv(length($num));

				return $self->_emit('NUMBER', $num, $line, $col);
			}
		}

			# string "..." and """..."""
			if ($ch eq '"') {
				if ($self->_peek(3) eq '"""') {
					$self->_adv(3);
					my $start = $self->pos;
					while (!$self->_eof && $self->_peek(3) ne '"""') { $self->_adv(1); }
					die "Unterminated string literal at line $line, col $col" if $self->_eof;
					my $val = substr($self->src, $start, $self->pos - $start);
					$self->_adv(3);

					return $self->_emit('STRING', $val, $line, $col);
				}
				my $out = $self->_read_single_line_literal( '"', 'string', $line, $col );
				return $self->_emit('STRING', $out, $line, $col);
			}
			if ( $ch eq "'" ) {
				if ( $self->_peek(3) eq "'''" ) {
					$self->_adv(3);
					my $start = $self->pos;
					while ( !$self->_eof and $self->_peek(3) ne "'''" ) {
						$self->_adv(1);
					}
					die "Unterminated binary string literal at line $line, col $col" if $self->_eof;
					my $val = substr( $self->src, $start, $self->pos - $start );
					$self->_adv(3);

					return $self->_emit( 'BINARY_STRING', $val, $line, $col );
				}
				my $out = $self->_read_single_line_literal( "'", 'binary string', $line, $col );
				return $self->_emit( 'BINARY_STRING', $out, $line, $col );
			}
			if ( $ch eq '`' ) {
				if ( $self->_peek(3) eq '```' ) {
					$self->_adv(3);
					my $start = $self->pos;
					while ( !$self->_eof and $self->_peek(3) ne '```' ) {
						$self->_adv(1);
					}
					die "Unterminated template literal at line $line, col $col" if $self->_eof;
					my $src = substr( $self->src, $start, $self->pos - $start );
					$self->_adv(3);
					my $parts = $self->_split_interpolated_source( $src, $line, $col, 'template', 0 );

					return $self->_emit( 'TEMPLATE', $parts, $line, $col );
				}
				$self->_adv(1);
				my $start = $self->pos;
				while ( !$self->_eof ) {
					my $c = $self->_peek(1);
					last if $c eq '`';
					if ( $c eq "\\" ) {
						$self->_adv(1);
						die "Unterminated template literal at line $line, col $col" if $self->_eof;
					}
					$self->_adv(1);
				}
				die "Unterminated template literal at line $line, col $col" if $self->_eof;
				my $src = substr( $self->src, $start, $self->pos - $start );
				$self->_adv(1);
				my $parts = $self->_split_interpolated_source( $src, $line, $col, 'template', 1 );
				$self->_decode_interpolated_text_parts( $parts, 'template', $line, $col );

				return $self->_emit( 'TEMPLATE', $parts, $line, $col );
			}

		# identifiers/keywords (unicode)
		{
			my $rest = substr($self->src, $self->pos);
			if ($rest =~ /\A(?:([\p{XID_Start}][\p{XID_Continue}_]*)|(_[\p{XID_Continue}_]+))/u) {
				my $id = defined($1) ? $1 : $2;
				$self->_adv(length($id));
				$id = Zuzu::Util::nfc($id);
				if ($id eq 'true' || $id eq '⊤') { return $self->_emit('BOOL', 1, $line, $col); }
				if ($id eq 'false' || $id eq '⊥') { return $self->_emit('BOOL', 0, $line, $col); }
				if ($id eq 'null') { return $self->_emit('NULL', undef, $line, $col); }

				return $self->_emit('KW', $id, $line, $col) if Zuzu::Util::is_keyword($id);

				return $self->_emit('IDENT', $id, $line, $col);
			}
		}

		if ( $ch eq '∅' ) {
			$self->_adv(1);

			return $self->_emit('EMPTY_SET', '∅', $line, $col);
		}

		if ( $self->_peek(2) eq '^^' ) {
			$self->_adv(2);

			return $self->_emit('IDENT', '^^', $line, $col);
		}

		# operators / punct (try longest first)
		my @ops = (
			'<<<', '>>>',
			'{{', '}}',
			'<=>', '**', '==', '!=', '<=', '>=', ':=', '~=', '+=', '-=', '*=', '/=',
			'×=', '÷=', '**=', '_=', '?:=', '@@', '@?', '++', '--', '->', '→', '?:', '...',
			'|>', '<|',
			'⊂⊃',
			'<<', '>>', '«', '»',
			'{', '}', '(', ')', '[', ']', ',', ';', ':', '.', '?', '_', '@',
			'+', '-', '*', '/', '<', '>', '=', '!', '~', '&', '|', '^',
			'⌊', '⌋', '⌈', '⌉',
		);
		# plus unicode aliases you mentioned (not exhaustive)
		push @ops, qw( × ÷ ≠ ≤ ≥ ≡ ≢ ≶ ≷ ⋀ ⋁ ⊻ ⊼ ¬ ∈ ∉ ⋃ ⋂ ⊂ ⊃ ∖ \ ▷ ◁ );
		# sort by length desc for greedy match
		@ops = sort { length($b) <=> length($a) } @ops;

		for my $op (@ops) {
			if ($self->_peek(length($op)) eq $op) {
				$self->_adv(length($op));

				return $self->_emit('OP', $op, $line, $col);
			}
		}

		# single char fallback punct/op
		$self->_adv(1);

		return $self->_emit('OP', $ch, $line, $col);
	}

	return Zuzu::Token->new(type => 'EOF', value => undef, file => $self->filename, line => $self->line, col => $self->col);
}

=pod

=head1 NAME

Zuzu::Lexer - lexer that tokenizes ZuzuScript source text

=head1 DESCRIPTION

Scans normalized source text and emits C<Zuzu::Token> objects with source location metadata.

=head1 INHERITANCE

Inherits from C<Moo::Object>.

=head1 ROLES

None.

=head1 ATTRIBUTES

=head2 src

Type: B<Str>.

Unicode-normalized source text being lexed.

=head2 filename

Type: B<Maybe[Str]>.

Filename attached to generated tokens and parser errors.

=head2 pos

Type: B<Int>.

Current character offset in C<src>.

=head2 line

Type: B<Int>.

1-based source line number used for diagnostics.

=head2 col

Type: B<Int>.

1-based source column number used for diagnostics.

=head1 METHODS

=head2 new

Constructs and returns a new instance of this class.

=head2 next_token

Consumes input and returns the next C<Zuzu::Token>.

=head1 SEE ALSO

Subclasses: none in this distribution.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Lexer >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
