package Text::Bidi::private;
$Text::Bidi::private::VERSION = '3.01';
use 5.010;
use strict;
use warnings;
use Carp qw(croak);
use FFI::CheckLib 0.28 qw(find_lib_or_die);
use FFI::Platypus 2.00;
use FFI::Platypus::Buffer qw(scalar_to_pointer);
use version 0.77;

# ABSTRACT: Private FFI bindings for FriBidi

# These are FriBidi's ABI constants, rather than Unicode property tables.
# Keep their scalar interface for Text::Bidi::Constants and existing callers.
# Values follow fribidi-{unicode,bidi-types,flags,joining-types,brackets,
# deprecated}.h, including the former wrapper's signed bracket-open mask.
while (<DATA>) {
    my ($name, $value) = split;
    no strict 'refs';
    ${__PACKAGE__ . '::' . $name} = 0 + $value;
    Internals::SvREADONLY(${__PACKAGE__ . '::' . $name}, 1);
}
close DATA;

my $ffi = FFI::Platypus->new(
    api => 2,
    lib => $ENV{TEXT_BIDI_FRIBIDI_LIB} || find_lib_or_die(lib => 'fribidi'),
);

for my $name (qw(version_info unicode_version)) {
    my $address = $ffi->find_symbol("fribidi_$name")
        or croak "Cannot find fribidi_$name in the FriBidi library";
    my $pointer = $ffi->cast('opaque' => 'opaque*', $address);
    no strict 'refs';
    ${__PACKAGE__ . '::' . $name} = $ffi->cast('opaque' => 'string', $$pointer);
    Internals::SvREADONLY(${__PACKAGE__ . '::' . $name}, 1);
}

our $version_info;
my ($library_version) = $version_info =~ /\(GNU FriBidi\) ([0-9.]+)/;
croak 'Text::Bidi requires FriBidi 1.0.0 or newer'
    unless defined $library_version
        && version->parse($library_version) >= version->parse('1.0.0');

# FriBidiChar/CharType/BracketType/ParType/Flags are uint32_t;
# StrIndex is int32_t, Level is signed char, and ArabicProp is uint8_t.
# Packed arrays are passed as opaque pointers, with lengths checked below.
my @bindings = (
    [get_bidi_type => ['uint32'] => 'uint32'],
    [get_bidi_type_name => ['uint32'] => 'string'],
    [get_joining_type => ['uint32'] => 'uint8'],
    [get_joining_type_name => ['uint8'] => 'string'],
    [get_bracket => ['uint32'] => 'uint32'],
    [get_bidi_types => ['opaque', 'sint32', 'opaque'] => 'void'],
    [get_joining_types => ['opaque', 'sint32', 'opaque'] => 'void'],
    [get_bracket_types => ['opaque', 'sint32', 'opaque', 'opaque'] => 'void'],
    [get_par_direction => ['opaque', 'sint32'] => 'uint32'],
    [get_par_embedding_levels_ex =>
        ['opaque', 'opaque', 'sint32', 'uint32*', 'opaque'] => 'sint8'],
    [get_mirror_char => ['uint32', 'uint32*'] => 'int'],
    [shape_mirroring => ['opaque', 'sint32', 'opaque'] => 'void'],
    [join_arabic => ['opaque', 'sint32', 'opaque', 'opaque'] => 'void'],
    [shape_arabic => ['uint32', 'opaque', 'sint32', 'opaque', 'opaque'] => 'void'],
    [shape => ['uint32', 'opaque', 'sint32', 'opaque', 'opaque'] => 'void'],
    [reorder_line =>
        ['uint32', 'opaque', 'sint32', 'sint32', 'uint32', 'opaque', 'opaque', 'opaque']
        => 'sint8'],
    [parse_charset => ['string'] => 'int'],
    [charset_to_unicode => ['int', 'opaque', 'sint32', 'opaque'] => 'sint32'],
    [unicode_to_charset => ['int', 'opaque', 'sint32', 'opaque'] => 'sint32'],
);
for my $binding (@bindings) {
    my ($name, $args, $return) = @$binding;
    $ffi->attach(["fribidi_$name" => "_c_$name"] => $args => $return);
}

# Simple scalar lookups need no packed-array adapter.
for my $name (qw(get_bidi_type get_bidi_type_name get_joining_type
                 get_joining_type_name get_bracket)) {
    no strict 'refs';
    *{$name} = \&{"_c_$name"};
}

my $utf8 = _c_parse_charset('UTF-8') or croak 'FriBidi has no UTF-8 charset';

sub _count {
    # SvPVbyte in the former wrapper also rejects wide-character buffers.
    utf8::downgrade($_[0]);
    my $size = length($_[0]);
    croak 'Invalid packed array length'
        if $size % $_[1] || $size / $_[1] > 2147483647;
    return $size / $_[1];
}

sub _same_length {
    my ($expected, $width) = @_[1, 2];
    croak 'Packed arrays must have equal lengths'
        if _count($_[0], $width) != $expected;
}

sub utf8_to_internal {
    my ($input) = @_;
    my $len = _count($input, 1);
    my $out = "\0" x (4 * ($len + 1));
    my $count = _c_charset_to_unicode(
        $utf8, scalar_to_pointer($input), $len, scalar_to_pointer($out));
    return ($count, substr($out, 0, 4 * $count));
}

sub internal_to_utf8 {
    my ($input) = @_;
    my $len = _count($input, 4);
    my $out = "\0" x (4 * ($len + 1));
    my $count = _c_unicode_to_charset(
        $utf8, scalar_to_pointer($input), $len, scalar_to_pointer($out));
    return ($count, substr($out, 0, $count));
}

sub get_bidi_types {
    my ($chars) = @_;
    my $len = _count($chars, 4);
    my $out = "\0" x (4 * $len);
    _c_get_bidi_types(scalar_to_pointer($chars), $len, scalar_to_pointer($out));
    return [unpack 'L*', $out];
}

sub get_joining_types {
    my ($chars) = @_;
    my $len = _count($chars, 4);
    my $out = "\0" x $len;
    _c_get_joining_types(scalar_to_pointer($chars), $len, scalar_to_pointer($out));
    return [unpack 'C*', $out];
}

sub get_bracket_types {
    my ($chars, $types) = @_;
    my $len = _count($chars, 4);
    _same_length($types, $len, 4);
    my $out = "\0" x (4 * $len);
    _c_get_bracket_types(scalar_to_pointer($chars), $len,
        scalar_to_pointer($types), scalar_to_pointer($out));
    return [unpack 'L*', $out];
}

sub get_par_direction {
    my ($types) = @_;
    my $len = _count($types, 4);
    return _c_get_par_direction(scalar_to_pointer($types), $len);
}

sub get_par_embedding_levels_ex {
    my ($types, $brackets, $dir) = @_;
    my $len = _count($types, 4);
    _same_length($brackets, $len, 4);
    my $out = "\0" x $len;
    my $max = _c_get_par_embedding_levels_ex(scalar_to_pointer($types),
        scalar_to_pointer($brackets), $len, \$dir, scalar_to_pointer($out));
    return ($max, $dir, [unpack 'C*', $out]);
}

sub get_mirror_char {
    my ($ch) = @_;
    my $mirror = $ch;
    my $found = _c_get_mirror_char($ch, \$mirror);
    return ($found, $mirror);
}

sub shape_mirroring {
    my ($levels, $chars) = @_;
    my $len = _count($levels, 1);
    _same_length($chars, $len, 4);
    # pack makes a fresh writable allocation, including for COW/literal inputs.
    my $out = pack 'a*', $chars;
    _c_shape_mirroring(scalar_to_pointer($levels), $len, scalar_to_pointer($out));
    return $out;
}

sub join_arabic {
    my ($types, $levels, $props) = @_;
    my $len = _count($types, 4);
    _same_length($levels, $len, 1);
    _same_length($props, $len, 1);
    my $out = pack 'a*', $props;
    _c_join_arabic(scalar_to_pointer($types), $len,
        scalar_to_pointer($levels), scalar_to_pointer($out));
    return [unpack 'C*', $out];
}

sub _shape {
    my ($call, $flags, $levels, $props, $chars) = @_;
    my $len = _count($levels, 1);
    _same_length($props, $len, 1);
    _same_length($chars, $len, 4);
    my $out_props = pack 'a*', $props;
    my $out_chars = pack 'a*', $chars;
    $call->($flags, scalar_to_pointer($levels), $len,
        scalar_to_pointer($out_props), scalar_to_pointer($out_chars));
    return ([unpack 'C*', $out_props], $out_chars);
}

sub shape_arabic { return _shape(\&_c_shape_arabic, @_) }
sub shape        { return _shape(\&_c_shape, @_) }

sub reorder_map {
    my ($flags, $types, $off, $length, $dir, $levels, $map) = @_;
    my $len = _count($types, 4);
    _same_length($levels, $len, 1);
    _same_length($map, $len, 4);
    croak 'Line range is outside the paragraph'
        if $off < 0 || $length < 0 || $off > $len || $length > $len - $off;
    my $out_levels = pack 'a*', $levels;
    my $out_map = pack 'a*', $map;
    my $max = _c_reorder_line($flags, scalar_to_pointer($types), $length, $off,
        $dir, scalar_to_pointer($out_levels), undef, scalar_to_pointer($out_map));
    # The original wrapper promoted signed indices to Perl unsigned integers.
    # Preserve that convention for caller-supplied sentinel values as well.
    my @indices = map { $_ < 0 ? ~(-1 - $_) : $_ } unpack 'l*', $out_map;
    return ($max, [unpack 'C*', $out_levels], \@indices);
}

# Retain the deprecated private entry points for existing consumers. Bind them
# directly to FriBidi so their legacy status flags retain the same semantics.
for my $name (qw(mirroring_status reorder_nsm_status)) {
    $ffi->attach(["fribidi_$name" => $name] => [] => 'int');
}
for my $name (qw(set_mirroring set_reorder_nsm)) {
    $ffi->attach(["fribidi_$name" => $name] => ['int'] => 'int');
}
for my $name (qw(get_type get_type_internal)) {
    $ffi->attach(["fribidi_$name" => $name] => ['uint32'] => 'uint32');
}
for my $name (qw(get_par_embedding_levels log2vis_get_embedding_levels)) {
    $ffi->attach(["fribidi_$name" => "_c_$name"] =>
        ['opaque', 'sint32', 'uint32*', 'opaque'] => 'sint8');
    no strict 'refs';
    my $call = \&{"_c_$name"};
    *{$name} = sub {
        my ($types, $dir) = @_;
        my $len = _count($types, 4);
        my $out = "\0" x $len;
        my $max = $call->(scalar_to_pointer($types), $len,
            \$dir, scalar_to_pointer($out));
        return ($max, $dir, [unpack 'C*', $out]);
    };
}

1;

=pod

=head1 NAME

Text::Bidi::private - Private FFI bindings for FriBidi

=head1 VERSION

version 3.01

=head1 DESCRIPTION

This is the internal FriBidi adapter used by L<Text::Bidi>. It loads the
system shared library using L<FFI::Platypus>, and preserves the packed-buffer
and return-value conventions of the original SWIG adapter. Applications
should use the public modules instead of calling this package directly.

C<TEXT_BIDI_FRIBIDI_LIB> can specify a shared library path when FriBidi is
installed outside the system library search paths. FriBidi 1.0.0 or newer
is required. No FriBidi headers or generated wrapper are needed.

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
FRIBIDI_BIDI_MAX_EXPLICIT_LEVEL 125
FRIBIDI_BIDI_MAX_NESTED_BRACKET_PAIRS 63
FRIBIDI_BIDI_MAX_RESOLVED_LEVELS 127
FRIBIDI_BIDI_NUM_TYPES 19
FRIBIDI_BRACKET_ID_MASK 2147483647
FRIBIDI_BRACKET_OPEN_MASK -2147483648
FRIBIDI_CHAR_ARABIC_ALEF 1575
FRIBIDI_CHAR_ARABIC_ZERO 1632
FRIBIDI_CHAR_FILL 65279
FRIBIDI_CHAR_FSI 8296
FRIBIDI_CHAR_HEBREW_ALEF 1488
FRIBIDI_CHAR_LRE 8234
FRIBIDI_CHAR_LRI 8294
FRIBIDI_CHAR_LRM 8206
FRIBIDI_CHAR_LRO 8237
FRIBIDI_CHAR_LS 8232
FRIBIDI_CHAR_PDF 8236
FRIBIDI_CHAR_PDI 8297
FRIBIDI_CHAR_PERSIAN_ZERO 1776
FRIBIDI_CHAR_PS 8233
FRIBIDI_CHAR_RLE 8235
FRIBIDI_CHAR_RLI 8295
FRIBIDI_CHAR_RLM 8207
FRIBIDI_CHAR_RLO 8238
FRIBIDI_CHAR_ZWJ 8205
FRIBIDI_CHAR_ZWNBSP 65279
FRIBIDI_CHAR_ZWNJ 8204
FRIBIDI_FLAGS_ARABIC 768
FRIBIDI_FLAGS_DEFAULT 262147
FRIBIDI_FLAG_REMOVE_BIDI 65536
FRIBIDI_FLAG_REMOVE_JOINING 131072
FRIBIDI_FLAG_REMOVE_SPECIALS 262144
FRIBIDI_FLAG_REORDER_NSM 2
FRIBIDI_FLAG_SHAPE_ARAB_CONSOLE 1024
FRIBIDI_FLAG_SHAPE_ARAB_LIGA 512
FRIBIDI_FLAG_SHAPE_ARAB_PRES 256
FRIBIDI_FLAG_SHAPE_MIRRORING 1
FRIBIDI_JOINING_TYPE_C_VAL 3
FRIBIDI_JOINING_TYPE_D_VAL 7
FRIBIDI_JOINING_TYPE_G_VAL 16
FRIBIDI_JOINING_TYPE_L_VAL 6
FRIBIDI_JOINING_TYPE_R_VAL 5
FRIBIDI_JOINING_TYPE_T_VAL 12
FRIBIDI_JOINING_TYPE_U_VAL 0
FRIBIDI_MASK_ARABIC 2
FRIBIDI_MASK_ARAB_SHAPES 4
FRIBIDI_MASK_BN 1048576
FRIBIDI_MASK_BS 2097152
FRIBIDI_MASK_CS 262144
FRIBIDI_MASK_ES 65536
FRIBIDI_MASK_ET 131072
FRIBIDI_MASK_EXPLICIT 4096
FRIBIDI_MASK_FIRST 33554432
FRIBIDI_MASK_IGNORED 16
FRIBIDI_MASK_ISOLATE 32768
FRIBIDI_MASK_JOINS_LEFT 2
FRIBIDI_MASK_JOINS_RIGHT 1
FRIBIDI_MASK_LETTER 256
FRIBIDI_MASK_LIGATURED 32
FRIBIDI_MASK_NEUTRAL 64
FRIBIDI_MASK_NSM 524288
FRIBIDI_MASK_NUMBER 512
FRIBIDI_MASK_NUMSEPTER 1024
FRIBIDI_MASK_OVERRIDE 16384
FRIBIDI_MASK_PRIVATE 16777216
FRIBIDI_MASK_RTL 1
FRIBIDI_MASK_SENTINEL 128
FRIBIDI_MASK_SEPARATOR 8192
FRIBIDI_MASK_SPACE 2048
FRIBIDI_MASK_SS 4194304
FRIBIDI_MASK_STRONG 16
FRIBIDI_MASK_TRANSPARENT 8
FRIBIDI_MASK_WEAK 32
FRIBIDI_MASK_WS 8388608
FRIBIDI_PAR_LTR 272
FRIBIDI_PAR_ON 64
FRIBIDI_PAR_RTL 273
FRIBIDI_PAR_WLTR 32
FRIBIDI_PAR_WRTL 33
FRIBIDI_TYPE_AL 275
FRIBIDI_TYPE_AL_VAL 275
FRIBIDI_TYPE_AN 546
FRIBIDI_TYPE_AN_VAL 546
FRIBIDI_TYPE_B 2107456
FRIBIDI_TYPE_BN 1050656
FRIBIDI_TYPE_BN_VAL 1050656
FRIBIDI_TYPE_BS 2107456
FRIBIDI_TYPE_BS_VAL 2107456
FRIBIDI_TYPE_CS 263200
FRIBIDI_TYPE_CS_VAL 263200
FRIBIDI_TYPE_EN 544
FRIBIDI_TYPE_EN_VAL 544
FRIBIDI_TYPE_ES 66592
FRIBIDI_TYPE_ES_VAL 66592
FRIBIDI_TYPE_ET 132128
FRIBIDI_TYPE_ET_VAL 132128
FRIBIDI_TYPE_FSI 33587264
FRIBIDI_TYPE_FSI_VAL 33587264
FRIBIDI_TYPE_L 272
FRIBIDI_TYPE_LRE 4112
FRIBIDI_TYPE_LRE_VAL 4112
FRIBIDI_TYPE_LRI 32832
FRIBIDI_TYPE_LRI_VAL 32832
FRIBIDI_TYPE_LRO 20496
FRIBIDI_TYPE_LRO_VAL 20496
FRIBIDI_TYPE_LTR 272
FRIBIDI_TYPE_LTR_VAL 272
FRIBIDI_TYPE_N 64
FRIBIDI_TYPE_NSM 524320
FRIBIDI_TYPE_NSM_VAL 524320
FRIBIDI_TYPE_ON 64
FRIBIDI_TYPE_ON_VAL 64
FRIBIDI_TYPE_PDF 4128
FRIBIDI_TYPE_PDF_VAL 4128
FRIBIDI_TYPE_PDI 32864
FRIBIDI_TYPE_PDI_VAL 32864
FRIBIDI_TYPE_PRIVATE 16777216
FRIBIDI_TYPE_R 273
FRIBIDI_TYPE_RLE 4113
FRIBIDI_TYPE_RLE_VAL 4113
FRIBIDI_TYPE_RLI 32833
FRIBIDI_TYPE_RLI_VAL 32833
FRIBIDI_TYPE_RLO 20497
FRIBIDI_TYPE_RLO_VAL 20497
FRIBIDI_TYPE_RTL 273
FRIBIDI_TYPE_RTL_VAL 273
FRIBIDI_TYPE_S 4204608
FRIBIDI_TYPE_SENTINEL 128
FRIBIDI_TYPE_SS 4204608
FRIBIDI_TYPE_SS_VAL 4204608
FRIBIDI_TYPE_WL 32
FRIBIDI_TYPE_WLTR 32
FRIBIDI_TYPE_WLTR_VAL 32
FRIBIDI_TYPE_WR 33
FRIBIDI_TYPE_WRTL 33
FRIBIDI_TYPE_WRTL_VAL 33
FRIBIDI_TYPE_WS 8390720
FRIBIDI_TYPE_WS_VAL 8390720
UNI_ARABIC_ALEF 1575
UNI_ARABIC_ZERO 1632
UNI_FARSI_ZERO 1776
UNI_HEBREW_ALEF 1488
UNI_LRE 8234
UNI_LRM 8206
UNI_LRO 8237
UNI_LS 8232
UNI_MAX_BIDI_LEVEL 125
UNI_PS 8233
UNI_RLE 8235
UNI_RLM 8207
UNI_RLO 8238
UNI_ZWJ 8205
UNI_ZWNJ 8204
_FRIBIDI_JOINING_TYPE_JUNK 17
_FRIBIDI_PAR_SENTINEL 128
_FRIBIDI_TYPE_SENTINEL 128
