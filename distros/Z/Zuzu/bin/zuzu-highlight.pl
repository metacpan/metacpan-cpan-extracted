#!/usr/bin/env perl

use strict;
use utf8;
use warnings;
use FindBin qw( $Bin );
use lib "$Bin/../lib";

use Zuzu::Lexer;
use Zuzu::Parser;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $source = read_source(@ARGV);
my ( $body, $parsed, $parse_error ) = highlight($source);
print render_html( $body, $parsed, $parse_error );

sub read_source {
	my (@args) = @_;

	if ( @args > 1 ) {
		die "usage: $0 [file.zzs]\n";
	}

	if ( @args == 1 and $args[0] ne '-' ) {
		my $path = $args[0];
		open my $fh, '<:encoding(UTF-8)', $path
			or die "failed to read '$path': $!\n";
		local $/ = undef;

		return <$fh>;
	}

	binmode STDIN, ':encoding(UTF-8)';
	local $/ = undef;

	return <STDIN> // '';
}

sub highlight {
	my ($src) = @_;
	my @out;
	my @tokens = lex_tokens($src);
	my @line_offsets = line_offsets($src);
	my $cursor = 0;

	for my $idx ( 0 .. $#tokens ) {
		my $entry = $tokens[$idx];
		my $tok = $entry->{token};
		my $start = offset_for_token( \@line_offsets, $entry );
		if ( $start > $cursor ) {
			push @out, esc_html( substr( $src, $cursor, $start - $cursor ) );
		}

		my $lexeme = extract_lexeme( $src, $start, $tok );
		$lexeme = substr( $src, $start, 1 ) if $lexeme eq '';
		$cursor = $start + length($lexeme);

		my $class = class_for_token( $tok, \@tokens, $idx );
		if ( defined $class ) {
			push @out, span( $class, $lexeme );
		}
		else {
			push @out, esc_html($lexeme);
		}
	}

	push @out, esc_html( substr( $src, $cursor ) ) if $cursor < length($src);
	my ( $parsed, $parse_error ) = parse_check($src);

	return ( join( '', @out ), $parsed, $parse_error );
}

sub lex_tokens {
	my ($src) = @_;
	my $lexer = Zuzu::Lexer->new( src => $src, filename => '<highlight>' );
	my @tokens;

	while (1) {
		my $tok = $lexer->next_token;
		last if $tok->type eq 'EOF';
		push @tokens, {
			token => $tok,
			line => $tok->line,
			col  => $tok->col,
		};
	}

	return @tokens;
}

sub parse_check {
	my ($src) = @_;
	my $parser = Zuzu::Parser->new;
	my $ok = eval {
		$parser->parse( $src, '<highlight>' );
		1;
	};
	if ($ok) {
		return ( 1, '' );
	}
	else {
		my $err = $@;
		$err = "$err";
		$err =~ s/\s+\z//;

		( 0, $err );
	}
}

sub line_offsets {
	my ($src) = @_;
	my @offsets = ( 0 );
	my $pos = 0;

	while ( $src =~ /\n/g ) {
		$pos = pos($src);
		push @offsets, $pos;
	}

	return @offsets;
}

sub offset_for_token {
	my ( $line_offsets, $entry ) = @_;
	my $line_start = $line_offsets->[ $entry->{line} - 1 ] // 0;

	return $line_start + $entry->{col} - 1;
}

sub extract_lexeme {
	my ( $src, $start, $tok ) = @_;
	my $type = $tok->type // '';
	my $rest = substr( $src, $start );

	if ( $type eq 'KW' ) {
		return $tok->value // '';
	}
	if ( $type eq 'IDENT' ) {
		return $tok->value // '';
	}
	if ( $type eq 'BOOL' ) {
		return ( $rest =~ /\A(?:true|false|⊤|⊥)/u ) ? $& : '';
	}
	if ( $type eq 'NULL' ) {
		return ( $rest =~ /\Anull/u ) ? 'null' : '';
	}
	if ( $type eq 'NUMBER' ) {
		return ( $rest =~ /\A[0-9]+(?:\.[0-9]+)?/u ) ? $& : '';
	}
	if ( $type eq 'STRING' ) {
		return ( $rest =~ /\A"""(?s:(?:\\.|(?!""").))*"""|\A"(?:\\.|[^"\\])*"?/u ) ? $& : '';
	}
	if ( $type eq 'BINARY_STRING' ) {
		return ( $rest =~ /\A'''(?s:(?:\\.|(?!''').))*'''|\A'(?:\\.|[^'\\])*'?/u ) ? $& : '';
	}
	if ( $type eq 'TEMPLATE' ) {
		return ( $rest =~ /\A```(?s:(?:\\.|(?!```).))*```|\A`(?:\\.|[^`\\])*`/u ) ? $& : '';
	}
	if ( $type eq 'REGEXP' ) {
		return extract_regexp_lexeme($rest);
	}
	if ( $type eq 'EMPTY_SET' ) {
		return '∅';
	}
	if ( $type eq 'OP' ) {
		my $op = $tok->value // '';
		return $op if $op ne '' and index( $rest, $op ) == 0;
	}

	return '';
}

sub extract_regexp_lexeme {
	my ($rest) = @_;
	return '' if substr( $rest, 0, 1 ) ne '/';

	my $len = length($rest);
	my $pos = 1;
	my $escaped = 0;
	my $in_class = 0;

	while ( $pos < $len ) {
		my $c = substr( $rest, $pos, 1 );
		if ( !$escaped and !$in_class and $c eq '/' ) {
			$pos++;
			my $flags = '';
			while ( $pos < $len ) {
				my $flag = substr( $rest, $pos, 1 );
				last if $flag ne 'i' and $flag ne 'g';
				last if index( $flags, $flag ) >= 0;
				$flags .= $flag;
				$pos++;
			}

			return substr( $rest, 0, $pos );
		}
		if ( !$escaped and $c eq '[' ) {
			$in_class = 1;
		}
		elsif ( !$escaped and $c eq ']' ) {
			$in_class = 0;
		}
		$escaped = !$escaped && $c eq "\\" ? 1 : 0;
		$pos++;
	}

	return '';
}

sub class_for_token {
	my ( $tok, $tokens, $idx ) = @_;
	my $type = $tok->type // '';

	if ( $type eq 'KW' and ( $tok->value // '' ) eq 'default' ) {
		my $next = next_significant_token( $tokens, $idx );
		return 'keyword'
			if defined $next and $next->type eq 'OP' and ( $next->value // '' ) eq ':';

		return 'operator';
	}
	return 'keyword' if $type eq 'KW';
	return 'boolean' if $type eq 'BOOL';
	return 'null' if $type eq 'NULL';
	return 'number' if $type eq 'NUMBER';
	return 'string' if $type eq 'STRING' or $type eq 'BINARY_STRING' or $type eq 'TEMPLATE';
	return 'regexp' if $type eq 'REGEXP';
	return 'operator' if $type eq 'OP' or $type eq 'EMPTY_SET';
	if ( $type eq 'IDENT' ) {
		if ( $idx > 0 ) {
			my $prev = $tokens->[ $idx - 1 ]{token};
			if ( $prev->type eq 'KW' ) {
				my $kw = $prev->value // '';
				return 'ident-decl' if $kw =~ /\A(?:function|method|class|trait|catch)\z/u;
			}
		}

		return 'ident';
	}

	return undef;
}

sub next_significant_token {
	my ( $tokens, $idx ) = @_;

	for my $look ( $idx + 1 .. $#$tokens ) {
		my $tok = $tokens->[$look]{token};
		my $type = $tok->type // '';
		return $tok if $type ne 'COMMENT' and $type ne 'POD';
	}

	return undef;
}

sub span {
	my ( $class, $text ) = @_;

	return qq{<span class="$class">} . esc_html($text) . '</span>';
}

sub esc_html {
	my ($text) = @_;

	$text =~ s/&/&amp;/g;
	$text =~ s/</&lt;/g;
	$text =~ s/>/&gt;/g;

	return $text;
}

sub render_html {
	my ( $body, $parsed, $parse_error ) = @_;
	my $status_class = $parsed ? 'parse-ok' : 'parse-error';
	my $status_msg = $parsed ? 'Parse check: ok' : 'Parse check: failed';
	my $status_detail = $parsed ? '' : '<div class="parse-detail">' . esc_html($parse_error) . '</div>';
	my $head = <<'HTML';
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Zuzu Syntax Highlight</title>
<style>
:root {
	color-scheme: light dark;
	--bg: #F4F1E8;
	--surface: #F8F5EE;
	--border: #D6D0C4;
	--text: #2E2E2E;
	--comment: #7C7670;
	--keyword: #8A9EFF;
	--string: #B06E8A;
	--number: #A77755;
	--operator: #6C78C8;
	--ident: #2E2E2E;
	--boolean: #F2A7A7;
	--null: #D98989;
	--regexp: #7BA6B0;
}

@media (prefers-color-scheme: dark) {
	:root {
		--bg: #2E2E2E;
		--surface: #363636;
		--border: #4A4A4A;
		--text: #F4F1E8;
		--comment: #B9B2A5;
		--keyword: #8A9EFF;
		--string: #E0AFC4;
		--number: #D6B28E;
		--operator: #AAB6FF;
		--ident: #F4F1E8;
		--boolean: #F2A7A7;
		--null: #FFC0C0;
		--regexp: #9FC9D2;
	}
}

body {
	margin: 0;
	padding: 2rem;
	background: var(--bg);
	color: var(--text);
	font-family: Inter, ui-sans-serif, system-ui, -apple-system,
		"Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

pre.zuzu-code {
	margin: 0;
	padding: 1.25rem 1.5rem;
	background: var(--surface);
	border: 1px solid var(--border);
	border-radius: 10px;
	overflow-x: auto;
	line-height: 1.55;
	font-size: 0.95rem;
	font-family: "JetBrains Mono", "SFMono-Regular", Menlo,
		Consolas, "Liberation Mono", monospace;
}

.comment { color: var(--comment); font-style: italic; }
.keyword { color: var(--keyword); font-weight: 600; }
.string { color: var(--string); }
.number { color: var(--number); }
.operator { color: var(--operator); }
.ident { color: var(--ident); }
.boolean { color: var(--boolean); font-weight: 600; }
.null { color: var(--null); font-weight: 600; }
.regexp { color: var(--regexp); }
.ident-decl { color: var(--keyword); font-weight: 700; }
.parse-status { margin-bottom: 0.8rem; font-size: 0.85rem; }
.parse-ok { color: #4C7A5C; }
.parse-error { color: #B85050; }
.parse-detail { font-family: monospace; margin-top: 0.25rem; white-space: pre-wrap; }
</style>
</head>
<body>
HTML
	my $status = qq{<div class="parse-status $status_class">$status_msg$status_detail</div>\n};
	my $open_pre = <<'HTML';
<pre class="zuzu-code">
HTML
	my $tail = <<'HTML';
</pre>
</body>
</html>
HTML

	return $head . $status . $open_pre . $body . $tail;
}
