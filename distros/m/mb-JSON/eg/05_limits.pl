######################################################################
# 05_limits.pl - mb::JSON safety limits example
#
# Usage: perl eg/05_limits.pl
#
# Two package variables tune how much mb::JSON will accept, and a few
# inputs have no JSON representation at all.  Both variables are
# ordinary globals, so local() confines a change to one block.
#
# Demonstrates:
#   - $mb::JSON::MAX_DEPTH -- cap on nesting depth, 512 by default
#   - $mb::JSON::STRICT -- reject raw control characters and bad UTF-8
#   - decode: a leading UTF-8 byte order mark is skipped
#   - decode: a number literal outside perl's range is reported
#   - decode: only the four whitespace bytes RFC 8259 allows are accepted
#   - encode: circular references, Inf and NaN are reported
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use mb::JSON;

# Report what happened, with the "at FILE line N" tail trimmed off.
sub show {
    my ($label, $result, $error) = @_;
    if (defined $error && $error ne '') {
        $error =~ s/ at .*//s;
        print "$label: rejected -- $error\n";
    }
    else {
        print "$label: accepted -- $result\n";
    }
}

print "defaults: MAX_DEPTH=$mb::JSON::MAX_DEPTH STRICT=$mb::JSON::STRICT\n";
print "\n";

######################################################################
# $mb::JSON::MAX_DEPTH -- nesting depth
######################################################################

print "-- MAX_DEPTH --\n";
{
    local $mb::JSON::MAX_DEPTH = 3;

    my $shallow = eval { mb::JSON::decode('[[1]]') };
    show('decode [[1]] with MAX_DEPTH 3',
         defined $shallow ? 'parsed' : 'undef', $@);

    my $deep = eval { mb::JSON::decode('[[[[[1]]]]]') };
    show('decode [[[[[1]]]]] with MAX_DEPTH 3',
         defined $deep ? 'parsed' : 'undef', $@);

    # encode() is capped the same way
    my $json = eval { mb::JSON::encode([ [ [ [ [ 1 ] ] ] ] ]) };
    show('encode 5 levels deep with MAX_DEPTH 3',
         defined $json ? $json : 'undef', $@);
}

# A false value turns the check off.  Do this only for input you trust:
# the limit is what stops hostile input from exhausting the perl stack.
{
    local $mb::JSON::MAX_DEPTH = 0;
    my $data = eval { mb::JSON::decode('[[[[[[[[1]]]]]]]]') };
    show('decode 8 levels deep with MAX_DEPTH 0',
         defined $data ? 'parsed' : 'undef', $@);
}
print "\n";

######################################################################
# $mb::JSON::STRICT -- string contents
######################################################################

print "-- STRICT --\n";

# By default the decoder is byte-transparent: an unescaped control
# character is kept, and UTF-8 is not validated.
my $lax_ctrl = eval { mb::JSON::decode(qq{"a\nb"}) };
show('decode a raw newline inside a string, STRICT off',
     defined $lax_ctrl ? length($lax_ctrl) . ' bytes' : 'undef', $@);

my $lax_utf8 = eval { mb::JSON::decode(qq{"\xFF"}) };
show('decode a malformed UTF-8 byte, STRICT off',
     defined $lax_utf8 ? length($lax_utf8) . ' bytes' : 'undef', $@);

{
    local $mb::JSON::STRICT = 1;

    my $ctrl = eval { mb::JSON::decode(qq{"a\nb"}) };
    show('decode a raw newline inside a string, STRICT on',
         defined $ctrl ? length($ctrl) . ' bytes' : 'undef', $@);

    my $bad = eval { mb::JSON::decode(qq{"\xFF"}) };
    show('decode a malformed UTF-8 byte, STRICT on',
         defined $bad ? length($bad) . ' bytes' : 'undef', $@);

    # Properly escaped and properly encoded text is still fine.
    my $good = eval { mb::JSON::decode('"a\nb"') };
    show('decode an escaped newline, STRICT on',
         defined $good ? length($good) . ' bytes' : 'undef', $@);

    my $emoji = eval { mb::JSON::decode('"\ud83d\ude00"') };
    show('decode a surrogate pair, STRICT on',
         defined $emoji ? length($emoji) . ' bytes of UTF-8' : 'undef', $@);
}
print "\n";

######################################################################
# Values with no JSON representation
######################################################################

print "-- values JSON cannot express --\n";

# A reference that contains itself would otherwise recurse forever.
my $loop = [ 1, 2 ];
push @$loop, $loop;
my $loop_json = eval { mb::JSON::encode([ @$loop ]) };
show('encode an array that contains itself',
     defined $loop_json ? $loop_json : 'undef', $@);

my $node = { name => 'root' };
$node->{self} = $node;
my $node_json = eval { mb::JSON::encode({ %$node }) };
show('encode a hash that contains itself',
     defined $node_json ? $node_json : 'undef', $@);

# Sharing a subtree twice is not circular, so it still encodes.
my $shared = [ 1, 2 ];
my $shared_json = eval { mb::JSON::encode([ $shared, $shared ]) };
show('encode a subtree used twice',
     defined $shared_json ? $shared_json : 'undef', $@);

# JSON has no syntax for Inf or NaN.
my $inf = 9**9**9;
my $inf_json = eval { mb::JSON::encode($inf) };
show("encode the number perl prints as '$inf'",
     defined $inf_json ? $inf_json : 'undef', $@);

# Inf and NaN are recognized by how perl prints them, so a string that
# spells one of those words exactly is rejected as well.  Longer words
# are unaffected.
my $word_json = eval { mb::JSON::encode({ word => 'Info', unit => 'nano' }) };
show('encode the strings "Info" and "nano"',
     defined $word_json ? $word_json : 'undef', $@);

# A number literal can be valid JSON syntax and still fall outside
# perl's floating point range at either end.  Converting it anyway would
# turn an overflowing literal into Inf and an underflowing one into 0,
# so decode() reports it instead.  Where the range ends depends on how
# this perl was built -- an ordinary double stops around 1e308, a perl
# built -Duselongdouble or -Dusequadmath carries on past 1e4932 -- so
# the literals below are searched for rather than assumed.
my $over = '1e400';
$over =~ s/\d+\z/$& * 4/e
    while ("$over" + 0) !~ /\A-?(?:inf(?:inity)?|nan|1\.#[a-z]+)\z/is
       && $over !~ /e\d{6}/;

my $under = '1e-400';
$under =~ s/\d+\z/$& * 4/e
    while (("$under" + 0) != 0) && $under !~ /e-\d{6}/;

print "this perl overflows at $over and underflows at $under\n";

my $over_val = eval { mb::JSON::decode($over) };
show("decode the number literal $over",
     defined $over_val ? $over_val : 'undef', $@);

my $under_val = eval { mb::JSON::decode($under) };
show("decode the number literal $under",
     defined $under_val ? $under_val : 'undef', $@);

# Only the mantissa is examined, so a literal that is genuinely zero is
# accepted however extreme its exponent looks.
my $zero = eval { mb::JSON::decode('0e-400') };
show('decode the number literal 0e-400',
     defined $zero ? $zero : 'undef', $@);
print "\n";

######################################################################
# Byte order mark
######################################################################

print "-- byte order mark --\n";

my $bom = eval { mb::JSON::decode("\xEF\xBB\xBF" . '{"name":"Alice"}') };
show('decode text that starts with a UTF-8 BOM',
     ref($bom) eq 'HASH' ? "name is $bom->{name}" : 'undef', $@);

# A BOM anywhere else is data, not a mark, so it is left to the parser.
my $tail = eval { mb::JSON::decode('{"name":"Alice"}' . "\xEF\xBB\xBF") };
show('decode text with a BOM after the value',
     ref($tail) eq 'HASH' ? 'parsed' : 'undef', $@);
print "\n";

######################################################################
# Whitespace between tokens
######################################################################

print "-- whitespace --\n";

# RFC 8259 allows exactly space, tab, LF and CR between tokens.  The set
# is spelled out in the parser rather than written as perl's \s, because
# \s also matches form feed on every perl and vertical tab from perl
# 5.18 onward -- which would have made the same document decode on one
# perl and fail on another.
my $spaced = eval { mb::JSON::decode(qq{ [\t1,\r\n2] }) };
show('decode a document padded with space, tab, CR and LF',
     ref($spaced) eq 'ARRAY' ? scalar(@$spaced) . ' elements' : 'undef', $@);

my $ff = eval { mb::JSON::decode("[\x0C1]") };
show('decode a document with a form feed before the value',
     ref($ff) eq 'ARRAY' ? 'parsed' : 'undef', $@);

my $vt = eval { mb::JSON::decode("[\x0B1]") };
show('decode a document with a vertical tab before the value',
     ref($vt) eq 'ARRAY' ? 'parsed' : 'undef', $@);
