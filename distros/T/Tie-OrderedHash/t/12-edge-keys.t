use strict;
use warnings;
use Test::More;
use Tie::OrderedHash;

# Awkward key shapes. STORE does SvPV(key, klen) and feeds (kpv,klen)
# to hv_store_ent / newSVpvn, so binary-safe and length-explicit
# storage is the contract.

# ---- empty-string key ---------------------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{''} = 'empty-key value';
    ok(exists $h{''},                'empty-string key: exists');
    is($h{''}, 'empty-key value',    'empty-string key: round-trip');
    is_deeply([keys %h], [''],       'empty-string key: in keys list');
    is(scalar keys %h, 1,            'empty-string key: counted');
}

# ---- empty string vs "0" are distinct keys (perl hash semantics) --
{
    tie my %h, 'Tie::OrderedHash';
    $h{''}  = 'empty';
    $h{'0'} = 'zero-string';
    is(scalar keys %h, 2,            '"" and "0" are distinct keys');
    is($h{''},  'empty',             '"" key resolves correctly');
    is($h{'0'}, 'zero-string',       '"0" key resolves correctly');
}

# ---- binary key with embedded NULs --------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    my $k = "a\0b\0c";       # 5 bytes, two NULs in the middle
    $h{$k} = 'binary';
    ok(exists $h{$k},        'NUL-bearing key: exists');
    is($h{$k}, 'binary',     'NUL-bearing key: round-trip');
    is(scalar keys %h, 1,    'NUL-bearing key: counted');
    my @ks = keys %h;
    is(length $ks[0], 5,     'NUL-bearing key: length preserved (5 bytes)');
    is($ks[0], $k,           'NUL-bearing key: bytes match');
}

# ---- "a" vs "a\0b" must be distinct keys (length-aware storage) ---
{
    tie my %h, 'Tie::OrderedHash';
    $h{"a"}     = 'short';
    $h{"a\0b"}  = 'longer';
    is(scalar keys %h, 2,          'short vs NUL-prefix-of-larger are distinct');
    is($h{"a"},    'short',         'short key resolves');
    is($h{"a\0b"}, 'longer',        'NUL-bearing key resolves');
}

# ---- numeric keys auto-stringify ----------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{42}    = 'forty-two';
    $h{-7}    = 'minus seven';
    $h{0}     = 'zero';
    is($h{42},   'forty-two',    'numeric key 42');
    is($h{-7},   'minus seven',  'numeric key -7');
    is($h{0},    'zero',         'numeric key 0');
    is($h{'42'}, 'forty-two',    'numeric key reachable as string');
    is(scalar keys %h, 3,        'three numeric keys');
}

# ---- long key (4 KiB) ---------------------------------------------
{
    tie my %h, 'Tie::OrderedHash';
    my $k = 'k' x 4096;
    $h{$k} = 'value';
    is(length((keys %h)[0]), 4096, '4 KiB key length preserved');
    is($h{$k}, 'value',            '4 KiB key round-trip');
}

# ---- UTF-8 keys: same byte sequence resolves the same key ---------
# (Both perl and our XS layer ultimately key on the byte form.)
{
    tie my %h, 'Tie::OrderedHash';
    my $name = "Sn\x{C3}\x{A4}gel";    # "Snägel" as UTF-8 bytes
    $h{$name} = 'utf8 value';
    ok(exists $h{$name},   'UTF-8 key bytes: exists with same byte string');
    is($h{$name}, 'utf8 value', 'UTF-8 key bytes: round-trip');
}

# ---- delete preserves byte-distinct keys --------------------------
{
    tie my %h, 'Tie::OrderedHash';
    $h{"a\0b"} = 1;
    $h{"a"}    = 2;
    is(delete $h{"a"}, 2,        'delete short key');
    is(scalar keys %h, 1,        'NUL key still present');
    ok(exists $h{"a\0b"},        'NUL key still resolves after sibling delete');
    is($h{"a\0b"}, 1,            'NUL key value intact');
}

done_testing;
