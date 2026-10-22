package oEdtk::LaTeX;

# LaTeX helpers, ported from the fork's oEdtk::LaTeX at S23
# (docs/integration/PLAN.md). The module is generic: it only
# depends on oEdtk::Utils for the index format, and on the latin-9 character
# table. The fork exported three names it never defined (demo_write,
# demo_expected_write, unfold_list); they are restored here so the exported API
# is truthful. They are diagnostic helpers, unused by the production path.

use base qw( Exporter );
use warnings;
use strict;
use Carp qw( carp croak );
use Readonly;
use Data::Dumper qw( Dumper );
use Encode       qw( encode );
use Roman        qw( roman );
use oEdtk::Utils qw( IDX_FORMAT );
use charnames ':full';

our $VERSION = 2.1131;

our @EXPORT_OK =
	qw( tag tag_args ged_tag make_index demo demo_write demo_expected_write latex_escape_string translate_unit concat_string latex_boolean unfold_list
	);

Readonly my $LATIN9_ENCODING => 'iso-8859-15';
Readonly my $OUTPUT_ENCODING => $LATIN9_ENCODING;
Readonly my $LIST_SEPARATOR =>
	"\N{LATIN CAPITAL LETTER S WITH CARON}";    # 0xa6 in latin-9 (U+00A6 is BROKEN BAR)
Readonly my $LINE_BREAK        => '\\\\';
Readonly my $ADDRESS_SEPARATOR => '~\edGreenBullet~';

Readonly my $UNKNOWN_CHARACTER => '\textcolor{red}{(\#)}';
Readonly my $DEMO_FILE         => '/tmp/demo_chars.tex';

Readonly my $INDEX_FORMAT => oEdtk::Utils::IDX_FORMAT();

Readonly my $WRITE_UNKNOWN_CHAR  => '?';
Readonly my $DEMO_WRITE_FILE     => '/tmp/demo_write.tex';
Readonly my $EXPECTED_WRITE_FILE => '/tmp/expected_write.txt';

Readonly my $VERBOSE => exists $ENV{'VERBOSE'} && $ENV{'VERBOSE'};

Readonly my $GED_TAG_XSOURCE          => 'xSOURCE';
Readonly my $GED_VALUE_PRECONTENTIEUX => 'PREC';

Readonly my $CSV_SEPARATOR => q{;};    # hardcoded in edtkdoc.cls

Readonly my @ORDS => sort { $a <=> $b }
	( 0 .. 255, 0x20ac, 0x160, 0x161, 0x17d, 0x17e, 0x152, 0x153, 0x178 )
	;                                  # character #'s to know about
my $CHARACTER_CACHE = { map { $_ => compute_character_cache($_) } @ORDS };

sub ged_tag_xSOURCE {
	return $GED_TAG_XSOURCE;
}

sub ged_value_precontentieux {
	return $GED_VALUE_PRECONTENTIEUX;
}

sub encode_error {
	my ($ord) = @_;
	carp sprintf(
		"Character <U+%04x> ('%s') does not map to %s",
		$ord, charnames::viacode($ord),
		$OUTPUT_ENCODING
	) if $VERBOSE;
	return $UNKNOWN_CHARACTER;
}

sub unknown_character {
	my ($str) = @_;
	die "Bad str '$str'" if $str =~ m{[^a-z0-9]}six;    # avoid deep recursion
	return '\textcolor{red}{(' . $str . ')}';
}

sub compute_character_cache_ascii {
	my ($ord) = @_;
	return '\#'                 if $ord == 0x23;
	return '\$'                 if $ord == 0x24;
	return '\%'                 if $ord == 0x25;
	return '\&'                 if $ord == 0x26;
	return '\_'                 if $ord == 0x5f;
	return '\textbackslash{}'   if $ord == 0x5c;        # U+005C REVERSE SOLIDUS
	return '\textasciicircum{}' if $ord == 0x5e;        # U+005E CIRCUMFLEX ACCENT
	return '\{'                 if $ord == 0x7b;        # '\\textbraceleft{}'
	return '\}'                 if $ord == 0x7d;        # '\\textbraceright{}'
	return '\textasciitilde{}'  if $ord == 0x7e;        # U+007E TILDE
	return chr($ord);
}

# should be useless since the switch to lualatex (see PHX-COUR)
sub compute_character_cache_8bit {
	my ($ord) = @_;
	return '{$\neg$}'   if $ord == 0xac;                             # U+00AC NOT SIGN
	return '{$\pm$}'    if $ord == 0xb1;                             # U+00B1 PLUS-MINUS SIGN
	return '{$^2$}'     if $ord == 0xb2;                             # U+00B2 SUPERSCRIPT TWO
	return '{$^3$}'     if $ord == 0xb3;                             # U+00B3 SUPERSCRIPT THREE
	return '{$\mu$}'    if $ord == 0xb5;                             # U+00B5 MICRO SIGN
	return '{$^1$}'     if $ord == 0xb9;                             # U+00B9 SUPERSCRIPT ONE
	return '{$\times$}' if $ord == 0xd7;                             # U+00D7 MULTIPLICATION SIGN
	return '\textdiv{}' if $ord == 0xf7;                             # U+00F7 DIVISION SIGN
	return encode( $OUTPUT_ENCODING, chr($ord), \&encode_error );    # not latin => 8 exceptions
}

sub compute_character_cache_extra {
	my ($ord) = @_;
	return chr($ord) if $ord == 0x152;    # U+0152 LATIN CAPITAL LIGATURE OE
	return chr($ord) if $ord == 0x153;    # U+0153 LATIN SMALL LIGATURE OE
	return chr($ord)
		if $ord == 0x160;                 # U+0160 LATIN CAPITAL LETTER S WITH CARON
	return chr($ord) if $ord == 0x161;    # U+0161 LATIN SMALL LETTER S WITH CARON
	return chr($ord)
		if $ord == 0x178;                 # U+0178 LATIN CAPITAL LETTER Y WITH DIAERESIS
	return chr($ord)
		if $ord == 0x17d;                 # U+017D LATIN CAPITAL LETTER Z WITH CARON
	return chr($ord) if $ord == 0x17e;    # U+017E LATIN SMALL LETTER Z WITH CARON
	return chr($ord)
		if $ord == 0x20ac;   # U+20AC EURO SIGN -- NB violates the standard, unlike eurosym's \EUR{}
	carp Dumper( sprintf( "Unknown character 0x%02x ('%s')", $ord, chr($ord) ) )
		if $VERBOSE;
	return $UNKNOWN_CHARACTER;
}

sub compute_character_cache {
	my ($ord) = @_;
	croak "Unimplemented output encoding '$OUTPUT_ENCODING'"
		if $OUTPUT_ENCODING ne $LATIN9_ENCODING;
	if ( $ord < 0x20 ) {     # control character
		return "$LINE_BREAK\n"
			if $ord == 0x0a
			;   # \n --; \n avoids '\\"{}' which makes indexation fail # might fail if line is empty
		return '' if $ord == 0x0d;    # \r
		carp sprintf "Found character 0x%02x ('%s')", $ord, charnames::viacode($ord)
			if $VERBOSE;
		return unknown_character( sprintf( "%02x", $ord ) );
	}
	elsif ( $ord < 0x7f ) { return compute_character_cache_ascii($ord); }
	elsif ( $ord <= 0x9f ) {          # windows-1252? bugware this?
		carp sprintf "Found character 0x%02x ('%s')", $ord, charnames::viacode($ord)
			if $VERBOSE;
		return unknown_character( sprintf( "%02x", $ord ) );
	}
	elsif ( $ord <= 0xff ) { return compute_character_cache_8bit($ord); }
	else                   { return compute_character_cache_extra($ord); }
}

sub latex_escape_character {
	my ($ord) = @_;
	return exists $CHARACTER_CACHE->{$ord}
		? $CHARACTER_CACHE->{$ord}
		: compute_character_cache($ord);
}

sub latex_boolean {
	my ($bool) = @_;
	return $bool ? "true" : "false";
}

sub translate_unit {
	my ($str) = @_;
	die "str undef" unless defined $str;
	if    ( $str eq '' ) { return ''; }
	elsif ( $str eq 'EUR' ) {
		return latex_narrow_space() . tag_args('EUR');
	}    # eurosym EURO symbol
	elsif ( $str eq '%' ) {
		return latex_narrow_space() . latex_escape_string('%');
	}
	else { croak "Unknown unit '$str'"; }
}

sub latex_escape_string {
	my ($str) = @_;
	return join( "", map { latex_escape_character( ord($_) ) } split( m//, $str ) );
}

sub latex_escape_string_no_byte_a6 {
	my ($str) = @_;
	croak "OUTPUT_ENCODING unexpected: $OUTPUT_ENCODING"
		if $OUTPUT_ENCODING ne $LATIN9_ENCODING;
	if ( $str =~ m/\N{LATIN CAPITAL LETTER S WITH CARON}/sox ) {
		carp "Replace capital letter S's with caron in '$str' with capital S's...";
		$str =~ s/\N{LATIN CAPITAL LETTER S WITH CARON}/S/gsox;
	}
	return latex_escape_string($str);
}

sub latex_escape_list_no_byte_a6 {
	my (@l) = @_;
	return map { ( $_ =~ m{\S}sx ) ? latex_escape_string_no_byte_a6($_) : () } @l;
}

sub latex_list {
	my ($l) = @_;
	my @res = latex_escape_list_no_byte_a6( @{$l} );
	return join( $LIST_SEPARATOR, @res );
}

# cannot use colors with \StrSubstitute replacements... (TeX capacity exceeded)
# used for addresses in the bottom of pages (green separators)
sub special_colored_address {
	my ($val) = @_;
	if ( ref $val eq 'HASH' ) {
		my $nKeys = scalar keys %{$val};
		if (   ( $nKeys == 1 )
			&& ( exists $val->{'address'} )
			&& ( ( ref( $val->{'address'} ) eq 'ARRAY' ) ) )
		{
			my @res   = ();
			my @val   = @{ $val->{'address'} };
			my $first = shift @val;
			push @res, '\textbf{', latex_escape_string_no_byte_a6($first), '}' . $LINE_BREAK
				if $first =~ m{\S}sox;
			push @res, join( $ADDRESS_SEPARATOR, latex_escape_list_no_byte_a6(@val) );
			push @res, $LINE_BREAK if scalar @val;
			push @res, '{\TelIndigoWebsite}';
			return join( '', @res );
		}
	}
	croak 'Not implemented: ' . Dumper($val);
}

# kludges when we need Perl to compute complicated LaTeX
sub special_treatment {
	my ($h)   = @_;
	my @keys  = keys %{$h};
	my $nKeys = scalar @keys;
	if ( $nKeys == 1 ) {
		my $key = $keys[0];
		return special_colored_address( $h->{$key} ) if $key eq 'colored_address';
	}
	croak 'Not implemented: ' . Dumper($h);
}

sub latex_xkeyval_value {
	my ($obj) = @_;
	my $ref = ref $obj;
	if ( $ref eq "" ) {    # should we care about embedded newlines?
		$obj = latex_escape_string($obj);
	}
	elsif ( $ref eq "ARRAY" ) {
		$obj = latex_list($obj);
	}
	elsif ( $ref eq "HASH" ) {
		$obj = special_treatment($obj);
	}
	else {
		croak "Should not happen/not implemented. Bad object ref: " . Dumper($obj);
	}
	return ( $obj =~ m{[=,\{\}]}sx ) ? "{$obj}" : $obj;
}

# define a list the oEdtk way
sub latex_define_list {
	my ( $tag, $l ) = @_;
	return ( "\\edListNew{$tag}", map { "\\edListAdd{$tag}{$_}" } @{$l} );
}

sub remove_roman_numbering {
	my ($h) = @_;
	foreach my $key ( sort keys %{$h} ) {
		my $ref = ref $h->{$key};
		if ( substr( $key, -6 ) eq "#roman" ) {
			croak "Unexpected value for key '$key': " . Dumper($h)
				unless $ref eq "ARRAY";
			my $counter = 0;
			my $baseKey = substr( $key, 0, -6 );
			foreach my $val ( @{ $h->{$key} } ) {
				$counter++;
				my $romanKey = $baseKey . roman($counter);
				croak "Bad tag '$romanKey'" unless is_valid_tag($romanKey);
				$h->{$romanKey} = $val;
			}
			delete $h->{$key};
		}
		else {
			croak "Bad tag '$key'" unless is_valid_tag($key);
		}
	}
	return $h;
}

# needed to circumvent edtkdoc.cls bug (poor man's CSV)
# (whitespace and u+FFFD are already taken care of in string_to_latex,
# but just in case)
sub skip_csv {
	my ($c) = @_;
	return
		   ( $c eq $CSV_SEPARATOR )
		|| ( $c eq q{'} )
		|| ( $c eq q{"} )
		|| ( $c eq "\n" )
		|| ( $c eq "\r" )
		|| ( $c eq "\t" )
		|| ( $c eq "\x{fffd}" );    # U+FFFD REPLACEMENT CHARACTER
}

sub sanitize_csv {
	my ($str) = @_;
	return join q{}, map { skip_csv($_) ? q{ } : $_ } split m//, $str;
}

sub index_value {
	my ( $h, $tag ) = @_;
	my $ref = ref $h->{$tag};
	return ( $ref eq '' )
		? "\\long\\gdef\\$tag" . "{" . latex_escape_string( sanitize_csv( $h->{$tag} ) ) . "}%"
		: ( $ref eq 'ARRAY' ) ? latex_define_list( $tag, $h->{$tag} )
		:                       croak "Unexpected value for key '$tag': " . Dumper($h);
}

sub make_index {
	my ( $h, %extra ) = @_;
	my $rrn   = remove_roman_numbering($h);                          # avoid side effects
	my @res   = map { index_value( $rrn, $_ ) } sort keys %{$rrn};
	my $extra = remove_roman_numbering( \%extra );
	push @res, map { index_value( $extra, $_ ) } sort keys %{$extra};
	return join( "\n", @res, '' );
}

sub check_index_is_complete {
	my ($h) = @_;
	my @errors = ();
	foreach my $s ( @{$INDEX_FORMAT} ) {
		my ( $orig, $new, $offset ) = @{$s};
		next unless length $new;
		if ( !exists $h->{$new} ) {
			push @errors, "Missing field '$new' (was '\\$orig' in the previous index system)";
		}
		else {
			if ( defined $offset ) {
				push @errors,
					"Field '$new' not a list (was '\\$orig' in the previous index system)"
					unless ref( $h->{$new} ) eq 'ARRAY';
			}
		}
	}
	croak join( "\n", @errors, '' ) if scalar @errors;
	return;
}

sub max {
	my (@l) = @_;
	my $res = 0;
	foreach my $val (@l) {
		$res = $val if $val > $res;
	}
	return $res;
}

sub pad_left {
	my ( $str, $len ) = @_;
	return ( " " x ( $len - length($str) ) ) . $str;
}

sub is_valid_tag {
	my ($tag) = @_;
	return $tag =~ m{^[a-z]+$}six;
}

sub ged_tag {
	my ( $tag, $value ) = @_;
	return ["Bad tag '$tag'"] unless is_valid_tag($tag);
	return "\\gdef\\$tag" . '{' . latex_escape_string($value) . '}%';
}

# output value: a list of one error, or the string wanted
sub tag {
	my ( $tag, $h ) = @_;
	return ["Bad tag '$tag'"] unless is_valid_tag($tag);
	return "\\$tag" if !defined $h;
	return ["Defined but empty hash for tag '$tag'"] unless scalar keys %{$h};
	my @l   = ();
	my $pad = 1 + max( map { length $_ } keys %{$h} );
	foreach my $key ( sort keys %{$h} ) {
		return [ "key '$key' undef: " . Dumper($h) ] unless defined $h->{$key};
		push @l, join( " = ", pad_left( $key, $pad ), latex_xkeyval_value( $h->{$key} ) );
	}
	return "\\$tag\[\n\x20" . join( "\n,", @l ) . "\n]%";
}

sub latex_narrow_space {
	return "\\,";
}

sub concat_string {
	my (@l) = @_;
	return join( '', map { interpret_argument($_) } @l );
}

sub interpret_argument {
	my ($arg) = @_;
	my $ref = ref $arg;
	if    ( $ref eq '' )      { return latex_escape_string($arg); }
	elsif ( $ref eq 'ARRAY' ) { my ( $sub, @l ) = @{$arg}; return &{$sub}(@l); }
	else                      { croak "Unexpected ref $ref for arg: " . Dumper($arg); }
}

sub tag_args {
	my ( $tag, @args ) = @_;
	die "Bad tag '$tag'" unless is_valid_tag($tag);
	@args = ('')         unless scalar @args;         # at least {} after the tag name
	return join( '', "\\$tag", map { '{' . interpret_argument($_) . '}' } @args );
}

sub demo {
	my @l =
		map { [ $_, $_, $CHARACTER_CACHE->{$_}, charnames::viacode($_) ] } @ORDS;
	my $preamble = <<'EOPREAMBLE';
\documentclass{article}
\usepackage[T1]{fontenc}
\usepackage[latin9]{inputenc}
\usepackage{color,textcomp,longtable}
\begin{document}
EOPREAMBLE
	my $postamble = <<'EOPOSTAMBLE';
\end{document}
EOPOSTAMBLE
	my $body = join(
		"\n",
		'\begin{longtable}{llcl}',
		'\hline',
		"\\textbf{Dec} & \\textbf{Hex} & \\textbf{Char} & \\textbf{Name}" . $LINE_BREAK,
		'\hline', '\hline',
		'\endhead',
		'\endfoot',
		(
			map {
				sprintf "%d & %02x & %s & %s$LINE_BREAK%s", @{$_}, ( $$_[0] % 2 )
					? "\n\\hline"
					: ''
			} @l
		),
		'\end{longtable}',
		''
	);
	open my $out, ">encoding($OUTPUT_ENCODING)", $DEMO_FILE || croak $!;
	print $out join( '', $preamble, $body, $postamble );
	close $out || croak $!;
	carp "demo saved to '$DEMO_FILE'";
	return 0;
}

# The fork listed these three names in @EXPORT_OK without defining them: an
# import succeeded but a call died ("Undefined subroutine"). They are restored
# here so the exported API is truthful and T33 holds. All three are diagnostic
# helpers; no production path calls them.

# The "written" companion of demo(): same character table written to
# $DEMO_WRITE_FILE, with unmapped characters rendered as $WRITE_UNKNOWN_CHAR.
sub demo_write {
	my $body = join(
		"\n",
		(
			map {
				sprintf "%d & %02x & %s & %s", $_, $_,
					( $CHARACTER_CACHE->{$_} eq $UNKNOWN_CHARACTER )
					? $WRITE_UNKNOWN_CHAR
					: $CHARACTER_CACHE->{$_},
					charnames::viacode($_);
			} @ORDS
		),
		''
	);
	open my $out, ">encoding($OUTPUT_ENCODING)", $DEMO_WRITE_FILE || croak $!;
	print $out $body;
	close $out || croak $!;
	carp "demo_write saved to '$DEMO_WRITE_FILE'";
	return 0;
}

# The expected character table, written to $EXPECTED_WRITE_FILE, for a human to
# diff against demo_write().
sub demo_expected_write {
	my $body = join( "\n", ( map { sprintf "%02x %s", $_, $CHARACTER_CACHE->{$_} } @ORDS ), '' );
	open my $out, ">encoding($OUTPUT_ENCODING)", $EXPECTED_WRITE_FILE || croak $!;
	print $out $body;
	close $out || croak $!;
	carp "demo_expected_write saved to '$EXPECTED_WRITE_FILE'";
	return 0;
}

# Unfold a list one level: an arrayref element is replaced by its items.
sub unfold_list {
	my (@l) = @_;
	return map { ref $_ eq 'ARRAY' ? @{$_} : $_ } @l;
}

1;

=head1 NAME

oEdtk::LaTeX - build the LaTeX index of an edtk document

=head1 SYNOPSIS

    use oEdtk::LaTeX qw(make_index latex_escape_string tag_args);

    my $index = make_index( \%index_variables );
    my $s     = latex_escape_string($utf8_string);

=head1 DESCRIPTION

Helpers used by an edtk application to turn Perl data into LaTeX: escape a
string to the latin-9 output encoding (C<latex_escape_string>), build the
index definitions (C<make_index>, C<ged_tag>, C<tag>, C<tag_args>,
C<concat_string>, C<latex_boolean>), translate a unit (C<translate_unit>), and
dump the character table for debugging (C<demo>, C<demo_write>,
C<demo_expected_write>, C<unfold_list>).

Ported from the fork's C<oEdtk::LaTeX> at S23. The latin-9 character table
(C<@ORDS> and C<compute_character_cache*>) is kept verbatim from the fork. The
fork exported C<demo_write>, C<demo_expected_write> and C<unfold_list> without
defining them; this port defines all three, so every exported symbol is
callable.

=head1 FUNCTIONS

=head2 tag

    my $latex = tag($name, \%pairs);

Return the LaTeX definition of one index tag from a hash of key/value pairs, or
a one-line error list when the tag or a value is invalid.

=head2 tag_args

    my $latex = tag_args($name, @args);

Build the backslash-tag call for C<$name> and the argument list, where an
argument may be a coderef paired with its own arguments.

=head2 ged_tag

    my $latex = ged_tag($name, $value);

Return a LaTeX C<gdef> definition of C<$name> holding the escaped C<$value>, or
an error list when the tag is invalid.

=head2 make_index

    my $index = make_index(\%index_variables, %extra);

Turn an index-variables hash, plus an optional extra hash, into the LaTeX index
text, one definition per key.

=head2 demo

    demo();

Write a LaTeX character table for the latin-9 ordinals to F</tmp/demo_chars.tex>
(a diagnostic helper).

=head2 demo_write

    demo_write();

Write the same character table, with unmapped characters replaced, to
F</tmp/demo_write.tex>.

=head2 demo_expected_write

    demo_expected_write();

Write the expected character table to F</tmp/expected_write.txt>, for a human to
diff against L</demo_write>.

=head2 latex_escape_string

    my $escaped = latex_escape_string($string);

Escape a string to the latin-9 output encoding.

=head2 translate_unit

    my $latex = translate_unit($unit);

Translate a unit (C<EUR> or a percent sign) to its LaTeX form; an unknown unit is
an error.

=head2 concat_string

    my $string = concat_string(@parts);

Concatenate the arguments into one string, escaping scalars and calling coderef
arguments.

=head2 latex_boolean

    my $word = latex_boolean($bool);

Return C<true> or C<false> for the boolean.

=head2 unfold_list

    my @flat = unfold_list(@list);

Unfold the list one level, replacing each array reference element with its items.

The unexported helpers C<latex_escape_character>, C<latex_escape_string_no_byte_a6>,
C<latex_list>, C<special_colored_address>, C<latex_xkeyval_value>,
C<remove_roman_numbering>, C<sanitize_csv>, C<index_value>,
C<check_index_is_complete>, C<is_valid_tag>, C<interpret_argument>, the
C<compute_character_cache*> builders and C<@ORDS> are not part of the public API.

=head1 AUTHOR

The oEdtk team.

=cut
