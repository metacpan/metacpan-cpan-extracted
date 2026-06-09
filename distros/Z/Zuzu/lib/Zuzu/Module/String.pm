package Zuzu::Module::String;

use utf8;

our $VERSION = '0.002000';

our %REGEXP_CACHE;
our %SPLIT_LITERAL_CACHE;

use Scalar::Util qw( blessed );
use Regexp::Util qw( deserialize_regexp );

use Zuzu::Error;
use Zuzu::Util::NativeHelpers qw(
	native_function
	perl_to_zuzu
	zuzu_to_perl
	zuzu_bool
);
use Zuzu::Value::Boolean;
use Zuzu::Value::Regexp;
use Zuzu::Value::BinaryString;

sub _str {
	my ( $value, $default, $label ) = @_;

	return $default if not defined $value;
	if ( blessed($value) and $value->isa('Zuzu::Value::BinaryString') ) {
		$label //= 'std/string function';
		die Zuzu::Error->new_runtime(
			message => "TypeException: $label expects String, got BinaryString",
			file => '<std/string>',
			line => 0,
		);
	}
	return "$value";
}

sub _num {
	my ( $value, $default ) = @_;

	return $default if not defined $value;
	return 0 + $value;
}

sub _int {
	my ( $value, $default, $label ) = @_;

	my $num = _num( $value, $default );
	die Zuzu::Error->new_runtime(
		message => "$label expects an integer",
		file => '<std/string>',
		line => 0,
	) if $num != int($num);
	return int($num);
}

sub _validate_codepoint {
	my ( $codepoint, $label ) = @_;

	die Zuzu::Error->new_runtime(
		message => "$label expects a Unicode code point in 0..0x10FFFF",
		file => '<std/string>',
		line => 0,
	) if $codepoint < 0 or $codepoint > 0x10FFFF;
	die Zuzu::Error->new_runtime(
		message => "$label rejects surrogate code points",
		file => '<std/string>',
		line => 0,
	) if $codepoint >= 0xD800 and $codepoint <= 0xDFFF;
	return $codepoint;
}

sub _regexp_from {
	my ( $pattern, $flags ) = @_;

	my $want_i = 0;
	my $want_g = 0;
	my $pat = '';

	if ( blessed($pattern) and $pattern->isa('Zuzu::Value::Regexp') ) {
		$pat = defined $pattern->pattern ? $pattern->pattern : '';
		my $lit_flags = defined $pattern->flags ? $pattern->flags : '';
		$want_i = 1 if $lit_flags =~ /i/;
	}
	elsif ( ref($pattern) eq 'Regexp' ) {
		my $f = defined $flags ? "$flags" : '';
		$want_g = 1 if $f =~ /g/;
		return ( $pattern, $want_g );
	}
	else {
		$pat = _str( $pattern, '' );
	}

	my $extra = defined $flags ? "$flags" : '';
	$want_i = 1 if $extra =~ /i/;
	$want_g = 1 if $extra =~ /g/;

	my $mods = '';
	$mods = '(?i)' if $want_i;
	my $cache_key = join "\x1f", $mods, $pat;
	my $regex = $REGEXP_CACHE{$cache_key};
	if ( not defined $regex ) {
		$regex = eval { qr/$mods$pat/ };
		die "invalid regexp pattern: $@" if not defined $regex;
		$REGEXP_CACHE{$cache_key} = $regex;
	}

	return ( $regex, $want_g );
}

sub _pattern_to_regexp {
	my ( $pattern, $case_insensitive ) = @_;

	my $pat = _str( $pattern, '' );
	my $flags = zuzu_bool( $case_insensitive, 0 ) ? 'i' : '';

	for my $candidate ( qw( / | : " ' ), '#' ) {
		next if CORE::index( $pat, $candidate ) >= 0;
		my $literal = sprintf( 'qr%s%s%s%s', $candidate, $pat, $candidate, $flags );
		my $regex = deserialize_regexp($literal);
		die "invalid regexp pattern" if not defined $regex;
		return Zuzu::Value::Regexp->new(
			pattern => $pat,
			flags => $flags,
		);
	}

	my $escaped = $pat;
	$escaped =~ s{/}{\\/}g;
	my $literal = sprintf( 'qr/%s/%s', $escaped, $flags );
	my $regex = deserialize_regexp($literal);
	die "invalid regexp pattern" if not defined $regex;
	return Zuzu::Value::Regexp->new(
		pattern => $pat,
		flags => $flags,
	);
}

sub _quotemeta {
	my ( $text ) = @_;

	my $value = _str( $text, '', 'quotemeta()' );
	$value =~ s{([\\/\^\$\.\|\?\*\+\(\)\[\]\{\}"'])}{\\$1}g;

	return $value;
}

sub _split_text {
	my ( $text, $separator, $limit ) = @_;

	my $value = _str( $text, '' );
	my @parts;

	if ( defined $separator and blessed($separator) and $separator->isa('Zuzu::Value::Regexp') ) {
		my ( $regex ) = _regexp_from( $separator, '' );
		@parts = defined $limit
			? CORE::split( /$regex/, $value, _num( $limit, 0 ) )
			: CORE::split( /$regex/, $value );
	}
	elsif ( ref($separator) eq 'Regexp' ) {
		@parts = defined $limit
			? CORE::split( /$separator/, $value, _num( $limit, 0 ) )
			: CORE::split( /$separator/, $value );
	}
	else {
		my $sep = _str( $separator, '' );
		my $regex = $SPLIT_LITERAL_CACHE{$sep};
		if ( not defined $regex ) {
			my $quoted = quotemeta($sep);
			$regex = qr/$quoted/;
			$SPLIT_LITERAL_CACHE{$sep} = $regex;
		}
		@parts = defined $limit
			? CORE::split( /$regex/, $value, _num( $limit, 0 ) )
			: CORE::split( /$regex/, $value );
	}

	return \@parts;
}

sub _word_segments {
	my ( $text ) = @_;

	my $value = _str( $text, '' );
	$value =~ s/([a-z0-9])([A-Z])/$1 $2/g;
	$value =~ s/[^A-Za-z0-9]+/ /g;
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

	return () if $value eq '';
	return grep { $_ ne '' } split /\s+/, $value;
}

sub _trim {
	my ( $text ) = @_;

	my $value = _str( $text, '' );
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;
	return $value;
}

sub _pad {
	my ( $text, $width, $pad_char, $side ) = @_;

	my $value = _str( $text, '' );
	my $want_width = _num( $width, 0 );
	my $fill = _str( $pad_char, ' ' );
	$fill = ' ' if $fill eq '';
	my $direction = _str( $side, 'right' );

	my $need = $want_width - length($value);
	return $value if $need <= 0;
	my $extra = $fill x $need;

	if ( $direction eq 'left' ) {
		return $extra . $value;
	}

	return $value . $extra;
}

sub _camel {
	my ( $text ) = @_;

	my @parts = _word_segments( $text );
	return '' if scalar @parts == 0;

	my $head = lc shift @parts;
	my @tail = map {
		my $piece = lc $_;
		substr( $piece, 0, 1 ) = uc substr( $piece, 0, 1 );
		$piece;
	} @parts;

	return $head . join( '', @tail );
}

sub _title {
	my ( $text ) = @_;

	my @parts = _word_segments( $text );
	my @words = map {
		my $piece = lc $_;
		substr( $piece, 0, 1 ) = uc substr( $piece, 0, 1 );
		$piece;
	} @parts;

	return join ' ', @words;
}

sub _snake {
	my ( $text ) = @_;

	my @parts = _word_segments( $text );
	return join '_', map { lc $_ } @parts;
}

sub _kebab {
	my ( $text ) = @_;

	my @parts = _word_segments( $text );
	return join '-', map { lc $_ } @parts;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $substr_fn = native_function(
		name => 'substr',
		native => sub {
			my ( @args ) = @_;
			my $text = _str( $args[0], '' );
			my $start = _num( $args[1], 0 );
			if ( scalar @args >= 3 and defined $args[2] ) {
				my $len = _num( $args[2], 0 );
				return CORE::substr( $text, $start, $len );
			}
			return CORE::substr( $text, $start );
		},
	);

	my $index_fn = native_function(
		name => 'index',
		native => sub {
			my ( @args ) = @_;
			my $text = _str( $args[0], '' );
			my $needle = _str( $args[1], '' );
			my $start = scalar @args >= 3 ? _num( $args[2], 0 ) : 0;
			return CORE::index( $text, $needle, $start );
		},
	);

	my $rindex_fn = native_function(
		name => 'rindex',
		native => sub {
			my ( @args ) = @_;
			my $text = _str( $args[0], '' );
			my $needle = _str( $args[1], '' );
			if ( scalar @args >= 3 and defined $args[2] ) {
				my $start = _num( $args[2], 0 );
				return CORE::rindex( $text, $needle, $start );
			}
			return CORE::rindex( $text, $needle );
		},
	);

	my $contains_fn = native_function(
		name => 'contains',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'contains() expects two arguments',
				file => '<std/string>',
				line => 0,
			) if scalar @args != 2;
			my $text = _str( $args[0], '' );
			my $needle = _str( $args[1], '' );
			return Zuzu::Value::Boolean->new(
				value => CORE::index( $text, $needle ) >= 0 ? 1 : 0,
			);
		},
	);

	my $starts_with_fn = native_function(
		name => 'starts_with',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'starts_with() expects two arguments',
				file => '<std/string>',
				line => 0,
			) if scalar @args != 2;
			my $text = _str( $args[0], '' );
			my $prefix = _str( $args[1], '' );
			return Zuzu::Value::Boolean->new(
				value => CORE::index( $text, $prefix ) == 0 ? 1 : 0,
			);
		},
	);

	my $ends_with_fn = native_function(
		name => 'ends_with',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'ends_with() expects two arguments',
				file => '<std/string>',
				line => 0,
			) if scalar @args != 2;
			my $text = _str( $args[0], '' );
			my $suffix = _str( $args[1], '' );
			return Zuzu::Value::Boolean->new(
				value => $suffix eq ''
					|| CORE::substr( $text, -length($suffix) ) eq $suffix
					? 1
					: 0,
			);
		},
	);

	my $chr_fn = native_function(
		name => 'chr',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'chr() expects one argument',
				file => '<std/string>',
				line => 0,
			) if scalar @args != 1;
			my $codepoint = _validate_codepoint(
				_int( $args[0], 0, 'chr()' ),
				'chr()',
			);
			return chr($codepoint);
		},
	);

	my $ord_fn = native_function(
		name => 'ord',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'ord() expects one or two arguments',
				file => '<std/string>',
				line => 0,
			) if scalar @args < 1 or scalar @args > 2;
			my $text = _str( $args[0], '', 'ord()' );
			my $index = _int(
				scalar @args >= 2 ? $args[1] : 0,
				0,
				'ord()',
			);
			my $length = length($text);
			die Zuzu::Error->new_runtime(
				message => 'ord() index out of range',
				file => '<std/string>',
				line => 0,
			) if $index < 0 or $index >= $length;
			return ord( CORE::substr( $text, $index, 1 ) );
		},
	);

	my $replace_fn = native_function(
		name => 'replace',
		native => sub {
			my ( @args ) = @_;
			my $text = _str( $args[0], '' );
			my $replacement = _str( $args[2], '' );
			my ( $regex, $global ) = _regexp_from( $args[1], $args[3] );
			if ( $global ) {
				$text =~ s/$regex/$replacement/g;
			}
			else {
				$text =~ s/$regex/$replacement/;
			}
			return $text;
		},
	);

	my $search_fn = native_function(
		name => 'search',
		native => sub {
			my ( @args ) = @_;
			my $text = _str( $args[0], '' );
			my ( $regex ) = _regexp_from( $args[1], $args[2] );
			return $1 if $text =~ /($regex)/;
			return undef;
		},
	);

	my $matches_fn = native_function(
		name => 'matches',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'matches() expects two or three arguments',
				file => '<std/string>',
				line => 0,
			) if scalar @args < 2 or scalar @args > 3;
			my $text = _str( $args[0], '' );
			my ( $regex ) = _regexp_from( $args[1], $args[2] );
			return Zuzu::Value::Boolean->new(
				value => $text =~ /$regex/ ? 1 : 0,
			);
		},
	);

	my $pattern_to_regexp_fn = native_function(
		name => 'pattern_to_regexp',
		native => sub {
			my ( @args ) = @_;
			return _pattern_to_regexp( $args[0], $args[1] );
		},
	);

	my $quotemeta_fn = native_function(
		name => 'quotemeta',
		native => sub {
			my ( @args ) = @_;
			die Zuzu::Error->new_runtime(
				message => 'quotemeta() expects one argument',
				file => '<std/string>',
				line => 0,
			) if scalar @args != 1;
			return _quotemeta( $args[0] );
		},
	);

	my $sprint_fn = native_function(
		name => 'sprint',
		native => sub {
			my ( @args ) = @_;
			my $fmt = _str( $args[0], '' );
			my @vals = map { defined $_ ? $_ : '' } @args[ 1 .. $#args ];
			return sprintf( $fmt, @vals );
		},
	);

	my $split_fn = native_function(
		name => 'split',
		native => sub {
			my ( @args ) = @_;
			return perl_to_zuzu(
				_split_text(
					$args[0],
					$args[1],
					scalar @args >= 3 ? $args[2] : undef,
				)
			);
		},
	);

	my $join_fn = native_function(
		name => 'join',
		native => sub {
			my ( @args ) = @_;
			my $sep = _str( $args[0], '' );
			my $items = zuzu_to_perl( $args[1] );
			my @parts = ref($items) eq 'ARRAY' ? @$items : ();
			return join $sep, map { defined $_ ? "$_" : '' } @parts;
		},
	);

	my $trim_fn = native_function(
		name => 'trim',
		native => sub {
			my ( @args ) = @_;
			return _trim( $args[0] );
		},
	);

	my $pad_fn = native_function(
		name => 'pad',
		native => sub {
			my ( @args ) = @_;
			return _pad(
				$args[0],
				$args[1],
				scalar @args >= 3 ? $args[2] : undef,
				scalar @args >= 4 ? $args[3] : undef,
			);
		},
	);

	my $chomp_fn = native_function(
		name => 'chomp',
		native => sub {
			my ( @args ) = @_;
			my $value = _str( $args[0], '' );
			$value =~ s/(?:\r\n|\n|\r)\z//;
			return $value;
		},
	);

	my $title_fn = native_function(
		name => 'title',
		native => sub {
			my ( @args ) = @_;
			return _title( $args[0] );
		},
	);

	my $snake_fn = native_function(
		name => 'snake',
		native => sub {
			my ( @args ) = @_;
			return _snake( $args[0] );
		},
	);

	my $kebab_fn = native_function(
		name => 'kebab',
		native => sub {
			my ( @args ) = @_;
			return _kebab( $args[0] );
		},
	);

	my $camel_fn = native_function(
		name => 'camel',
		native => sub {
			my ( @args ) = @_;
			return _camel( $args[0] );
		},
	);

	return {
		substr => $substr_fn,
		index => $index_fn,
		rindex => $rindex_fn,
		contains => $contains_fn,
		starts_with => $starts_with_fn,
		ends_with => $ends_with_fn,
		chr => $chr_fn,
		ord => $ord_fn,
		replace => $replace_fn,
		search => $search_fn,
		matches => $matches_fn,
		pattern_to_regexp => $pattern_to_regexp_fn,
		quotemeta => $quotemeta_fn,
		sprint => $sprint_fn,
		split => $split_fn,
		join => $join_fn,
		trim => $trim_fn,
		pad => $pad_fn,
		chomp => $chomp_fn,
		title => $title_fn,
		snake => $snake_fn,
		kebab => $kebab_fn,
		camel => $camel_fn,
	};
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::String >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
