# Copyright (c) 2025-2026 Voxgig Ltd. MIT LICENSE.
# Perl port of the canonical TypeScript implementation (ts/src/StructUtility.ts).
# See ../REPORT.md for cross-language parity.
package Voxgig::Struct;

use 5.018;
use strict;
use warnings;
use utf8;

our $VERSION = '0.1.0';

use Scalar::Util qw(blessed reftype looks_like_number refaddr);
use List::Util qw();
use B qw();

# ============================================================================
# Voxgig::Struct::OrderedHash — minimal insertion-ordered tied hash.
#
# Perl hashes randomise key order; the canonical contract requires that
# JSON object key order survive every operation. Other ports either get
# this for free (Python 3.7+ dict, Ruby Hash, PHP array, JS object) or
# hand-roll an OrderedMap (C / C++ / Zig). This is the Perl equivalent —
# keeps the port dependency-free. Implements the standard `Tie::Hash`
# protocol plus a `Keys()` direct accessor for fast iteration.
# ============================================================================

package Voxgig::Struct::OrderedHash;

sub TIEHASH {
    my ($class) = @_;
    return bless { _keys => [], _data => {} }, $class;
}

sub STORE {
    my ($self, $key, $value) = @_;
    if (!exists $self->{_data}{$key}) {
        push @{ $self->{_keys} }, $key;
    }
    $self->{_data}{$key} = $value;
    return $value;
}

sub FETCH {
    my ($self, $key) = @_;
    return $self->{_data}{$key};
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->{_data}{$key} ? 1 : 0;
}

sub DELETE {
    my ($self, $key) = @_;
    return unless exists $self->{_data}{$key};
    my $v = delete $self->{_data}{$key};
    @{ $self->{_keys} } = grep { $_ ne $key } @{ $self->{_keys} };
    return $v;
}

sub CLEAR {
    my ($self) = @_;
    @{ $self->{_keys} } = ();
    %{ $self->{_data} } = ();
}

sub FIRSTKEY {
    my ($self) = @_;
    $self->{_iter} = 0;
    return unless @{ $self->{_keys} };
    return $self->{_keys}[0];
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    $self->{_iter}++;
    my $i = $self->{_iter};
    return if $i >= scalar @{ $self->{_keys} };
    return $self->{_keys}[$i];
}

sub SCALAR {
    my ($self) = @_;
    return scalar @{ $self->{_keys} };
}

# Direct ordered-keys accessor (matches Tie::IxHash's `Keys` so the
# rest of Voxgig::Struct's hot path can skip iterator overhead).
sub Keys { @{ $_[0]{_keys} } }

package Voxgig::Struct;

# Distinguish numbers from strings at the SV level. JSON numbers come in with
# IOK / NOK flags set (because our parser does `0+$n`); JSON strings stay
# pure POK. Used in getpath / typify to keep TS's typeof(path) === 'number'
# branch reachable.
sub _is_number_sv {
    my ($val) = @_;
    return 0 unless defined $val;
    return 0 if ref $val;
    my $sv = B::svref_2object(\$val);
    my $flags = $sv->FLAGS;
    return ($flags & (B::SVf_NOK() | B::SVf_IOK())) ? 1 : 0;
}

sub _is_string_sv {
    my ($val) = @_;
    return 0 unless defined $val;
    return 0 if ref $val;
    my $sv = B::svref_2object(\$val);
    my $flags = $sv->FLAGS;
    # POK without IOK/NOK → pure string.
    return ($flags & B::SVf_POK()) && !($flags & (B::SVf_NOK() | B::SVf_IOK())) ? 1 : 0;
}

# ============================================================================
# Constants
# ============================================================================

# Injection modes (a key is injected three times: pre / val / post).
use constant M_KEYPRE  => 1;
use constant M_KEYPOST => 2;
use constant M_VAL     => 4;

# Backtick-quoted command names.
use constant S_BKEY   => '`$KEY`';
use constant S_BANNO  => '`$ANNO`';
use constant S_BEXACT => '`$EXACT`';
use constant S_BVAL   => '`$VAL`';
use constant S_BOPEN  => '`$OPEN`';

# Annotation keys.
use constant S_DKEY  => '$KEY';
use constant S_DTOP  => '$TOP';
use constant S_DERRS => '$ERRS';
use constant S_DSPEC => '$SPEC';
use constant S_DMETA => '$META';

# Type names.
use constant S_list     => 'list';
use constant S_base     => 'base';
use constant S_boolean  => 'boolean';
use constant S_function => 'function';
use constant S_symbol   => 'symbol';
use constant S_instance => 'instance';
use constant S_key      => 'key';
use constant S_any      => 'any';
use constant S_nil      => 'nil';
use constant S_null     => 'null';
use constant S_number   => 'number';
use constant S_object   => 'object';
use constant S_string   => 'string';
use constant S_decimal  => 'decimal';
use constant S_integer  => 'integer';
use constant S_map      => 'map';
use constant S_scalar   => 'scalar';
use constant S_node     => 'node';

# Common single-character strings.
use constant S_BT  => '`';
use constant S_CN  => ':';
use constant S_CS  => ']';
use constant S_DS  => '$';
use constant S_DT  => '.';
use constant S_FS  => '/';
use constant S_KEY => 'KEY';
use constant S_MT  => '';
use constant S_OS  => '[';
use constant S_SP  => ' ';
use constant S_CM  => ',';
use constant S_VIZ => ': ';

# Type bit flags. Same numeric layout as the canonical TS:
# T_any is all-bits-below set; the others are distinct bits decreasing
# down the list. The order matches TYPENAME below for table-driven lookup.
# Type bit-flags. Values match the canonical TypeScript scheme exactly so that
# typify()/typename() return the same numbers the shared corpus pins.
use constant T_any      => (1 << 31) - 1;
use constant T_noval    => 1 << 30;
use constant T_boolean  => 1 << 29;
use constant T_decimal  => 1 << 28;
use constant T_integer  => 1 << 27;
use constant T_number   => 1 << 26;
use constant T_string   => 1 << 25;
use constant T_function => 1 << 24;
use constant T_symbol   => 1 << 23;
use constant T_null     => 1 << 22;
use constant T_list     => 1 << 14;
use constant T_map      => 1 << 13;
use constant T_instance => 1 << 12;
use constant T_scalar   => 1 << 7;
use constant T_node     => 1 << 6;

our %TYPENAME = (
    T_noval()    => S_nil,
    T_boolean()  => S_boolean,
    T_decimal()  => S_decimal,
    T_integer()  => S_integer,
    T_number()   => S_number,
    T_string()   => S_string,
    T_function() => S_function,
    T_symbol()   => S_symbol,
    T_null()     => S_null,
    T_list()     => S_list,
    T_map()      => S_map,
    T_instance() => S_instance,
    T_scalar()   => S_scalar,
    T_node()     => S_node,
);

# Mode → human-readable name (mirrors TS MODENAME).
our %MODENAME = (
    M_KEYPRE()  => 'key:pre',
    M_KEYPOST() => 'key:post',
    M_VAL()     => 'val',
);

# Sentinel for "absent" (corresponds to TS undefined / Python NULLMARK).
# Use a unique blessed reference — refaddr identifies it.
our $NONE = do { my $x = \"$$"; bless $x, 'Voxgig::Struct::None' };
sub NONE { return $NONE }
sub is_none { return defined $_[0] && blessed($_[0]) && blessed($_[0]) eq 'Voxgig::Struct::None' }

# JSON null sentinel — distinct from Perl undef (which is "absent").
our $JNULL = bless \(my $jn_dummy = 'null'), 'Voxgig::Struct::Null';
sub JNULL { return $JNULL }
sub is_jnull { return defined $_[0] && blessed($_[0]) && blessed($_[0]) eq 'Voxgig::Struct::Null' }

# Booleans (JSON true/false).
our $JTRUE  = bless \(my $jt_dummy = 1), 'Voxgig::Struct::Bool';
our $JFALSE = bless \(my $jf_dummy = 0), 'Voxgig::Struct::Bool';
sub JTRUE  { return $JTRUE }
sub JFALSE { return $JFALSE }
sub is_jbool { return defined $_[0] && blessed($_[0]) && blessed($_[0]) eq 'Voxgig::Struct::Bool' }
sub jbool { return $_[0] ? $JTRUE : $JFALSE }

# Bool overloading so $JTRUE/$JFALSE evaluate sanely in boolean context.
package Voxgig::Struct::Bool;
use overload
    'bool'  => sub { ${ $_[0] } ? 1 : 0 },
    '0+'    => sub { ${ $_[0] } ? 1 : 0 },
    '""'    => sub { ${ $_[0] } ? 'true' : 'false' },
    fallback => 1;
sub TO_JSON { return ${ $_[0] } ? \1 : \0 }

# Stringify the JSON-null singleton as 'null' rather than the blessed
# scalar's address (matches TS / JS toString of null).
package Voxgig::Struct::Null;
use overload
    'bool' => sub { 0 },
    '0+'   => sub { 0 },
    '""'   => sub { 'null' },
    fallback => 1;

package Voxgig::Struct;

# Sentinels (immutable singletons). SKIP omits the slot, DELETE removes it.
our $SKIP = _make_sentinel('`$SKIP`');
our $DELETE = _make_sentinel('`$DELETE`');
sub SKIP   { return $SKIP }
sub DELETE { return $DELETE }
sub is_sentinel {
    my ($val) = @_;
    return 0 unless defined $val && blessed($val) && blessed($val) eq 'Voxgig::Struct::Sentinel';
    return 1;
}

sub _make_sentinel {
    my ($mark) = @_;
    my %h;
    tie %h, 'Voxgig::Struct::OrderedHash';
    $h{$mark} = $JTRUE;
    return bless \%h, 'Voxgig::Struct::Sentinel';
}

# Common regex patterns (precompiled).
our $R_INTEGER_KEY     = qr/^-?[0-9]+$/;
our $R_ESCAPE_REGEXP   = qr/[.*+?^\${}()|\[\]\\]/;
our $R_QUOTES          = qr/"/;
our $R_DOT             = qr/\./;
our $R_CLONE_REF       = qr/^`\$REF:([0-9]+)`$/;
our $R_META_PATH       = qr/^([^\$]+)\$([=~])(.+)$/;
our $R_DOUBLE_DOLLAR   = qr/\$\$/;
our $R_TRANSFORM_NAME  = qr/`\$([A-Z]+)`/;
our $R_INJECTION_FULL  = qr/^`(\$[A-Z]+|[^`]*)[0-9]*`$/;
our $R_BT_ESCAPE       = qr/\$BT/;
our $R_DS_ESCAPE       = qr/\$DS/;
our $R_INJECTION_PARTIAL = qr/`([^`]+)`/;

use constant MAXDEPTH => 32;

# ============================================================================
# Map helpers (insertion-ordered hashes via Tie::IxHash).
# ============================================================================

# Build a new empty insertion-ordered map.
sub _mkmap {
    my %h;
    tie %h, 'Voxgig::Struct::OrderedHash';
    return \%h;
}

# Build a new empty list.
sub _mklist { return [] }

# Detect whether a hash reference is tied to Tie::IxHash (i.e. our map type).
sub _is_tied_hash {
    my ($ref) = @_;
    return 0 unless defined $ref;
    my $rt = reftype($ref) // '';
    return 0 unless $rt eq 'HASH';
    return defined tied(%$ref) ? 1 : 0;
}

# Get the in-order keys of a map (or sorted-as-strings for plain hashes).
# Works on plain HASH refs AND blessed hash-backed objects (e.g. sentinels).
sub _map_keys {
    my ($ref) = @_;
    return () unless defined $ref;
    my $rt = reftype($ref) // '';
    return () unless $rt eq 'HASH';
    if (my $tied = tied(%$ref)) {
        return $tied->Keys;
    }
    return keys %$ref;
}

# Ensure a hash is tied to Tie::IxHash (preserving current keys/values in
# their existing order). No-op if already tied.
sub _ensure_ordered {
    my ($ref) = @_;
    return $ref unless ref $ref eq 'HASH';
    return $ref if _is_tied_hash($ref);
    my @pairs;
    push @pairs, $_, $ref->{$_} for keys %$ref;
    %$ref = ();
    tie %$ref, 'Voxgig::Struct::OrderedHash';
    for (my $i = 0; $i < @pairs; $i += 2) {
        $ref->{ $pairs[$i] } = $pairs[ $i + 1 ];
    }
    return $ref;
}

# ============================================================================
# Type predicates
# ============================================================================

# TYPENAME indexed by clz32(typebit): the human name of a type bit-field is the
# name of its highest set bit (matches canonical getelem(TYPENAME, clz32(t))).
our @TYPENAME = (
    S_any, S_nil, S_boolean, S_decimal, S_integer, S_number, S_string,
    S_function, S_symbol, S_null,
    '', '', '', '', '', '', '',
    S_list, S_map, S_instance,
    '', '', '', '',
    S_scalar, S_node,
);

sub typename {
    my ($t) = @_;
    $t = 0 unless defined $t;
    $t = int($t) & 0xFFFFFFFF;
    return $TYPENAME[0] if $t == 0;
    # clz32: index of the highest set bit, counted from the top of 32 bits.
    my $hb = 0;
    my $v = $t;
    while ($v > 1) { $v >>= 1; $hb++ }
    my $clz = 31 - $hb;
    my $name = $TYPENAME[$clz];
    return (defined $name && $name ne '') ? $name : $TYPENAME[0];
}

sub getdef {
    my ($val, $alt) = @_;
    return is_none($val) ? $alt : (defined $val ? $val : $alt);
}

sub isnode {
    my ($val) = @_;
    return 0 unless defined $val;
    return 0 if is_none($val) || is_jnull($val) || is_sentinel($val) || is_jbool($val);
    return 0 unless ref $val;
    my $r = reftype($val) // ref($val);
    return 1 if $r eq 'HASH' || $r eq 'ARRAY';
    return 0;
}

sub ismap {
    my ($val) = @_;
    return 0 unless defined $val;
    return 0 if is_none($val) || is_jnull($val) || is_sentinel($val) || is_jbool($val);
    return 0 unless ref $val;
    my $r = reftype($val) // ref($val);
    return $r eq 'HASH' ? 1 : 0;
}

sub islist {
    my ($val) = @_;
    return 0 unless defined $val;
    return 0 if is_none($val) || is_jnull($val) || is_sentinel($val) || is_jbool($val);
    return 0 unless ref $val;
    my $r = reftype($val) // ref($val);
    return $r eq 'ARRAY' ? 1 : 0;
}

sub iskey {
    my ($k) = @_;
    return 0 unless defined $k;
    return 0 if is_none($k) || is_jnull($k);
    if (!ref $k) {
        return 0 if $k eq '';
        # Either a non-empty string, or a number.
        return 1;
    }
    return 0;
}

sub isempty {
    my ($val) = @_;
    return 1 if !defined $val || is_none($val) || is_jnull($val);
    if (!ref $val) {
        return $val eq '' ? 1 : 0;
    }
    if (islist($val)) { return @$val == 0 ? 1 : 0 }
    if (ismap($val))  { return _map_keys($val) == 0 ? 1 : 0 }
    return 0;
}

sub isfunc {
    my ($val) = @_;
    return defined $val && ref $val eq 'CODE' ? 1 : 0;
}

sub size {
    my ($val) = @_;
    return 0 if !defined $val || is_none($val) || is_jnull($val);
    if (is_jbool($val)) { return $$val ? 1 : 0 }
    if (ref $val) {
        if (islist($val)) { return scalar @$val }
        if (ismap($val))  { return scalar _map_keys($val) }
        return 0;
    }
    if (looks_like_number($val) && "$val" !~ /[^0-9eE.+\-]/) {
        # Number: floor.
        my $n = 0 + $val;
        return int($n);  # int() in Perl truncates toward zero; matches floor for >=0
    }
    return length($val);
}

# Slice a list, string or number (clamp). Negative indices supported.
# When `mutate` is set, mutates the list in place.
sub slice {
    my ($val, $start, $end, $mutate) = @_;
    if (defined $val && !ref($val) && looks_like_number($val) && $val !~ /[^0-9eE.+\-]/ && $val ne '') {
        # Number → clamp.
        my $lo = (defined $start && looks_like_number($start)) ? 0 + $start : -2**52;
        my $hi = (defined $end && looks_like_number($end)) ? (0 + $end) - 1 : 2**52;
        my $v = 0 + $val;
        $v = $lo if $v < $lo;
        $v = $hi if $v > $hi;
        return $v;
    }
    my $vlen = size($val);
    if (defined $end && !defined $start) { $start = 0 }
    if (defined $start) {
        if ($start < 0) {
            $end = $vlen + $start;
            $end = 0 if $end < 0;
            $start = 0;
        }
        elsif (defined $end) {
            if ($end < 0) {
                $end = $vlen + $end;
                $end = 0 if $end < 0;
            }
            elsif ($vlen < $end) {
                $end = $vlen;
            }
        }
        else {
            $end = $vlen;
        }
        $start = $vlen if $vlen < $start;
        if (-1 < $start && $start <= $end && $end <= $vlen) {
            if (islist($val)) {
                if ($mutate) {
                    my @kept = @{$val}[ $start .. $end - 1 ];
                    @$val = @kept;
                    return $val;
                }
                return [ @{$val}[ $start .. $end - 1 ] ];
            }
            elsif (!ref $val) {
                return substr($val, $start, $end - $start);
            }
        }
        else {
            if (islist($val)) {
                @$val = () if $mutate;
                return $mutate ? $val : [];
            }
            elsif (!ref $val) {
                return '';
            }
        }
    }
    return $val;
}

sub pad {
    my ($str, $padding, $padchar) = @_;
    $str = _is_string_sv($str) ? $str : stringify($str);
    $padding = 44 unless defined $padding;
    # Use the first character of padchar (or a space); a multi-char padchar
    # collapses to its first char, matching the canonical TS implementation.
    $padchar = (defined $padchar && length $padchar) ? substr($padchar, 0, 1) : ' ';
    my $s = "$str";
    my $need = abs($padding) - length($s);
    return $s if $need <= 0;
    my $fill = $padchar x $need;
    return $padding < 0 ? $fill . $s : $s . $fill;
}

# Compute a bit-flag describing the type of value.
sub typify {
    my ($value) = @_;
    return T_noval if !defined $value || is_none($value);
    return T_scalar | T_null if is_jnull($value);
    if (is_jbool($value)) { return T_scalar | T_boolean }
    if (is_sentinel($value)) { return T_node | T_map }
    if (ref $value) {
        if (islist($value)) { return T_node | T_list }
        if (isfunc($value)) { return T_scalar | T_function }
        if (ismap($value))  { return T_node | T_map }
        return T_node | T_instance;
    }
    # Scalar.
    if (_is_number_sv($value)) {
        if ($value =~ /[.eE]/ || (int($value) != $value)) {
            return T_scalar | T_number | T_decimal;
        }
        return T_scalar | T_number | T_integer;
    }
    return T_scalar | T_string;
}

# Get an element from a list with negative-index support and a fallback.
# Mirrors TS getelem.
sub getelem {
    my ($val, $key, $alt) = @_;
    $alt = is_none($_[2]) ? $NONE : (exists $_[2] ? $alt : $NONE);
    return $alt unless islist($val);
    my $len = scalar @$val;
    my $k;
    if (defined $key && !ref($key) && looks_like_number($key)) { $k = int($key) }
    elsif (ref $key eq 'CODE') {
        # Fallback callback (TS supports getelem(val, key, () => ...)).
        return $key->();
    }
    else { return $alt }
    $k = $len + $k if $k < 0;
    return $alt if $k < 0 || $k >= $len;
    my $v = $val->[$k];
    # A null (or absent/NONE) slot counts as "no value" → alt, the same
    # Group A rule getprop applies; a function alt is called.
    if (!defined $v || is_none($v) || is_jnull($v)) {
        return (typify($alt) & T_function) ? $alt->() : $alt;
    }
    return $v;
}

sub getprop {
    my ($val, $key, $alt) = @_;
    $alt = NONE() unless exists $_[2];
    return $alt unless defined $val && ref $val;
    if (islist($val)) {
        return getelem($val, $key, $alt);
    }
    if (ismap($val)) {
        my $k = strkey($key);
        return $alt if $k eq '';
        return $alt unless exists $val->{$k};
        my $v = $val->{$k};
        # Group A semantics: stored null counts as absent for getprop.
        return $alt if !defined $v || is_jnull($v) || is_none($v);
        return $v;
    }
    return $alt;
}

# Group B: read raw stored value (including JSON null) at a slot.
sub _lookup {
    my ($val, $key) = @_;
    return NONE() unless defined $val && ref $val;
    if (islist($val)) {
        return NONE() unless defined $key && !ref($key) && looks_like_number($key);
        my $k = int($key);
        my $len = scalar @$val;
        $k = $len + $k if $k < 0;
        return NONE() if $k < 0 || $k >= $len;
        my $v = $val->[$k];
        return is_none($v) ? NONE() : $v;
    }
    if (ismap($val)) {
        my $k = strkey($key);
        return NONE() if $k eq '';
        return NONE() unless exists $val->{$k};
        return $val->{$k};
    }
    return NONE();
}

sub strkey {
    my ($key) = @_;
    return S_MT if !defined $key || is_none($key);
    my $t = typify($key);
    if ($t & T_string)  { return $key }
    if ($t & T_boolean) { return S_MT }
    if ($t & T_number)  {
        # Integers stringify as-is; non-integers truncate toward zero.
        return ($key == int($key)) ? "" . $key : "" . int($key);
    }
    return S_MT;
}

sub keysof {
    my ($val) = @_;
    return [] unless defined $val && ref $val;
    if (islist($val)) {
        my @k = map { "$_" } 0 .. $#$val;
        return \@k;
    }
    if (ismap($val)) {
        my @keys = _map_keys($val);
        return [ sort @keys ];
    }
    return [];
}

sub haskey {
    my ($val, $key) = @_;
    return 0 unless defined $val && ref $val;
    if (islist($val)) {
        return 0 unless defined $key && !ref($key) && looks_like_number($key);
        my $k = int($key);
        my $len = scalar @$val;
        $k = $len + $k if $k < 0;
        return 0 if $k < 0 || $k >= $len;
        my $v = $val->[$k];
        return (defined $v && !is_jnull($v) && !is_none($v)) ? 1 : 0;
    }
    if (ismap($val)) {
        my $k = strkey($key);
        return 0 if $k eq '';
        return 0 unless exists $val->{$k};
        my $v = $val->{$k};
        return (defined $v && !is_jnull($v) && !is_none($v)) ? 1 : 0;
    }
    return 0;
}

# items: return [ [k0,v0], [k1,v1] ... ]. With $apply, apply to each pair.
sub items {
    my ($val, $apply) = @_;
    my $islist = islist($val);
    my @out;
    # keysof() returns sorted map keys (and '0','1',… for lists), so items are
    # in the same order the canonical implementation produces.
    for my $k (@{ keysof($val) }) {
        my $v = $islist ? $val->[$k] : $val->{$k};
        my $pair = [ "$k", $v ];
        push @out, defined $apply ? $apply->($pair) : $pair;
    }
    return \@out;
}

sub flatten {
    my ($list, $depth) = @_;
    return $list unless islist($list);
    $depth = getdef($depth, 1);
    return _flatten_depth($list, $depth);
}

sub _flatten_depth {
    my ($list, $depth) = @_;
    my @out;
    for my $item (@$list) {
        if ($depth > 0 && islist($item)) {
            push @out, @{ _flatten_depth($item, $depth - 1) };
        }
        else {
            push @out, $item;
        }
    }
    return \@out;
}

# Filter a list or map by predicate. Lists return [v...]; maps return [[k,v]...].
sub filter {
    my ($val, $pred) = @_;
    return [] unless defined $val && ref $val;
    my @out;
    if (islist($val)) {
        for (my $i = 0; $i < @$val; $i++) {
            my $pair = [ "$i", $val->[$i] ];
            push @out, $val->[$i] if $pred->($pair);
        }
    }
    elsif (ismap($val)) {
        for my $k (_map_keys($val)) {
            my $pair = [ "$k", $val->{$k} ];
            push @out, $val->{$k} if $pred->($pair);
        }
    }
    return \@out;
}

# Escape a string for use as a literal pattern in a regular expression.
sub escre {
    my ($s) = @_;
    return '' unless defined $s;
    $s = "$s";
    $s =~ s/([.*+?^\${}()|\[\]\\])/\\$1/g;
    return $s;
}

# Escape characters that are unsafe in a URL component.
sub escurl {
    my ($s) = @_;
    return '' unless defined $s;
    $s = "$s";
    $s =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    return $s;
}

# Join list parts with a separator. With trailing-separator option.
sub join {
    my ($arr, $sep, $url) = @_;
    my $sarr = size($arr);
    my $sepdef = getdef($sep, S_CM);
    my $sepre = (size($sepdef) == 1) ? escre($sepdef) : $NONE;

    # Keep only the non-empty string elements.
    my $inner = filter($arr, sub {
        my $n = $_[0];
        return (0 < (T_string & typify($n->[1]))) && (S_MT ne $n->[1]);
    });

    # Strip the separator at element boundaries and collapse internal runs of
    # the separator to a single one, so a single sep ends up between elements.
    my $mapped = items($inner, sub {
        my $n = $_[0];
        my $i = 0 + $n->[0];
        my $s = $n->[1];
        if (!is_none($sepre) && S_MT ne $sepre) {
            if ($url && 0 == $i) {
                return re_replace($sepre . '+$', $s, S_MT);
            }
            if (0 < $i) {
                $s = re_replace('^' . $sepre . '+', $s, S_MT);
            }
            if ($i < $sarr - 1 || !$url) {
                $s = re_replace($sepre . '+$', $s, S_MT);
            }
            $s = re_replace(
                '([^' . $sepre . '])' . $sepre . '+([^' . $sepre . '])',
                $s,
                sub { $_[0][1] . $sepdef . $_[0][2] },
            );
        }
        return $s;
    });

    my $result = filter($mapped, sub { S_MT ne $_[0]->[1] });
    return CORE::join($sepdef, @$result);
}

# Convert a path to a dotted string. depth>0 → start at that depth.
sub pathify {
    my ($val, $startin, $endin) = @_;
    my $pathstr = $NONE;

    my $path;
    if (islist($val)) {
        $path = $val;
    }
    elsif (!ref($val) && defined($val) && _is_string_sv($val)) {
        $path = [$val];
    }
    elsif (!ref($val) && defined($val) && _is_number_sv($val)) {
        $path = [$val];
    }
    else {
        $path = $NONE;
    }

    my $start = (!defined $startin) ? 0 : ($startin > -1 ? $startin : 0);
    my $end   = (!defined $endin)   ? 0 : ($endin   > -1 ? $endin   : 0);

    if (!is_none($path) && $start >= 0) {
        $path = slice($path, $start, scalar(@$path) - $end);
        if (scalar(@$path) == 0) {
            $pathstr = '<root>';
        }
        else {
            # Drop non-key segments (booleans, null, nodes); render numbers as
            # truncated integers and strip dots out of string segments.
            my $kept = filter($path, sub { iskey($_[0]->[1]) });
            my $segs = items($kept, sub {
                my $p = $_[0]->[1];
                if (!ref($p) && _is_number_sv($p)) { return S_MT . int($p) }
                my $s = "$p";
                $s =~ s/\.//g;
                return $s;
            });
            $pathstr = Voxgig::Struct::join($segs, S_DT);
        }
    }

    if (is_none($pathstr)) {
        # Canonical NONE is `undefined`, so an absent value renders the same as
        # NONE (no trailing ":value").
        my $absent = is_none($val) || !defined($val);
        $pathstr = '<unknown-path'
            . ($absent ? S_MT : (S_CN . stringify($val, 47)))
            . '>';
    }

    return $pathstr;
}

# Compact-format a JSON-like value to a string (no whitespace).
sub jsonify {
    my ($val, $flags) = @_;
    # Canonical signature: jsonify(val, { indent => N, offset => M }). Default
    # indent is 2 (pretty). A bare numeric second arg is also accepted as the
    # indent for backward compatibility.
    my $indent = 2;
    my $offset = 0;
    if (defined $flags) {
        if (ismap($flags)) {
            $indent = $flags->{indent} if defined $flags->{indent};
            $offset = $flags->{offset} if defined $flags->{offset};
        }
        elsif (!ref $flags && Scalar::Util::looks_like_number($flags)) {
            $indent = $flags;
        }
    }
    my $str = _jsonify_inner($val, $indent, 0);
    if (defined $offset && $offset > 0) {
        # Left-offset the entire indented JSON so it aligns with surrounding
        # code indented by $offset. The first brace stays on the assignment line.
        my @lines = split /\n/, $str, -1;
        shift @lines;
        my @padded = map { (' ' x $offset) . $_ } @lines;
        $str = "{\n" . CORE::join("\n", @padded);
    }
    return $str;
}

sub _jsonify_inner {
    my ($val, $indent, $depth) = @_;
    return 'null' if !defined $val || is_jnull($val);
    return 'null' if is_none($val);  # NONE collapses to null when serialised.
    if (is_jbool($val)) { return $$val ? 'true' : 'false' }
    if (is_sentinel($val)) {
        # Sentinel — emit its own backtick marker.
        my ($mark) = _map_keys($val);
        return "\"$mark\"";
    }
    if (!ref $val) {
        if (_is_number_sv($val)) {
            return _format_number($val);
        }
        return _json_string($val);
    }
    if (islist($val)) {
        return '[]' unless @$val;
        my @parts;
        for my $v (@$val) {
            push @parts, _jsonify_inner($v, $indent, $depth + 1);
        }
        if ($indent > 0) {
            my $pad = (' ' x $indent) x ($depth + 1);
            my $end = (' ' x $indent) x $depth;
            return "[\n$pad" . CORE::join(",\n$pad", @parts) . "\n$end]";
        }
        return '[' . CORE::join(',', @parts) . ']';
    }
    if (ismap($val)) {
        my @keys = _map_keys($val);
        return '{}' unless @keys;
        my @parts;
        for my $k (@keys) {
            my $kj = _json_string($k);
            my $vj = _jsonify_inner($val->{$k}, $indent, $depth + 1);
            if ($indent > 0) {
                push @parts, "$kj: $vj";
            }
            else {
                push @parts, "$kj:$vj";
            }
        }
        if ($indent > 0) {
            my $pad = (' ' x $indent) x ($depth + 1);
            my $end = (' ' x $indent) x $depth;
            return "{\n$pad" . CORE::join(",\n$pad", @parts) . "\n$end}";
        }
        return '{' . CORE::join(',', @parts) . '}';
    }
    if (isfunc($val)) { return '"<function>"' }
    return 'null';
}

# Format a number using TS / JS %g-style: drop trailing zeros, no trailing dot.
sub _format_number {
    my ($v) = @_;
    if ($v == int($v) && $v !~ /[.eE]/) {
        return "" . int($v);
    }
    my $s = sprintf('%.15g', 0 + $v);
    return $s;
}

# Escape and quote a JSON string.
sub _json_string {
    my ($s) = @_;
    return '""' unless defined $s;
    $s = "$s";
    $s =~ s/\\/\\\\/g;
    $s =~ s/"/\\"/g;
    $s =~ s/\x08/\\b/g;
    $s =~ s/\x09/\\t/g;
    $s =~ s/\x0A/\\n/g;
    $s =~ s/\x0C/\\f/g;
    $s =~ s/\x0D/\\r/g;
    $s =~ s/([\x00-\x1F])/sprintf('\\u%04x', ord($1))/ge;
    return '"' . $s . '"';
}

# Human-friendly stringification (TS canonical stringify): JSON.stringify
# with a replacer that sorts map keys alphabetically (mirrors TS), then
# strip all double-quotes. Numbers, booleans and null are emitted as bare
# values. Strings come out unquoted at the root.
sub stringify {
    my ($val, $maxlen, $pretty) = @_;
    return $pretty ? '<>' : '' if is_none($val);
    my $s;
    if (!defined $val) {
        $s = '';
    }
    elsif (!ref $val && _is_string_sv($val)) {
        $s = $val;
    }
    else {
        $s = _stringify_inner($val, 1);
        $s =~ s/"//g;
    }
    if (defined $maxlen && $maxlen > -1) {
        if (length($s) > $maxlen) {
            $s = substr($s, 0, $maxlen - 3) . '...';
        }
    }
    return $s;
}

sub _stringify_inner {
    my ($val, $sort_keys) = @_;
    return 'null' if !defined $val || is_jnull($val) || is_none($val);
    if (is_jbool($val))     { return $$val ? 'true' : 'false' }
    if (is_sentinel($val)) {
        my ($mark) = _map_keys($val);
        return "\"$mark\"";
    }
    if (!ref $val) {
        if (_is_number_sv($val)) { return _format_number($val) }
        return _json_string($val);
    }
    if (islist($val)) {
        return '[]' unless @$val;
        return '[' . CORE::join(',', map { _stringify_inner($_, $sort_keys) } @$val) . ']';
    }
    if (ismap($val)) {
        my @keys = _map_keys($val);
        @keys = sort @keys if $sort_keys;
        return '{}' unless @keys;
        my @parts = map {
            _json_string($_) . ':' . _stringify_inner($val->{$_}, $sort_keys)
        } @keys;
        return '{' . CORE::join(',', @parts) . '}';
    }
    if (isfunc($val)) { return '"<function>"' }
    return 'null';
}

# Deep clone with reference-stability tracking for shared structures.
sub clone {
    my ($val) = @_;
    return _clone_inner($val, {});
}

sub _clone_inner {
    my ($val, $seen) = @_;
    return $val unless defined $val;
    return $val if is_none($val) || is_jnull($val) || is_jbool($val);
    return $val if is_sentinel($val);
    return $val unless ref $val;
    return $val if isfunc($val);
    my $addr = refaddr($val);
    return $seen->{$addr} if defined $addr && exists $seen->{$addr};
    if (islist($val)) {
        my $out = [];
        $seen->{$addr} = $out if defined $addr;
        push @$out, _clone_inner($_, $seen) for @$val;
        return $out;
    }
    if (ismap($val)) {
        my $out = _mkmap();
        $seen->{$addr} = $out if defined $addr;
        for my $k (_map_keys($val)) {
            $out->{$k} = _clone_inner($val->{$k}, $seen);
        }
        return $out;
    }
    return $val;
}

# Delete a property; safe on lists (negative index) and maps.
sub delprop {
    my ($val, $key) = @_;
    return $val unless defined $val && ref $val;
    if (islist($val)) {
        return $val unless defined $key && !ref($key) && looks_like_number($key);
        my $k = int($key);
        my $len = scalar @$val;
        # A negative or out-of-bounds index is a no-op (no end-relative delete).
        return $val if $k < 0 || $k >= $len;
        splice(@$val, $k, 1);
        return $val;
    }
    if (ismap($val)) {
        my $k = strkey($key);
        return $val if $k eq '';
        delete $val->{$k};
        return $val;
    }
    return $val;
}

# Set a property; sentinels SKIP/DELETE handled specially.
sub setprop {
    my ($val, $key, $newval) = @_;
    return $val unless defined $val && ref $val;
    if (is_sentinel($newval)) {
        my ($mark) = _map_keys($newval);
        if ($mark eq '`$SKIP`')   { return $val }
        if ($mark eq '`$DELETE`') { return delprop($val, $key) }
    }
    if (is_none($newval)) { return delprop($val, $key) }
    if (islist($val)) {
        return $val unless defined $key && !ref($key) && looks_like_number($key);
        my $k = int($key);
        my $len = scalar @$val;
        if ($k >= 0) {
            # Set or append; an out-of-bounds index clamps to the end (append).
            $k = $len if $k > $len;
            $val->[$k] = $newval;
        }
        else {
            # A negative index prepends.
            unshift @$val, $newval;
        }
        return $val;
    }
    if (ismap($val)) {
        my $k = strkey($key);
        return $val if $k eq '';
        $val->{$k} = $newval;
        return $val;
    }
    return $val;
}

1;  # End of Voxgig::Struct (more to come).

# ============================================================================
# Insertion-order-preserving JSON parser.
# Needed because Cpanel::JSON::XS / JSON::PP return plain Perl hashes whose
# key order is randomised. We hand-roll a minimal recursive-descent parser
# that builds Tie::IxHash maps. Numbers stay as Perl scalars; booleans
# become $JTRUE / $JFALSE; null becomes $JNULL; strings stay scalar.
# ============================================================================

package Voxgig::Struct::JsonParser;
use strict;
use warnings;
use Scalar::Util qw();

sub parse {
    my ($text) = @_;
    my $self = bless { text => $text, pos => 0, len => length($text) }, __PACKAGE__;
    $self->_skip_ws;
    my $v = $self->_parse_value;
    $self->_skip_ws;
    die "JSON: trailing data at pos $self->{pos}" if $self->{pos} < $self->{len};
    return $v;
}

sub _skip_ws {
    my ($self) = @_;
    while ($self->{pos} < $self->{len}) {
        my $c = substr($self->{text}, $self->{pos}, 1);
        last unless $c eq ' ' || $c eq "\t" || $c eq "\n" || $c eq "\r";
        $self->{pos}++;
    }
}

sub _peek {
    my ($self) = @_;
    return $self->{pos} < $self->{len} ? substr($self->{text}, $self->{pos}, 1) : '';
}

sub _parse_value {
    my ($self) = @_;
    $self->_skip_ws;
    my $c = $self->_peek;
    return $self->_parse_object if $c eq '{';
    return $self->_parse_array  if $c eq '[';
    return $self->_parse_string if $c eq '"';
    return $self->_parse_keyword if $c eq 't' || $c eq 'f' || $c eq 'n';
    return $self->_parse_number;
}

sub _parse_object {
    my ($self) = @_;
    $self->{pos}++;  # consume {
    my %h;
    tie %h, 'Voxgig::Struct::OrderedHash';
    $self->_skip_ws;
    if ($self->_peek eq '}') { $self->{pos}++; return \%h }
    while (1) {
        $self->_skip_ws;
        die "JSON: expected string key at pos $self->{pos}" unless $self->_peek eq '"';
        my $k = $self->_parse_string;
        $self->_skip_ws;
        die "JSON: expected : at pos $self->{pos}" unless $self->_peek eq ':';
        $self->{pos}++;
        my $v = $self->_parse_value;
        $h{$k} = $v;
        $self->_skip_ws;
        my $c = $self->_peek;
        if ($c eq ',') { $self->{pos}++; next }
        if ($c eq '}') { $self->{pos}++; last }
        die "JSON: expected , or } at pos $self->{pos}";
    }
    return \%h;
}

sub _parse_array {
    my ($self) = @_;
    $self->{pos}++;  # consume [
    my @a;
    $self->_skip_ws;
    if ($self->_peek eq ']') { $self->{pos}++; return \@a }
    while (1) {
        my $v = $self->_parse_value;
        push @a, $v;
        $self->_skip_ws;
        my $c = $self->_peek;
        if ($c eq ',') { $self->{pos}++; next }
        if ($c eq ']') { $self->{pos}++; last }
        die "JSON: expected , or ] at pos $self->{pos}";
    }
    return \@a;
}

sub _parse_string {
    my ($self) = @_;
    $self->{pos}++;  # consume "
    my $out = '';
    while ($self->{pos} < $self->{len}) {
        my $c = substr($self->{text}, $self->{pos}, 1);
        if ($c eq '"') { $self->{pos}++; return $out }
        if ($c eq '\\') {
            my $esc = substr($self->{text}, $self->{pos} + 1, 1);
            if    ($esc eq '"')  { $out .= '"';  $self->{pos} += 2 }
            elsif ($esc eq '\\') { $out .= '\\'; $self->{pos} += 2 }
            elsif ($esc eq '/')  { $out .= '/';  $self->{pos} += 2 }
            elsif ($esc eq 'b')  { $out .= "\x08"; $self->{pos} += 2 }
            elsif ($esc eq 'f')  { $out .= "\x0C"; $self->{pos} += 2 }
            elsif ($esc eq 'n')  { $out .= "\x0A"; $self->{pos} += 2 }
            elsif ($esc eq 'r')  { $out .= "\x0D"; $self->{pos} += 2 }
            elsif ($esc eq 't')  { $out .= "\x09"; $self->{pos} += 2 }
            elsif ($esc eq 'u') {
                my $hex = substr($self->{text}, $self->{pos} + 2, 4);
                $out .= chr(hex($hex));
                $self->{pos} += 6;
            }
            else {
                $out .= $esc;
                $self->{pos} += 2;
            }
        }
        else {
            $out .= $c;
            $self->{pos}++;
        }
    }
    die "JSON: unterminated string";
}

sub _parse_keyword {
    my ($self) = @_;
    if (substr($self->{text}, $self->{pos}, 4) eq 'true') {
        $self->{pos} += 4;
        return $Voxgig::Struct::JTRUE;
    }
    if (substr($self->{text}, $self->{pos}, 5) eq 'false') {
        $self->{pos} += 5;
        return $Voxgig::Struct::JFALSE;
    }
    if (substr($self->{text}, $self->{pos}, 4) eq 'null') {
        $self->{pos} += 4;
        return $Voxgig::Struct::JNULL;
    }
    die "JSON: invalid keyword at pos $self->{pos}";
}

sub _parse_number {
    my ($self) = @_;
    my $start = $self->{pos};
    my $c = $self->_peek;
    $self->{pos}++ if $c eq '-';
    while ($self->{pos} < $self->{len}) {
        my $d = substr($self->{text}, $self->{pos}, 1);
        last unless $d =~ /[0-9.eE+\-]/;
        $self->{pos}++;
    }
    my $s = substr($self->{text}, $start, $self->{pos} - $start);
    # Force the SV to be IOK or NOK so callers can distinguish from a string.
    if ($s =~ /[.eE]/) {
        my $n = 0 + $s;
        $n += 0;  # ensure NOK
        return $n;
    }
    else {
        my $n = int($s);
        $n += 0;  # ensure IOK
        return $n;
    }
}

package Voxgig::Struct;

sub parse_json {
    my ($text) = @_;
    return Voxgig::Struct::JsonParser::parse($text);
}

# ============================================================================
# Walk: recursive descent with before/after callbacks and depth control.
# ============================================================================

sub walk {
    my ($val, $before, $after, $maxdepth) = @_;
    $maxdepth = MAXDEPTH unless defined $maxdepth;
    return _walk_inner($val, undef, undef, [], $before, $after, $maxdepth, 0);
}

sub _walk_inner {
    my ($val, $key, $parent, $path, $before, $after, $maxdepth, $depth) = @_;
    if (defined $before) {
        $val = $before->($key, $val, $parent, $path);
    }
    if ($depth >= $maxdepth) {
        return $val;
    }
    if (islist($val)) {
        for (my $i = 0; $i < @$val; $i++) {
            my $sub_path = [ @$path, "$i" ];
            $val->[$i] = _walk_inner($val->[$i], "$i", $val, $sub_path, $before, $after, $maxdepth, $depth + 1);
        }
    }
    elsif (ismap($val)) {
        for my $k (_map_keys($val)) {
            my $sub_path = [ @$path, "$k" ];
            $val->{$k} = _walk_inner($val->{$k}, $k, $val, $sub_path, $before, $after, $maxdepth, $depth + 1);
        }
    }
    if (defined $after) {
        $val = $after->($key, $val, $parent, $path);
    }
    return $val;
}

# ============================================================================
# Merge: deep merge of a list of nodes. Later wins; nodes deep-merge,
# scalars overwrite. With $depth=1, only top-level merges.
# ============================================================================

sub merge {
    my ($vals, $depth) = @_;
    return $vals unless islist($vals);
    return unless @$vals;
    return $vals->[0] if @$vals == 1;
    my $out = $vals->[0];
    $depth = MAXDEPTH unless defined $depth;
    for (my $i = 1; $i < @$vals; $i++) {
        $out = _merge_pair($out, $vals->[$i], $depth, 0);
    }
    return $out;
}

sub _merge_pair {
    my ($a, $b, $maxdepth, $depth) = @_;
    return $b if !defined $a || is_none($a);
    return $b unless isnode($a);
    return $b unless isnode($b);
    return $b if islist($a) != islist($b);  # type mismatch → replace
    if ($depth >= $maxdepth) { return $b }
    if (islist($a)) {
        for (my $i = 0; $i < @$b; $i++) {
            if ($i < @$a) {
                $a->[$i] = _merge_pair($a->[$i], $b->[$i], $maxdepth, $depth + 1);
            }
            else {
                $a->[$i] = $b->[$i];
            }
        }
        return $a;
    }
    # Map.
    for my $k (_map_keys($b)) {
        my $bv = $b->{$k};
        if (exists $a->{$k}) {
            $a->{$k} = _merge_pair($a->{$k}, $bv, $maxdepth, $depth + 1);
        }
        else {
            $a->{$k} = $bv;
        }
    }
    return $a;
}

# ============================================================================
# setpath: descend a dotted path and set a leaf value (creating maps/lists).
# ============================================================================

sub setpath {
    my ($store, $path_in, $val, $injdef) = @_;

    # Coerce the path into a parts list via typify, matching canonical:
    # a list path is used as-is, a string path is dot-split, a number path
    # becomes a single-element list; anything else returns NONE.
    my $ptype = typify($path_in);
    my @parts;
    if ($ptype & T_list) {
        @parts = @$path_in;
    }
    elsif ($ptype & T_string) {
        @parts = split /\./, "$path_in", -1;
    }
    elsif ($ptype & T_number) {
        @parts = ($path_in);
    }
    else {
        return NONE();
    }

    my $base = getprop($injdef, S_base);
    my $numparts = scalar @parts;
    # parent = store[base] (defaulting to store), the node we descend from.
    my $parent = getprop($store, $base, $store);

    for (my $i = 0; $i < $numparts - 1; $i++) {
        my $part_key = getelem(\@parts, $i);
        my $next_parent = getprop($parent, $part_key);
        if (!isnode($next_parent)) {
            # A list part is created only when the NEXT path part is a real
            # number; a string-digit (e.g. "0" from a dotted path) makes a map.
            my $nexttype = typify(getelem(\@parts, $i + 1));
            $next_parent = ($nexttype & T_number) ? [] : _mkmap();
            setprop($parent, $part_key, $next_parent);
        }
        $parent = $next_parent;
    }

    # setprop already routes a DELETE sentinel (and NONE) to delprop, matching
    # canonical's `DELETE === val ? delprop(...) : setprop(...)`.
    my $last = getelem(\@parts, -1);
    setprop($parent, $last, $val);

    # Return the leaf key's PARENT node (canonical), not the whole store.
    return $parent;
}

# ============================================================================
# getpath: descend a dotted path with optional injection context.
# Supports ancestor traversal via consecutive dots (".." = parent of parent).
# Absolute paths starting with a top-level key; relative paths starting with
# "." use the injection's dparent.
# ============================================================================

sub getpath {
    my ($store, $path_in, $inj) = @_;

    # Coerce path into a parts list. Anything else returns NONE.
    my @parts;
    if (islist($path_in)) {
        @parts = @$path_in;
    }
    elsif (defined $path_in && !ref($path_in) && !is_jbool($path_in) && !is_jnull($path_in)) {
        if (_is_number_sv($path_in)) {
            @parts = (strkey($path_in));
        }
        elsif ("$path_in" eq '') {
            @parts = ('');
        }
        else {
            @parts = split /\./, "$path_in", -1;
        }
    }
    else {
        return NONE();
    }

    my $val = $store;
    my $base = defined $inj ? $inj->{base} : undef;
    my $src = defined $base ? getprop($store, $base, $store) : $store;
    my $numparts = scalar @parts;
    my $dparent = defined $inj ? $inj->{dparent} : undef;

    if (!defined $path_in || !defined $store
        || ($numparts == 1 && $parts[0] eq S_MT))
    {
        $val = $src;
    }
    elsif ($numparts > 0) {
        # Single-part lookup may hit a function.
        if ($numparts == 1) {
            $val = getprop($store, $parts[0]);
        }
        if (!isfunc($val)) {
            $val = $src;
            # Meta-path syntax on first part.
            if (defined $inj && $inj->{meta} && $parts[0] =~ $R_META_PATH) {
                my ($name, $sym, $rest) = ($1, $2, $3);
                $val = getprop($inj->{meta}, $name);
                $parts[0] = $rest;
            }
            my $dpath = defined $inj ? $inj->{dpath} : undef;
            for (my $pI = 0; defined $val && !is_none($val) && $pI < $numparts; $pI++) {
                my $part = $parts[$pI];
                if (defined $inj && defined $part && $part eq S_DKEY) {
                    $part = $inj->{key};
                }
                elsif (defined $inj && defined $part && index($part, '$GET:') == 0) {
                    my $sub = substr($part, 5, length($part) - 6);
                    $part = stringify(getpath($src, $sub));
                }
                elsif (defined $inj && defined $part && index($part, '$REF:') == 0) {
                    my $sub = substr($part, 5, length($part) - 6);
                    $part = stringify(getpath(getprop($store, S_DSPEC), $sub));
                }
                elsif (defined $inj && defined $part && index($part, '$META:') == 0) {
                    my $sub = substr($part, 6, length($part) - 7);
                    $part = stringify(getpath($inj->{meta}, $sub));
                }
                $part = '' unless defined $part;
                $part =~ s/\$\$/\$/g;
                if ($part eq S_MT) {
                    my $ascends = 0;
                    while ($pI + 1 < $numparts && $parts[$pI + 1] eq S_MT) {
                        $ascends++;
                        $pI++;
                    }
                    if (defined $inj && $ascends > 0) {
                        $ascends-- if $pI == $#parts;
                        if ($ascends == 0) { $val = $dparent }
                        else {
                            my @dp = islist($dpath) ? @$dpath : ();
                            my $cut = @dp - $ascends;
                            $cut = 0 if $cut < 0;
                            my @full = @dp[0 .. $cut - 1];
                            push @full, @parts[$pI + 1 .. $#parts] if $pI + 1 <= $#parts;
                            if ($ascends <= scalar @dp) {
                                $val = getpath($store, \@full);
                            }
                            else { $val = NONE() }
                            last;
                        }
                    }
                    else {
                        $val = $dparent;
                    }
                }
                else {
                    $val = getprop($val, $part);
                }
            }
        }
    }

    # Optional handler callback.
    if (defined $inj && defined $inj->{handler} && isfunc($inj->{handler})) {
        my $ref = pathify($path_in);
        $val = $inj->{handler}->($inj, $val, $ref, $store);
    }
    return $val;
}

# ============================================================================
# Injection — recursive state for inject / transform / validate / select.
# Modelled as a plain hashref (not a Perl class) to keep the port lean; the
# canonical TS Injection methods (`child`, `descend`, `setval`) appear as
# helper functions that take the inj hashref as their first argument.
# ============================================================================

# Construct a root Injection bound to a value and its synthetic parent.
sub _new_injection {
    my ($val, $parent) = @_;
    my $meta = _mkmap();
    $meta->{'__d'} = 0;
    return {
        mode    => M_VAL,
        full    => 0,
        keyI    => 0,
        keys    => [S_DTOP],
        key     => S_DTOP,
        val     => $val,
        parent  => $parent,
        path    => [S_DTOP],
        nodes   => [$parent],
        handler => \&_injecthandler,
        errs    => [],
        meta    => $meta,
        dparent => $NONE,
        dpath   => [S_DTOP],
        base    => S_DTOP,
    };
}

# child(keyI, keys): build a child injection for the next descent step.
sub _inj_child {
    my ($inj, $keyI, $keys) = @_;
    my $key  = strkey($keys->[$keyI]);
    my $val  = $inj->{val};
    my $cinj = _new_injection(getprop($val, $key), $val);
    $cinj->{keyI} = $keyI;
    $cinj->{keys} = $keys;
    $cinj->{key}  = $key;
    $cinj->{path}  = [ @{ $inj->{path} || [] }, $key ];
    $cinj->{nodes} = [ @{ $inj->{nodes} || [] }, $val ];
    $cinj->{mode}    = $inj->{mode};
    $cinj->{handler} = $inj->{handler};
    $cinj->{modify}  = $inj->{modify};
    $cinj->{base}    = $inj->{base};
    $cinj->{meta}    = $inj->{meta};
    $cinj->{errs}    = $inj->{errs};
    $cinj->{prior}   = $inj;
    $cinj->{dpath}   = [ @{ $inj->{dpath} || [] } ];
    $cinj->{dparent} = $inj->{dparent};
    return $cinj;
}

# descend(): step into the current node. dparent walks down by parentkey,
# dpath grows or contracts past synthetic $:KEY markers (TS canonical).
sub _inj_descend {
    my ($inj) = @_;
    $inj->{meta}{'__d'} = ($inj->{meta}{'__d'} // 0) + 1;
    my $parentkey;
    my $plen = scalar @{ $inj->{path} || [] };
    if ($plen >= 2) { $parentkey = $inj->{path}[ $plen - 2 ] }
    if (is_none($inj->{dparent})) {
        # No data: still grow dpath so relative paths line up with path.
        if (defined $inj->{dpath} && scalar(@{ $inj->{dpath} }) > 1 && defined $parentkey) {
            push @{ $inj->{dpath} }, $parentkey;
        }
    }
    elsif (defined $parentkey) {
        $inj->{dparent} = getprop($inj->{dparent}, $parentkey);
        my $last = (scalar @{ $inj->{dpath} || [] }) > 0
            ? $inj->{dpath}[ scalar(@{ $inj->{dpath} }) - 1 ]
            : '';
        if (defined $last && $last eq '$:' . $parentkey) {
            pop @{ $inj->{dpath} };
        }
        else {
            push @{ $inj->{dpath} }, $parentkey;
        }
    }
    return $inj->{dparent};
}

# setval(val, ancestor?): write a value into the parent (or a higher
# ancestor when ancestor>=2). NONE / SKIP / DELETE delete the slot.
sub _inj_setval {
    my ($inj, $val, $ancestor) = @_;
    my $target;
    my $tkey;
    if (!defined $ancestor || $ancestor < 2) {
        $target = $inj->{parent};
        $tkey   = $inj->{key};
    }
    else {
        my $nlen = scalar @{ $inj->{nodes} || [] };
        my $plen = scalar @{ $inj->{path}  || [] };
        return $inj->{parent} if $ancestor > $nlen || $ancestor > $plen;
        $target = $inj->{nodes}[ $nlen - $ancestor ];
        $tkey   = $inj->{path}[  $plen - $ancestor ];
    }
    if (is_none($val)) { delprop($target, $tkey) }
    else               { setprop($target, $tkey, $val) }
    return $target;
}

# Default inject handler: if the resolved value is a function and the
# reference looks like a `$NAME` command, invoke it; otherwise return val.
sub _injecthandler {
    my ($inj, $val, $ref, $store) = @_;
    my $iscmd = isfunc($val) && (is_none($ref) || (defined $ref && index($ref, S_DS) == 0));
    if ($iscmd) {
        return $val->($inj, $val, $ref, $store);
    }
    elsif ($inj->{mode} == M_VAL && $inj->{full}) {
        _inj_setval($inj, $val);
    }
    return $val;
}

# Resolve a string scalar that may contain backtick injection refs.
# Returns the resolved value (full injection) or the substituted string
# (partial injection). Mirrors TS _injectstr.
sub _injectstr {
    my ($val, $store, $inj) = @_;
    return '' unless defined $val && !ref($val);
    return '' if $val eq '';
    # Full injection: pattern is `($NAME or [^`]*)[0-9]*`. The optional
    # trailing digits are part of the *match* but NOT part of m[1] —
    # they're an ordering suffix on $NAME commands only. This matches
    # canonical TS R_INJECTION_FULL exactly.
    if ($val =~ /^`(\$[A-Z]+|[^`]*)[0-9]*`$/) {
        my $pathref = $1;
        $inj->{full} = 1 if defined $inj;
        if (length($pathref) > 3) {
            $pathref =~ s/\$BT/`/g;
            $pathref =~ s/\$DS/\$/g;
        }
        return getpath($store, $pathref, $inj);
    }
    return $val if index($val, '`') == -1;
    $inj->{full} = 0 if defined $inj;
    my $out = $val;
    $out =~ s{`([^`]+)`}{
        my $ref = $1;
        if (length($ref) > 3) {
            $ref =~ s/\$BT/`/g;
            $ref =~ s/\$DS/\$/g;
        }
        $inj->{full} = 0 if defined $inj;
        my $found = getpath($store, $ref, $inj);
        if (is_none($found))                            { '' }
        elsif (!ref $found && _is_string_sv($found))    { $found }
        elsif (is_jnull($found))                        { 'null' }
        elsif (is_jbool($found))                        { $$found ? 'true' : 'false' }
        elsif (isnode($found))                          { _stringify_inner($found, 0) }
        elsif (!ref $found && _is_number_sv($found))    { _format_number($found) }
        else                                             { stringify($found) }
    }ge;
    if (defined $inj && isfunc($inj->{handler})) {
        $inj->{full} = 1;
        $out = $inj->{handler}->($inj, $out, $val, $store);
    }
    return $out;
}

# Recursive inject. Walks $val, performing 3-phase key injection on each
# child of a node, or full / partial string injection on a scalar.
sub inject {
    my ($val, $store, $injdef) = @_;
    my $inj;
    if (!defined $injdef || !defined $injdef->{mode}) {
        my $vp = _mkmap();
        $vp->{ S_DTOP() } = $val;
        $inj = _new_injection($val, $vp);
        $inj->{dparent} = $store;
        $inj->{errs}    = getprop($store, S_DERRS, []);
        $inj->{meta}{'__d'} = 0;
        if (defined $injdef) {
            $inj->{modify}  = $injdef->{modify}  if defined $injdef->{modify};
            $inj->{extra}   = $injdef->{extra}   if defined $injdef->{extra};
            $inj->{meta}    = $injdef->{meta}    if defined $injdef->{meta};
            $inj->{handler} = $injdef->{handler} if defined $injdef->{handler};
        }
    }
    else {
        $inj = $injdef;
    }
    _inj_descend($inj);

    if (isnode($val)) {
        my @nodekeys;
        if (ismap($val)) {
            my @rawk = _map_keys($val);
            my @raw  = sort @rawk;
            my @plain   = grep { index($_, S_DS) < 0 } @raw;
            my @cmd     = grep { index($_, S_DS) >= 0 } @raw;
            @nodekeys = (@plain, @cmd);
        }
        else {
            @nodekeys = map { "$_" } 0 .. $#$val;
        }
        my $nkI = 0;
        while ($nkI < scalar @nodekeys) {
            my $childinj = _inj_child($inj, $nkI, [@nodekeys]);
            my $nodekey  = $childinj->{key};
            $childinj->{mode} = M_KEYPRE;
            my $prekey = _injectstr($nodekey, $store, $childinj);
            $nkI = $childinj->{keyI};
            @nodekeys = @{ $childinj->{keys} };
            if (!is_none($prekey)) {
                $childinj->{val}  = getprop($val, $prekey);
                $childinj->{mode} = M_VAL;
                inject($childinj->{val}, $store, $childinj);
                $nkI = $childinj->{keyI};
                @nodekeys = @{ $childinj->{keys} };
                $childinj->{mode} = M_KEYPOST;
                _injectstr($nodekey, $store, $childinj);
                $nkI = $childinj->{keyI};
                @nodekeys = @{ $childinj->{keys} };
            }
            $nkI++;
        }
    }
    elsif (defined $val && !ref($val) && _is_string_sv($val)) {
        $inj->{mode} = M_VAL;
        $val = _injectstr($val, $store, $inj);
        if (!(is_sentinel($val) && (_map_keys($val))[0] eq '`$SKIP`')) {
            _inj_setval($inj, $val);
        }
    }

    if ($inj->{modify} && !(is_sentinel($val) && (_map_keys($val))[0] eq '`$SKIP`')) {
        my $mkey = $inj->{key};
        my $mparent = $inj->{parent};
        my $mval = getprop($mparent, $mkey);
        $inj->{modify}->($mval, $mkey, $mparent, $inj, $store);
    }

    $inj->{val} = $val;
    return _lookup($inj->{parent}, S_DTOP);
}

# ============================================================================
# Builder helpers: jm = JSON-map literal, jt = JSON-list literal.
# Both produce insertion-ordered map / list structures from Perl args.
# ============================================================================

sub jm {
    my $m = _mkmap();
    for (my $i = 0; $i < @_; $i += 2) {
        my $k = $_[$i];
        my $v = $_[ $i + 1 ];
        $m->{$k} = $v;
    }
    return $m;
}

sub jt {
    return [@_];
}

# ============================================================================
# checkPlacement / injectorArgs / injectChild — helpers used by custom
# injectors (mirrors TS exports).
# ============================================================================

# Placement names for error messages (a key-mode is "key", value-mode "value").
our %PLACEMENT = (
    M_VAL()     => 'value',
    M_KEYPRE()  => S_key,
    M_KEYPOST() => S_key,
);

sub checkPlacement {
    my ($modes, $name, $parent_types, $inj) = @_;
    # modes can be a single mode bitmask. parent_types is a type-flag mask.
    if (!($inj->{mode} & $modes)) {
        push @{ $inj->{errs} }, '$' . $name . ': invalid placement as '
            . ($PLACEMENT{ $inj->{mode} } // 'unknown') . ', expected: '
            . CORE::join(',', map { $PLACEMENT{$_} // '?' } grep { $modes & $_ } (M_KEYPRE, M_KEYPOST, M_VAL))
            . '.';
        return 0;
    }
    if ($parent_types) {
        my $ptype = typify($inj->{parent});
        if (!($ptype & $parent_types)) {
            push @{ $inj->{errs} }, '$' . $name . ': invalid placement in parent '
                . typename($ptype) . ', expected: ' . typename($parent_types) . '.';
            return 0;
        }
    }
    return 1;
}

sub injectorArgs {
    my ($types, $args) = @_;
    return (NONE(), @$args) unless islist($args);
    my @out;
    for (my $i = 0; $i < @$types; $i++) {
        my $expected = $types->[$i];
        my $arg = $args->[$i];
        my $atype = typify($arg);
        if ($expected != T_any && !($atype & $expected)) {
            return (
                'invalid argument: ' . stringify($arg, 22) . ' (' . typename($atype)
                    . ' at position ' . ($i + 1) . ') is not of type: ' . typename($expected) . '.',
                @$args,
            );
        }
        push @out, $arg;
    }
    return (NONE(), @out);
}

sub injectChild {
    my ($child, $store, $inj) = @_;
    my $cinj = $inj;
    if (defined $inj->{prior}) {
        if (defined $inj->{prior}{prior}) {
            $cinj = _inj_child($inj->{prior}{prior}, $inj->{prior}{keyI}, $inj->{prior}{keys});
            $cinj->{val} = $child;
            setprop($cinj->{parent}, $inj->{prior}{key}, $child);
        }
        else {
            $cinj = _inj_child($inj->{prior}, $inj->{keyI}, $inj->{keys});
            $cinj->{val} = $child;
            setprop($cinj->{parent}, $inj->{key}, $child);
        }
    }
    inject($child, $store, $cinj);
    return $cinj;
}

# ============================================================================
# Transform commands (11)
# ============================================================================

sub transform_DELETE {
    my ($inj) = @_;
    _inj_setval($inj, NONE());
    return NONE();
}

sub transform_COPY {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless checkPlacement(M_VAL, 'COPY', T_any, $inj);
    my $out = _lookup($inj->{dparent}, $inj->{key});
    _inj_setval($inj, $out);
    return $out;
}

sub transform_KEY {
    my ($inj) = @_;
    return NONE() if $inj->{mode} != M_VAL;
    my $parent = $inj->{parent};
    my $keyspec = _lookup($parent, S_BKEY);
    if (!is_none($keyspec)) {
        delprop($parent, S_BKEY);
        return getprop($inj->{dparent}, $keyspec);
    }
    my $anno = _lookup($parent, S_BANNO);
    my $k = _lookup($anno, S_KEY);
    if (!is_none($k)) { return $k }
    return getelem($inj->{path}, -2);
}

sub transform_META {
    my ($inj) = @_;
    delprop($inj->{parent}, S_DMETA);
    return NONE();
}

sub transform_ANNO {
    my ($inj) = @_;
    delprop($inj->{parent}, S_BANNO);
    return NONE();
}

sub transform_MERGE {
    my ($inj) = @_;
    my $mode   = $inj->{mode};
    my $key    = $inj->{key};
    my $parent = $inj->{parent};
    my $out    = NONE();
    if ($mode == M_KEYPRE)  { $out = $key }
    elsif ($mode == M_KEYPOST) {
        $out = $key;
        my $args = getprop($parent, $key);
        $args = islist($args) ? $args : [$args];
        _inj_setval($inj, NONE());
        my $merge_list = flatten([[$parent], $args, [clone($parent)]]);
        merge($merge_list);
    }
    return $out;
}

sub transform_EACH {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless checkPlacement(M_VAL, 'EACH', T_list, $inj);
    slice($inj->{keys}, 0, 1, 1);
    my $rest = slice($inj->{parent}, 1);
    my ($err, $srcpath, $child) = injectorArgs([T_string, T_any], $rest);
    if (!is_none($err)) {
        push @{ $inj->{errs} }, '$EACH: ' . $err;
        return NONE();
    }
    my $srcstore = getprop($store, $inj->{base}, $store);
    my $src = getpath($srcstore, $srcpath, $inj);
    my $srctype = typify($src);
    my $tcur = [];
    my $tval = [];
    my $tkey = getelem($inj->{path}, -2);
    my $target = getelem(
        $inj->{nodes}, -2,
        sub { getelem($inj->{nodes}, -1) },
    );
    if ($srctype & T_list) {
        $tval = items($src, sub { clone($child) });
    }
    elsif ($srctype & T_map) {
        $tval = items($src, sub {
            my ($pair) = @_;
            my $ann = _mkmap();
            $ann->{ S_BANNO() } = jm('KEY', $pair->[0]);
            merge([clone($child), $ann], 1);
        });
    }
    my $rval = [];
    if (size($tval) > 0) {
        $tcur = (!defined $src || is_none($src)) ? NONE() : items($src, sub { $_[0]->[1] });
        my $ckey = getelem($inj->{path}, -2);
        my $tpath = slice($inj->{path}, -1);
        my $dpath = flatten([S_DTOP, [split /\./, "$srcpath", -1], '$:' . $ckey]);
        my $tcurmap = jm($ckey, $tcur);
        if (size($tpath) > 1) {
            my $pkey = getelem($inj->{path}, -3, S_DTOP);
            $tcurmap = jm($pkey, $tcurmap);
            push @$dpath, '$:' . $pkey;
        }
        my $tinj = _inj_child($inj, 0, [$ckey]);
        $tinj->{path} = $tpath;
        $tinj->{nodes} = slice($inj->{nodes}, -1);
        $tinj->{parent} = getelem($tinj->{nodes}, -1);
        setprop($tinj->{parent}, $ckey, $tval);
        $tinj->{val} = $tval;
        $tinj->{dpath} = $dpath;
        $tinj->{dparent} = $tcurmap;
        inject($tval, $store, $tinj);
        $rval = $tinj->{val};
    }
    setprop($target, $tkey, $rval);
    return getelem($rval, 0);
}

sub transform_PACK {
    my ($inj, $val, $ref, $store) = @_;
    my $key    = $inj->{key};
    my $path   = $inj->{path};
    my $parent = $inj->{parent};
    my $nodes  = $inj->{nodes};
    return NONE() unless checkPlacement(M_KEYPRE, 'EACH', T_map, $inj);
    my $args = getprop($parent, $key);
    my ($err, $srcpath, $origchildspec) = injectorArgs([T_string, T_any], $args);
    if (!is_none($err)) {
        push @{ $inj->{errs} }, '$EACH: ' . $err;
        return NONE();
    }
    my $tkey = getelem($path, -2);
    my $pathsize = size($path);
    my $target = getelem(
        $nodes, $pathsize - 2,
        sub { getelem($nodes, $pathsize - 1) },
    );
    my $srcstore = getprop($store, $inj->{base}, $store);
    my $src = getpath($srcstore, $srcpath, $inj);
    if (!islist($src)) {
        if (ismap($src)) {
            $src = items($src, sub {
                my ($item) = @_;
                setprop($item->[1], S_BANNO, jm('KEY', $item->[0]));
                $item->[1];
            });
        }
        else { $src = NONE() }
    }
    return NONE() if is_none($src) || !defined $src;
    my $keypath = getprop($origchildspec, S_BKEY);
    my $childspec = delprop($origchildspec, S_BKEY);
    my $child = getprop($childspec, S_BVAL, $childspec);
    my $tval = _mkmap();
    items($src, sub {
        my ($item) = @_;
        my ($srckey, $srcnode) = ($item->[0], $item->[1]);
        my $kk = $srckey;
        if (!is_none($keypath)) {
            if (index($keypath, '`') == 0) {
                my $tmap = jm( S_DTOP, $srcnode );
                my $mstore = merge([_mkmap(), $store, $tmap], 1);
                $kk = inject($keypath, $mstore);
            }
            else {
                $kk = getpath($srcnode, $keypath, $inj);
            }
        }
        my $tchild = clone($child);
        setprop($tval, $kk, $tchild);
        my $anno = getprop($srcnode, S_BANNO);
        if (is_none($anno)) { delprop($tchild, S_BANNO) }
        else                { setprop($tchild, S_BANNO, $anno) }
    });
    my $rval = _mkmap();
    if (!isempty($tval)) {
        my $tsrc = _mkmap();
        for (my $i = 0; $i < @$src; $i++) {
            my $n = $src->[$i];
            my $kn;
            if (is_none($keypath)) { $kn = $i }
            elsif (index($keypath, '`') == 0) {
                my $tmap = jm( S_DTOP, $n );
                my $mstore = merge([_mkmap(), $store, $tmap], 1);
                $kn = inject($keypath, $mstore);
            }
            else { $kn = getpath($n, $keypath, $inj) }
            setprop($tsrc, $kn, $n);
        }
        my $tpath = slice($inj->{path}, -1);
        my $ckey = getelem($inj->{path}, -2);
        my $dpath = flatten([S_DTOP, [split /\./, "$srcpath", -1], '$:' . $ckey]);
        my $tcur = jm($ckey, $tsrc);
        if (size($tpath) > 1) {
            my $pkey = getelem($inj->{path}, -3, S_DTOP);
            $tcur = jm($pkey, $tcur);
            push @$dpath, '$:' . $pkey;
        }
        my $tinj = _inj_child($inj, 0, [$ckey]);
        $tinj->{path} = $tpath;
        $tinj->{nodes} = slice($inj->{nodes}, -1);
        $tinj->{parent} = getelem($tinj->{nodes}, -1);
        $tinj->{val} = $tval;
        $tinj->{dpath} = $dpath;
        $tinj->{dparent} = $tcur;
        inject($tval, $store, $tinj);
        $rval = $tinj->{val};
    }
    setprop($target, $tkey, $rval);
    return NONE();
}

sub transform_REF {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() if $inj->{mode} != M_VAL;
    my $nodes = $inj->{nodes};
    my $refpath = _lookup($inj->{parent}, 1);
    $inj->{keyI} = size($inj->{keys});
    my $specfn = getprop($store, S_DSPEC);
    my $spec = isfunc($specfn) ? $specfn->() : $specfn;
    my $dpath = slice($inj->{path}, 1);
    my $sub_inj = {
        dpath   => $dpath,
        dparent => getpath($spec, $dpath),
        base    => S_DTOP,
        meta    => $inj->{meta},
    };
    my $resolved = getpath($spec, $refpath, $sub_inj);
    my $hasSubRef = 0;
    if (isnode($resolved)) {
        walk($resolved, sub {
            my ($k, $v) = @_;
            if (defined $v && !ref($v) && $v eq '`$REF`') { $hasSubRef = 1 }
            return $v;
        });
    }
    my $tref = clone($resolved);
    my $cpath = slice($inj->{path}, -3);
    my $tpath = slice($inj->{path}, -1);
    my $tcur = getpath($store, $cpath);
    my $tval = getpath($store, $tpath);
    my $rval = NONE();
    if (!$hasSubRef || !is_none($tval)) {
        my $tinj = _inj_child($inj, 0, [getelem($tpath, -1)]);
        $tinj->{path}    = $tpath;
        $tinj->{nodes}   = slice($inj->{nodes}, -1);
        $tinj->{parent}  = getelem($nodes, -2);
        $tinj->{val}     = $tref;
        $tinj->{dpath}   = flatten([$cpath]);
        $tinj->{dparent} = $tcur;
        inject($tref, $store, $tinj);
        $rval = $tinj->{val};
    }
    my $grandparent = _inj_setval($inj, $rval, 2);
    if (islist($grandparent) && $inj->{prior}) {
        $inj->{prior}{keyI}--;
    }
    return $val;
}

our %FORMATTER = (
    identity => sub { $_[1] },
    upper    => sub {
        my (undef, $v) = @_;
        return $v if isnode($v);
        my $s = defined $v ? "$v" : '';
        return uc $s;
    },
    lower    => sub {
        my (undef, $v) = @_;
        return $v if isnode($v);
        my $s = defined $v ? "$v" : '';
        return lc $s;
    },
    string   => sub {
        my (undef, $v) = @_;
        return $v if isnode($v);
        return defined $v ? "$v" : '';
    },
    number   => sub {
        my (undef, $v) = @_;
        return $v if isnode($v);
        my $n = defined $v && looks_like_number($v) ? 0 + $v : 0;
        return $n;
    },
    integer  => sub {
        my (undef, $v) = @_;
        return $v if isnode($v);
        my $n = defined $v && looks_like_number($v) ? int(0 + $v) : 0;
        return $n;
    },
    concat   => sub {
        my ($k, $v) = @_;
        if (!defined $k && islist($v)) {
            my $out = '';
            for my $e (@$v) {
                $out .= isnode($e) ? '' : (defined $e ? "$e" : '');
            }
            return $out;
        }
        return $v;
    },
);

sub transform_FORMAT {
    my ($inj, $val, $ref, $store) = @_;
    slice($inj->{keys}, 0, 1, 1);
    return NONE() if $inj->{mode} != M_VAL;
    my $name  = _lookup($inj->{parent}, 1);
    my $child = _lookup($inj->{parent}, 2);
    my $tkey = getelem($inj->{path}, -2);
    my $target = getelem(
        $inj->{nodes}, -2,
        sub { getelem($inj->{nodes}, -1) },
    );
    my $cinj = injectChild($child, $store, $inj);
    my $resolved = $cinj->{val};
    my $formatter = (typify($name) & T_function) ? $name : $FORMATTER{$name // ''};
    if (!defined $formatter) {
        push @{ $inj->{errs} }, '$FORMAT: unknown format: ' . (defined $name ? $name : '') . '.';
        return NONE();
    }
    my $out = walk($resolved, $formatter);
    setprop($target, $tkey, $out);
    return $out;
}

sub transform_APPLY {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless checkPlacement(M_VAL, 'APPLY', T_list, $inj);
    my $rest = slice($inj->{parent}, 1);
    my ($err, $apply, $child) = injectorArgs([T_function, T_any], $rest);
    if (!is_none($err)) {
        push @{ $inj->{errs} }, '$APPLY: ' . $err;
        return NONE();
    }
    my $tkey = getelem($inj->{path}, -2);
    my $target = getelem(
        $inj->{nodes}, -2,
        sub { getelem($inj->{nodes}, -1) },
    );
    my $cinj = injectChild($child, $store, $inj);
    my $resolved = $cinj->{val};
    my $out = $apply->($resolved, $store, $cinj);
    setprop($target, $tkey, $out);
    return $out;
}

# ============================================================================
# Transform — top-level wrapper.
# ============================================================================

sub transform {
    my ($data, $spec, $injdef) = @_;
    my $origspec = $spec;
    $spec = clone($origspec);
    my $extra = defined $injdef ? $injdef->{extra} : undef;
    my $collect = defined $injdef && defined $injdef->{errs};
    my $errs = ($injdef && $injdef->{errs}) ? $injdef->{errs} : [];
    my $extraTransforms = _mkmap();
    my $extraData;
    if (defined $extra) {
        $extraData = _mkmap();
        for my $pair (@{ items($extra) }) {
            my ($k, $v) = @$pair;
            if (index($k, S_DS) == 0) {
                $extraTransforms->{$k} = $v;
            }
            else {
                $extraData->{$k} = $v;
            }
        }
    }
    my $dataClone = merge([
        (defined $extraData && !isempty($extraData)) ? clone($extraData) : NONE(),
        clone($data),
    ]);
    my $base_store = jm(
        S_DTOP, $dataClone,
        '$SPEC', sub { $origspec },
        '$BT',   sub { S_BT },
        '$DS',   sub { S_DS },
        '$WHEN', sub {
            my @t = gmtime;
            return sprintf('%04d-%02d-%02dT%02d:%02d:%02d.000Z',
                $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
        },
        '$DELETE', \&transform_DELETE,
        '$COPY',   \&transform_COPY,
        '$KEY',    \&transform_KEY,
        '$META',   \&transform_META,
        '$ANNO',   \&transform_ANNO,
        '$MERGE',  \&transform_MERGE,
        '$EACH',   \&transform_EACH,
        '$PACK',   \&transform_PACK,
        '$REF',    \&transform_REF,
        '$FORMAT', \&transform_FORMAT,
        '$APPLY',  \&transform_APPLY,
    );
    my $errs_map = jm(S_DERRS, $errs);
    my $store = merge([$base_store, $extraTransforms, $errs_map], 1);
    my $out = inject($spec, $store, $injdef);
    if (size($errs) > 0 && !$collect) {
        die CORE::join(' | ', map { defined $_ ? "$_" : '' } @$errs);
    }
    return $out;
}

# ============================================================================
# Validate checkers (15)
# ============================================================================

sub _invalid_type_msg {
    my ($path, $needtype, $vt, $v, $whence) = @_;
    # Canonical: `null == v` (null OR undefined) renders as "no value", with no
    # "typename: " prefix. Absent (NONE) and JSON null both count.
    my $novalue = (!defined $v || is_none($v) || is_jnull($v));
    my $vs = $novalue ? 'no value' : stringify($v);
    my $field = (size($path) > 1) ? ('field ' . pathify($path, 1) . ' to be ') : '';
    my $extra = $novalue ? '' : (typename($vt) . S_VIZ);
    return 'Expected ' . $field . $needtype . ', but found ' . $extra . $vs . '.';
}

sub validate_STRING {
    my ($inj) = @_;
    my $out = _lookup($inj->{dparent}, $inj->{key});
    my $t = typify($out);
    if (!($t & T_string)) {
        push @{ $inj->{errs} }, _invalid_type_msg($inj->{path}, S_string, $t, $out, 'V1010');
        return NONE();
    }
    if (defined $out && !ref($out) && $out eq '') {
        push @{ $inj->{errs} }, 'Empty string at ' . pathify($inj->{path}, 1);
        return NONE();
    }
    return $out;
}

sub validate_TYPE {
    my ($inj, $val, $ref) = @_;
    my $tname = lc substr($ref, 1);
    my %TNAME_TO_BIT = (
        S_nil()      => T_noval,
        S_boolean()  => T_boolean,
        S_decimal()  => T_decimal,
        S_integer()  => T_integer,
        S_number()   => T_number,
        S_string()   => T_string,
        S_function() => T_function,
        S_symbol()   => T_symbol,
        S_null()     => T_null,
        S_list()     => T_list,
        S_map()      => T_map,
        S_instance() => T_instance,
        S_scalar()   => T_scalar,
        S_node()     => T_node,
        S_any()      => T_any,
    );
    my $typev = $TNAME_TO_BIT{$tname} // 0;
    # Special "number" matches integers & decimals.
    if ($tname eq S_number) {
        $typev = T_integer | T_decimal | T_number;
    }
    my $out = _lookup($inj->{dparent}, $inj->{key});
    my $t = typify($out);
    if (!($t & $typev)) {
        push @{ $inj->{errs} }, _invalid_type_msg($inj->{path}, $tname, $t, $out, 'V1001');
        return NONE();
    }
    return $out;
}

sub validate_ANY {
    my ($inj) = @_;
    return _lookup($inj->{dparent}, $inj->{key});
}

sub validate_CHILD {
    my ($inj) = @_;
    my $mode = $inj->{mode};
    my $key = $inj->{key};
    my $parent = $inj->{parent};
    my $keys = $inj->{keys};
    my $path = $inj->{path};
    if ($mode == M_KEYPRE) {
        my $childtm = getprop($parent, $key);
        my $pkey = getelem($path, -2);
        my $tval = getprop($inj->{dparent}, $pkey);
        if (!defined $tval || is_none($tval)) { $tval = _mkmap() }
        elsif (!ismap($tval)) {
            push @{ $inj->{errs} }, _invalid_type_msg(slice($inj->{path}, -1), S_object, typify($tval), $tval, 'V0220');
            return NONE();
        }
        my $ckeys = keysof($tval);
        for my $ckey (@$ckeys) {
            setprop($parent, $ckey, clone($childtm));
            push @$keys, $ckey;
        }
        _inj_setval($inj, NONE());
        return NONE();
    }
    if ($mode == M_VAL) {
        if (!islist($parent)) {
            push @{ $inj->{errs} }, 'Invalid $CHILD as value';
            return NONE();
        }
        my $childtm = _lookup($parent, 1);
        if (is_none($inj->{dparent})) {
            slice($parent, 0, 0, 1);
            return NONE();
        }
        if (!islist($inj->{dparent})) {
            my $msg = _invalid_type_msg(slice($inj->{path}, -1), S_list, typify($inj->{dparent}), $inj->{dparent}, 'V0230');
            push @{ $inj->{errs} }, $msg;
            $inj->{keyI} = size($parent);
            return $inj->{dparent};
        }
        items($inj->{dparent}, sub {
            my ($n) = @_;
            setprop($parent, $n->[0], clone($childtm));
        });
        slice($parent, 0, scalar @{ $inj->{dparent} }, 1);
        $inj->{keyI} = 0;
        return getprop($inj->{dparent}, 0);
    }
    return NONE();
}

sub validate_ONE {
    my ($inj, $val, $ref, $store) = @_;
    my $mode = $inj->{mode};
    my $parent = $inj->{parent};
    my $keyI = $inj->{keyI};
    if ($mode == M_VAL) {
        if (!islist($parent) || $keyI != 0) {
            push @{ $inj->{errs} },
                'The $ONE validator at field ' . pathify($inj->{path}, 1, 1) .
                ' must be the first element of an array.';
            return;
        }
        $inj->{keyI} = size($inj->{keys});
        _inj_setval($inj, $inj->{dparent}, 2);
        $inj->{path} = slice($inj->{path}, -1);
        $inj->{key} = getelem($inj->{path}, -1);
        my $tvals = slice($parent, 1);
        if (size($tvals) == 0) {
            push @{ $inj->{errs} },
                'The $ONE validator at field ' . pathify($inj->{path}, 1, 1) .
                ' must have at least one argument.';
            return;
        }
        for my $tval (@$tvals) {
            my $terrs = [];
            my $vstore = merge([_mkmap(), $store], 1);
            $vstore->{ S_DTOP() } = $inj->{dparent};
            my $vcurrent = validate($inj->{dparent}, $tval, {
                extra => $vstore,
                errs  => $terrs,
                meta  => $inj->{meta},
            });
            _inj_setval($inj, $vcurrent, -2);
            return if size($terrs) == 0;
        }
        my $valdesc = CORE::join(', ', map { stringify($_) } @$tvals);
        $valdesc =~ s/`\$([A-Z]+)`/lc($1)/ge;
        push @{ $inj->{errs} }, _invalid_type_msg(
            $inj->{path},
            (size($tvals) > 1 ? 'one of ' : '') . $valdesc,
            typify($inj->{dparent}),
            $inj->{dparent},
            'V0210',
        );
    }
}

sub validate_EXACT {
    my ($inj) = @_;
    my $mode = $inj->{mode};
    my $parent = $inj->{parent};
    my $key = $inj->{key};
    my $keyI = $inj->{keyI};
    if ($mode == M_VAL) {
        if (!islist($parent) || $keyI != 0) {
            push @{ $inj->{errs} },
                'The $EXACT validator at field ' . pathify($inj->{path}, 1, 1) .
                ' must be the first element of an array.';
            return;
        }
        $inj->{keyI} = size($inj->{keys});
        _inj_setval($inj, $inj->{dparent}, 2);
        $inj->{path} = slice($inj->{path}, 0, -1);
        $inj->{key} = getelem($inj->{path}, -1);
        my $tvals = slice($parent, 1);
        if (size($tvals) == 0) {
            push @{ $inj->{errs} },
                'The $EXACT validator at field ' . pathify($inj->{path}, 1, 1) .
                ' must have at least one argument.';
            return;
        }
        my $currentstr;
        for my $tval (@$tvals) {
            my $exactmatch = _exact_eq($tval, $inj->{dparent});
            if (!$exactmatch && isnode($tval)) {
                $currentstr //= stringify($inj->{dparent});
                my $tvalstr = stringify($tval);
                $exactmatch = ($tvalstr eq $currentstr);
            }
            return if $exactmatch;
        }
        my $valdesc = CORE::join(', ', map { stringify($_) } @$tvals);
        $valdesc =~ s/`\$([A-Z]+)`/lc($1)/ge;
        push @{ $inj->{errs} }, _invalid_type_msg(
            $inj->{path},
            (size($inj->{path}) > 1 ? '' : 'value ') . 'exactly equal to ' .
                (size($tvals) == 1 ? '' : 'one of ') . $valdesc,
            typify($inj->{dparent}),
            $inj->{dparent},
            'V0110',
        );
    }
    else {
        delprop($parent, $key);
    }
}

sub _exact_eq {
    my ($a, $b) = @_;
    # NONE/undef: treat both forms as equivalent.
    my $a_na = !defined $a || is_none($a);
    my $b_na = !defined $b || is_none($b);
    return 1 if $a_na && $b_na;
    return 0 if $a_na || $b_na;
    return 1 if is_jnull($a) && is_jnull($b);
    return 0 if is_jnull($a) || is_jnull($b);
    if (is_jbool($a) && is_jbool($b)) { return $$a == $$b }
    return 0 if is_jbool($a) || is_jbool($b);
    if (!ref($a) && !ref($b)) {
        if (_is_number_sv($a) && _is_number_sv($b)) {
            return 0 + $a == 0 + $b;
        }
        return "$a" eq "$b";
    }
    return 0;
}

# Validation modify: runs after each child's inject pass.
sub _validation {
    my ($pval, $key, $parent, $inj) = @_;
    return if is_none($inj);
    return if is_sentinel($pval) && (_map_keys($pval))[0] eq '`$SKIP`';
    my $exact = getprop($inj->{meta}, S_BEXACT, $JFALSE);
    my $exact_bool = is_jbool($exact) ? !!$$exact : ($exact ? 1 : 0);
    my $cval = getprop($inj->{dparent}, $key);
    return if is_none($inj) || (!$exact_bool && is_none($cval));
    my $ptype = typify($pval);
    if (($ptype & T_string) && defined $pval && !ref($pval) && index($pval, S_DS) >= 0) {
        return;
    }
    my $ctype = typify($cval);
    if ($ptype != $ctype && !is_none($pval)) {
        push @{ $inj->{errs} },
            _invalid_type_msg($inj->{path}, typename($ptype), $ctype, $cval, 'V0010');
        return;
    }
    if (ismap($cval)) {
        if (!ismap($pval)) {
            push @{ $inj->{errs} },
                _invalid_type_msg($inj->{path}, typename($ptype), $ctype, $cval, 'V0020');
            return;
        }
        my $ckeys = keysof($cval);
        my $pkeys = keysof($pval);
        # A map is open only if `$OPEN` is literally true; an absent flag (NONE,
        # which is itself truthy in Perl) leaves the map closed.
        my $open_flag = getprop($pval, '`$OPEN`');
        my $is_open = (is_jbool($open_flag) && ${$open_flag}) ? 1 : 0;
        if (size($pkeys) > 0 && !$is_open) {
            my @badkeys;
            for my $ck (@$ckeys) {
                if (is_none(_lookup($pval, $ck))) {
                    push @badkeys, $ck;
                }
            }
            if (@badkeys) {
                push @{ $inj->{errs} },
                    'Unexpected keys at field ' . pathify($inj->{path}, 1) . S_VIZ . CORE::join(', ', @badkeys);
            }
        }
        else {
            merge([$pval, $cval]);
            if (isnode($pval)) { delprop($pval, '`$OPEN`') }
        }
    }
    elsif (islist($cval)) {
        if (!islist($pval)) {
            push @{ $inj->{errs} },
                _invalid_type_msg($inj->{path}, typename($ptype), $ctype, $cval, 'V0030');
        }
    }
    elsif ($exact_bool) {
        my $eq = _exact_eq($cval, $pval);
        if (!$eq) {
            my $pathmsg = size($inj->{path}) > 1
                ? 'at field ' . pathify($inj->{path}, 1) . S_VIZ
                : S_MT;
            push @{ $inj->{errs} },
                'Value ' . $pathmsg . stringify($cval) . ' should equal ' . stringify($pval) . S_DT;
        }
    }
    else {
        setprop($parent, $key, $cval);
    }
    return;
}

sub _validatehandler {
    my ($inj, $val, $ref, $store) = @_;
    if (defined $ref && !ref($ref) && $ref =~ $R_META_PATH) {
        my ($name, $sym, $rest) = ($1, $2, $3);
        if ($sym eq '=') {
            _inj_setval($inj, [S_BEXACT, $val]);
        }
        else {
            _inj_setval($inj, $val);
        }
        $inj->{keyI} = -1;
        return SKIP();
    }
    return _injecthandler($inj, $val, $ref, $store);
}

sub validate {
    my ($data, $spec, $injdef) = @_;
    my $extra = defined $injdef ? $injdef->{extra} : undef;
    my $collect = defined $injdef && defined $injdef->{errs};
    my $errs = ($injdef && $injdef->{errs}) ? $injdef->{errs} : [];
    my $base = jm(
        '$DELETE', $JNULL,
        '$COPY',   $JNULL,
        '$KEY',    $JNULL,
        '$META',   $JNULL,
        '$MERGE',  $JNULL,
        '$EACH',   $JNULL,
        '$PACK',   $JNULL,
        '$STRING',   \&validate_STRING,
        '$NUMBER',   \&validate_TYPE,
        '$INTEGER',  \&validate_TYPE,
        '$DECIMAL',  \&validate_TYPE,
        '$BOOLEAN',  \&validate_TYPE,
        '$NULL',     \&validate_TYPE,
        '$NIL',      \&validate_TYPE,
        '$MAP',      \&validate_TYPE,
        '$LIST',     \&validate_TYPE,
        '$FUNCTION', \&validate_TYPE,
        '$INSTANCE', \&validate_TYPE,
        '$ANY',      \&validate_ANY,
        '$CHILD',    \&validate_CHILD,
        '$ONE',      \&validate_ONE,
        '$EXACT',    \&validate_EXACT,
    );
    my $errsmap = jm(S_DERRS, $errs);
    my $store = merge([$base, getdef($extra, _mkmap()), $errsmap], 1);
    my $meta = getprop($injdef, 'meta', _mkmap());
    setprop($meta, S_BEXACT, getprop($meta, S_BEXACT, $JFALSE));
    my $out = transform($data, $spec, {
        meta    => $meta,
        extra   => $store,
        modify  => \&_validation,
        handler => \&_validatehandler,
        errs    => $errs,
    });
    if (size($errs) > 0 && !$collect) {
        die CORE::join(' | ', map { defined $_ ? "$_" : '' } @$errs);
    }
    return $out;
}

# ============================================================================
# Select operators (4)
# ============================================================================

sub select_AND {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless $inj->{mode} == M_KEYPRE;
    my $terms = _lookup($inj->{parent}, $inj->{key});
    my $ppath = slice($inj->{path}, -1);
    my $point = getpath($store, $ppath);
    my $vstore = merge([_mkmap(), $store], 1);
    $vstore->{ S_DTOP() } = $point;
    for my $term (@$terms) {
        my $terrs = [];
        validate($point, $term, {
            extra => $vstore,
            errs  => $terrs,
            meta  => $inj->{meta},
        });
        if (size($terrs) != 0) {
            push @{ $inj->{errs} },
                'AND:' . pathify($ppath) . S_VIZ . stringify($point) .
                ' fail:' . stringify($terms);
        }
    }
    my $gkey = getelem($inj->{path}, -2);
    my $gp = getelem($inj->{nodes}, -2);
    setprop($gp, $gkey, $point);
    return NONE();
}

sub select_OR {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless $inj->{mode} == M_KEYPRE;
    my $terms = _lookup($inj->{parent}, $inj->{key});
    my $ppath = slice($inj->{path}, -1);
    my $point = getpath($store, $ppath);
    my $vstore = merge([_mkmap(), $store], 1);
    $vstore->{ S_DTOP() } = $point;
    for my $term (@$terms) {
        my $terrs = [];
        validate($point, $term, {
            extra => $vstore,
            errs  => $terrs,
            meta  => $inj->{meta},
        });
        if (size($terrs) == 0) {
            my $gkey = getelem($inj->{path}, -2);
            my $gp = getelem($inj->{nodes}, -2);
            setprop($gp, $gkey, $point);
            return NONE();
        }
    }
    push @{ $inj->{errs} },
        'OR:' . pathify($ppath) . S_VIZ . stringify($point) .
        ' fail:' . stringify($terms);
    return NONE();
}

sub select_NOT {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless $inj->{mode} == M_KEYPRE;
    my $term = _lookup($inj->{parent}, $inj->{key});
    my $ppath = slice($inj->{path}, -1);
    my $point = getpath($store, $ppath);
    my $vstore = merge([_mkmap(), $store], 1);
    $vstore->{ S_DTOP() } = $point;
    my $terrs = [];
    validate($point, $term, {
        extra => $vstore,
        errs  => $terrs,
        meta  => $inj->{meta},
    });
    if (size($terrs) == 0) {
        push @{ $inj->{errs} },
            'NOT:' . pathify($ppath) . S_VIZ . stringify($point) .
            ' fail:' . stringify($term);
    }
    my $gkey = getelem($inj->{path}, -2);
    my $gp = getelem($inj->{nodes}, -2);
    setprop($gp, $gkey, $point);
    return NONE();
}

sub select_CMP {
    my ($inj, $val, $ref, $store) = @_;
    return NONE() unless $inj->{mode} == M_KEYPRE;
    my $term = _lookup($inj->{parent}, $inj->{key});
    my $gkey = getelem($inj->{path}, -2);
    my $ppath = slice($inj->{path}, -1);
    my $point = getpath($store, $ppath);
    my $pass = 0;
    # NOTE: avoid numifying $point / $term via `0 + $x` — that mutates the
    # SV's IOK flag (so a string "123" becomes typify=integer afterwards).
    # We probe types via Scalar::Util::looks_like_number on a COPY.
    my $pc = $point;
    my $tc = $term;
    my $both_num = defined $point && defined $term
        && !ref($point) && !ref($term)
        && looks_like_number($pc) && looks_like_number($tc);
    if ($ref eq '$GT') {
        $pass = $both_num ? ((0 + $pc) > (0 + $tc))
              : (defined $point && defined $term && "$point" gt "$term");
    }
    elsif ($ref eq '$LT') {
        $pass = $both_num ? ((0 + $pc) < (0 + $tc))
              : (defined $point && defined $term && "$point" lt "$term");
    }
    elsif ($ref eq '$GTE') {
        $pass = $both_num ? ((0 + $pc) >= (0 + $tc))
              : (defined $point && defined $term && "$point" ge "$term");
    }
    elsif ($ref eq '$LTE') {
        $pass = $both_num ? ((0 + $pc) <= (0 + $tc))
              : (defined $point && defined $term && "$point" le "$term");
    }
    elsif ($ref eq '$LIKE') {
        my $s = stringify($point);
        $pass = (defined $term && $s =~ /$term/) ? 1 : 0;
    }
    if ($pass) {
        my $gp = getelem($inj->{nodes}, -2);
        setprop($gp, $gkey, $point);
    }
    else {
        push @{ $inj->{errs} },
            'CMP: ' . pathify($ppath) . S_VIZ . stringify($point) .
            ' fail:' . $ref . ' ' . stringify($term);
    }
    return NONE();
}

sub select {
    my ($children, $query) = @_;
    return [] unless isnode($children);
    if (ismap($children)) {
        $children = items($children, sub {
            my ($n) = @_;
            setprop($n->[1], S_DKEY, $n->[0]);
            return $n->[1];
        });
    }
    else {
        $children = items($children, sub {
            my ($n) = @_;
            setprop($n->[1], S_DKEY, int($n->[0]));
            return $n->[1];
        });
    }
    my $results = [];
    my $meta = _mkmap();
    $meta->{ S_BEXACT() } = $JTRUE;
    my $extra = jm(
        '$AND',  \&select_AND,
        '$OR',   \&select_OR,
        '$NOT',  \&select_NOT,
        '$GT',   \&select_CMP,
        '$LT',   \&select_CMP,
        '$GTE',  \&select_CMP,
        '$LTE',  \&select_CMP,
        '$LIKE', \&select_CMP,
    );
    my $q = clone($query);
    walk($q, sub {
        my ($k, $v) = @_;
        if (ismap($v)) {
            my $existing = getprop($v, '`$OPEN`', $JTRUE);
            setprop($v, '`$OPEN`', $existing);
        }
        return $v;
    });
    for my $child (@$children) {
        my $errs = [];
        my $injdef = {
            errs  => $errs,
            meta  => $meta,
            extra => $extra,
        };
        validate($child, clone($q), $injdef);
        if (size($errs) == 0) {
            push @$results, $child;
        }
    }
    return $results;
}

# ============================================================================
# Regex utility — uniform API across ports (see /REGEX.md). Perl's built-in
# regex handles the RE2 subset directly; these are thin wrappers so the
# canonical names exist for cross-port parity.
# ============================================================================

sub re_compile {
    my ($pattern, $flags) = @_;
    return $pattern if ref($pattern) eq 'Regexp';
    return $flags ? qr/(?$flags:$pattern)/ : qr/$pattern/;
}

sub re_test {
    my ($pattern, $input) = @_;
    return 0 unless defined $input;
    my $re = re_compile($pattern);
    return $input =~ $re ? 1 : 0;
}

# Single match. Returns [whole, $1, $2, ...] or undef. Mirrors JS String.match.
sub re_find {
    my ($pattern, $input) = @_;
    return unless defined $input;
    my $re = re_compile($pattern);
    if ($input =~ $re) {
        my $whole = substr($input, $-[0], $+[0] - $-[0]);
        my @caps;
        for (my $i = 1; $i < scalar @-; $i++) {
            push @caps, defined $-[$i]
                ? substr($input, $-[$i], $+[$i] - $-[$i])
                : undef;
        }
        return [ $whole, @caps ];
    }
    return;
}

# All non-overlapping left-to-right matches. Same shape as re_find per element.
sub re_find_all {
    my ($pattern, $input) = @_;
    return [] unless defined $input;
    my $re = re_compile($pattern);
    my @out;
    while ($input =~ /$re/g) {
        my $whole = substr($input, $-[0], $+[0] - $-[0]);
        my @caps;
        for (my $i = 1; $i < scalar @-; $i++) {
            push @caps, defined $-[$i]
                ? substr($input, $-[$i], $+[$i] - $-[$i])
                : undef;
        }
        push @out, [ $whole, @caps ];
        last if length($whole) == 0 && (pos($input) // 0) >= length($input);
    }
    return \@out;
}

# Replace every match. `replacement` is either a string (literal) or a coderef
# receiving the same array re_find returns.
sub re_replace {
    my ($pattern, $input, $replacement) = @_;
    return '' unless defined $input;
    my $re = re_compile($pattern);
    if (ref($replacement) eq 'CODE') {
        my $s = $input;
        $s =~ s{$re}{
            my $whole = substr($input, $-[0], $+[0] - $-[0]);
            my @caps;
            for (my $i = 1; $i < scalar @-; $i++) {
                push @caps, defined $-[$i]
                    ? substr($input, $-[$i], $+[$i] - $-[$i])
                    : undef;
            }
            $replacement->([ $whole, @caps ]);
        }ge;
        return $s;
    }
    my $s = $input;
    $s =~ s/$re/$replacement/g;
    return $s;
}

sub re_escape { return escre($_[0]) }

1;
