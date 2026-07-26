######################################################################
#
# 1005-limits.t - $MAX_DEPTH, $STRICT, circular references, Inf/NaN, BOM
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

my ($T_RUN, $T_FAIL) = (0, 0);
sub ok   {
    my ($ok,$n) = @_;
    $T_RUN++; $T_FAIL++ unless $ok;
    print +($ok?'':'not ') . "ok $T_RUN" . ($n?" - $n":'') . "\n"; $ok
}
sub is   {
    my ($got,$exp,$n) = @_;
    my $ok = defined $got && defined $exp && "$got" eq "$exp";
    ok($ok, $n) or print "# got: " . (defined $got ? "'$got'" : 'undef')
                       . "  expected: '$exp'\n";
}
sub err_like {
    my ($code,$re,$n) = @_;
    my $e;
    eval { $code->() };
    $e = $@;
    ok($e && $e =~ /$re/, $n)
        or print "# got: " . (defined $e && $e ne '' ? "'$e'" : 'no error')
               . "  expected to match: $re\n";
}
# Assigning to $? sets the exit status; calling exit() from an END block
# aborts perl 5.6 and earlier with "Callback called exit."
END { $? = 1 if $T_FAIL }

my @tests;

######################################################################
# Configuration variables exist and have the documented defaults
######################################################################

push @tests, sub { is( $mb::JSON::MAX_DEPTH, 512, 'MAX_DEPTH defaults to 512' ) };
push @tests, sub { is( $mb::JSON::STRICT, 0, 'STRICT defaults to 0' ) };

######################################################################
# MAX_DEPTH on decode
######################################################################

# depth 4 array, limit 5: accepted
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 5;
    my $d = eval { mb::JSON::decode('[[[[1]]]]') };
    ok(!$@ && ref($d) eq 'ARRAY', 'decode: nesting within MAX_DEPTH is accepted');
};

# depth 6 array, limit 5: rejected
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 5;
    err_like(sub { mb::JSON::decode('[[[[[[1]]]]]]') },
             qr/nesting too deep/, 'decode: array deeper than MAX_DEPTH is rejected');
};

# depth 6 object, limit 5: rejected
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 5;
    err_like(sub { mb::JSON::decode('{"a":{"a":{"a":{"a":{"a":{"a":1}}}}}}') },
             qr/nesting too deep/, 'decode: object deeper than MAX_DEPTH is rejected');
};

# a false MAX_DEPTH disables the check
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 0;
    my $d = eval { mb::JSON::decode('[[[[[[[[1]]]]]]]]') };
    ok(!$@ && ref($d) eq 'ARRAY', 'decode: MAX_DEPTH = 0 disables the check');
};

# parse() shares the limit
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 3;
    err_like(sub { mb::JSON::parse('[[[[1]]]]') },
             qr/nesting too deep/, 'parse: honours MAX_DEPTH');
};

######################################################################
# MAX_DEPTH on encode
######################################################################

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 5;
    my $j = eval { mb::JSON::encode([[[1]]]) };
    is($j, '[[[1]]]', 'encode: nesting within MAX_DEPTH is accepted');
};

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 3;
    err_like(sub { mb::JSON::encode([[[[[1]]]]]) },
             qr/nesting too deep/, 'encode: structure deeper than MAX_DEPTH is rejected');
};

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 3;
    err_like(sub { mb::JSON::stringify([[[[[1]]]]]) },
             qr/nesting too deep/, 'stringify: honours MAX_DEPTH');
};

######################################################################
# decode() and encode() must stop at the same depth
#
# The limit counts containers, not values, in both directions: a leaf
# scalar inside the deepest allowed container is not a further level,
# because the decoder does not count it as one either.  Whatever
# decode() accepts, encode() must be able to write back out.
######################################################################

sub nest_json { my ($n) = @_; return ('[' x $n) . (']' x $n) }

sub nest_data {
    my ($n) = @_;
    my $top = [];
    my $leaf = $top;
    for (2 .. $n) { my $inner = []; push @$leaf, $inner; $leaf = $inner }
    return $top;
}

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 8;
    my $d = eval { mb::JSON::decode(nest_json(8)) };
    ok(!$@ && ref($d) eq 'ARRAY', 'decode: exactly MAX_DEPTH containers is accepted');
};

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 8;
    my $j = eval { mb::JSON::encode(nest_data(8)) };
    is($j, nest_json(8), 'encode: exactly MAX_DEPTH containers is accepted');
};

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 8;
    err_like(sub { mb::JSON::decode(nest_json(9)) },
             qr/nesting too deep/, 'decode: MAX_DEPTH + 1 containers is rejected');
};

push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 8;
    err_like(sub { mb::JSON::encode(nest_data(9)) },
             qr/nesting too deep/, 'encode: MAX_DEPTH + 1 containers is rejected');
};

# A scalar in the innermost allowed container is not an extra level.
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 8;
    my $data = nest_data(8);
    my $leaf = $data;
    $leaf = $leaf->[0] while ref($leaf->[0]) eq 'ARRAY';
    push @$leaf, 1;
    my $j = eval { mb::JSON::encode($data) };
    is($j, ('[' x 8) . '1' . (']' x 8),
       'encode: a leaf scalar in the deepest container is not a further level');
};

# The round trip is the property that matters: whatever decode() reads,
# encode() must be able to write back.
push @tests, sub {
    local $mb::JSON::MAX_DEPTH = 8;
    my $j = nest_json(8);
    my $back = eval { mb::JSON::encode(mb::JSON::decode($j)) };
    is($back, $j, 'decode then encode at exactly MAX_DEPTH round-trips');
};

# and at the shipped default, not just at a small local override
push @tests, sub {
    my $j = nest_json($mb::JSON::MAX_DEPTH);
    my $back = eval { mb::JSON::encode(mb::JSON::decode($j)) };
    is($back, $j, 'decode then encode at the default MAX_DEPTH round-trips');
};

push @tests, sub {
    err_like(sub { mb::JSON::encode(nest_data($mb::JSON::MAX_DEPTH + 1)) },
             qr/nesting too deep/,
             'encode: default MAX_DEPTH + 1 containers is rejected');
};

######################################################################
# Circular references
######################################################################

push @tests, sub {
    my @a;
    push @a, \@a;
    err_like(sub { mb::JSON::encode([ @a ]) },
             qr/circular reference/, 'encode: self-referencing array is rejected');
};

push @tests, sub {
    my %h;
    $h{self} = { %h };
    $h{self}{back} = $h{self};
    err_like(sub { mb::JSON::encode({ %h }) },
             qr/circular reference/, 'encode: self-referencing hash is rejected');
};

push @tests, sub {
    my @a;
    push @a, \@a;
    err_like(sub { mb::JSON::stringify([ @a ]) },
             qr/circular reference/, 'stringify: self-referencing array is rejected');
};

# sharing a subtree twice is not circular and must still encode
push @tests, sub {
    my $shared = [ 1, 2 ];
    my $j = eval { mb::JSON::encode([ $shared, $shared ]) };
    is($j, '[[1,2],[1,2]]', 'encode: a shared (non-circular) subtree still encodes');
};

push @tests, sub {
    my $shared = { a => 1 };
    my $j = eval { mb::JSON::encode({ x => $shared, y => $shared }) };
    is($j, '{"x":{"a":1},"y":{"a":1}}', 'encode: a shared hash used twice still encodes');
};

######################################################################
# Inf / NaN
#
# How perl spells a non-finite value is platform dependent ("Inf",
# "-Inf", "NaN", "1.#INF", "-1.#IND", ...), and mb::JSON recognizes them
# by that spelling.  The tests below report the spelling this platform
# actually uses, so an unrecognized one is visible in the output rather
# than silently passing.
######################################################################

my $INF  = 9**9**9;
my $NINF = -(9**9**9);
my $NAN  = $INF - $INF;

sub nonfinite_spelling_known {
    my ($value) = @_;
    return "$value" =~ /\A-?(?:inf(?:inity)?|nan|1\.#[a-z]+)\z/is;
}

push @tests, sub {
    print "# this platform spells 9**9**9 as '$INF'\n";
    print "# this platform spells -(9**9**9) as '$NINF'\n";
    print "# this platform spells (9**9**9)-(9**9**9) as '$NAN'\n";
    ok(nonfinite_spelling_known($INF),
       "encode: this platform's Inf spelling '$INF' is one mb::JSON knows");
};

push @tests, sub {
    err_like(sub { mb::JSON::encode($INF) },
             qr/cannot encode Inf or NaN/, 'encode: numeric Inf is rejected');
};

push @tests, sub {
    err_like(sub { mb::JSON::encode($NINF) },
             qr/cannot encode Inf or NaN/, 'encode: numeric -Inf is rejected');
};

push @tests, sub {
    err_like(sub { mb::JSON::encode({ v => $INF }) },
             qr/cannot encode Inf or NaN/, 'encode: Inf inside a hash is rejected');
};

# Documented cost of recognizing them by spelling: a string that spells
# one of these words exactly is rejected as well.
push @tests, sub {
    err_like(sub { mb::JSON::encode('Inf') },
             qr/cannot encode Inf or NaN/, 'encode: a string spelling exactly "Inf" is rejected too');
};

push @tests, sub {
    err_like(sub { mb::JSON::encode('NaN') },
             qr/cannot encode Inf or NaN/, 'encode: a string spelling exactly "NaN" is rejected too');
};

# Longer words must not be caught by that rule.
push @tests, sub {
    my $j = eval { mb::JSON::encode({ word => 'Info' }) };
    is($j, '{"word":"Info"}', 'encode: the string "Info" is encoded as a string');
};

push @tests, sub {
    my $j = eval { mb::JSON::encode('nano') };
    is($j, '"nano"', 'encode: the string "nano" is encoded as a string');
};

push @tests, sub {
    my $j = eval { mb::JSON::encode('Infrastructure') };
    is($j, '"Infrastructure"', 'encode: the string "Infrastructure" is encoded as a string');
};

push @tests, sub {
    my $j = eval { mb::JSON::encode('infinite loop') };
    is($j, '"infinite loop"', 'encode: the string "infinite loop" is encoded as a string');
};

# A JSON number literal can be finite JSON syntax and still fall outside
# perl's floating point range at either end.  decode() must reject it
# instead of silently returning Inf, which encode() would then refuse to
# re-encode, or 0, which has lost every significant digit the literal
# carried.
#
# Where that range ends depends on how this perl was built.  An ordinary
# double runs out around 1e308, but a perl built -Duselongdouble or
# -Dusequadmath carries on past 1e4932, and on such a perl "1e400" is an
# unremarkable finite number that decode() is right to accept.  Any
# literal hardcoded here would therefore test the opposite thing on the
# next smoker, so the literals are searched for at run time.

sub overflow_literal {
    my $e = 400;
    for (1 .. 8) {
        return "1e$e" if nonfinite_spelling_known("1e$e" + 0);
        $e *= 4;
    }
    return undef;
}

sub underflow_literal {
    my $e = 400;
    for (1 .. 8) {
        return "1e-$e" if ("1e-$e" + 0) == 0;
        $e *= 4;
    }
    return undef;
}

my $OVER  = overflow_literal();
my $UNDER = underflow_literal();

push @tests, sub {
    print "# this perl overflows at '"  . (defined $OVER  ? $OVER  : 'not found') . "'\n";
    print "# this perl underflows at '" . (defined $UNDER ? $UNDER : 'not found') . "'\n";
    ok(defined($OVER) && defined($UNDER),
       'a literal outside this perl\'s floating point range was found at both ends');
};

push @tests, sub {
    return ok(1, 'decode: overflow test skipped, no overflowing literal')
        unless defined $OVER;
    err_like(sub { mb::JSON::decode($OVER) },
             qr/number out of range/,
             "decode: an overflowing exponent ($OVER) is rejected");
};

push @tests, sub {
    return ok(1, 'decode: negative overflow test skipped, no overflowing literal')
        unless defined $OVER;
    err_like(sub { mb::JSON::decode("-$OVER") },
             qr/number out of range/,
             "decode: an overflowing negative exponent (-$OVER) is rejected");
};

push @tests, sub {
    return ok(1, 'decode: underflow test skipped, no underflowing literal')
        unless defined $UNDER;
    err_like(sub { mb::JSON::decode($UNDER) },
             qr/number out of range/,
             "decode: an underflowing exponent ($UNDER) is rejected");
};

push @tests, sub {
    return ok(1, 'decode: negative underflow test skipped, no underflowing literal')
        unless defined $UNDER;
    err_like(sub { mb::JSON::decode("-$UNDER") },
             qr/number out of range/,
             "decode: an underflowing negative exponent (-$UNDER) is rejected");
};

# 1e300 and 1e-300 are comfortably inside the range of an ordinary
# double and of every wider NV, so these two are safe to hardcode.
push @tests, sub {
    my $d = eval { mb::JSON::decode('1e300') };
    ok(!$@ && $d == 1e300, 'decode: a large but finite exponent is accepted');
};

push @tests, sub {
    my $d = eval { mb::JSON::decode('1e-300') };
    ok(!$@ && $d == 1e-300, 'decode: a small but representable exponent is accepted');
};

# A literal that is genuinely zero has no significant digit to lose.
for my $zero ('0', '-0', '0.0', '0.000', '0e0', '0e-400') {
    push @tests, sub {
        my $d = eval { mb::JSON::decode($zero) };
        ok(!$@ && defined($d) && $d == 0,
           "decode: the zero literal $zero is accepted");
    };
}

######################################################################
# Whitespace between tokens
#
# RFC 8259 allows exactly space, tab, LF and CR.  perl's \s also matches
# form feed, and matches vertical tab from perl 5.18 onward, so writing
# \s here would have made the same document decode differently on perl
# 5.16 and perl 5.18.  These tests pin the set down on every perl.
######################################################################

for my $ws (0x20, 0x09, 0x0A, 0x0D) {
    push @tests, sub {
        my $c = chr($ws);
        my $json = $c . '[' . $c . '1' . $c . ']' . $c;
        my $d = eval { mb::JSON::decode($json) };
        ok(!$@ && ref($d) eq 'ARRAY' && @$d == 1 && $d->[0] == 1,
           sprintf('decode: 0x%02X is accepted as whitespace', $ws));
    };
}

for my $ws (0x0B, 0x0C) {
    push @tests, sub {
        my $c = chr($ws);
        err_like(sub { mb::JSON::decode('[' . $c . '1]') },
                 qr/unexpected token/,
                 sprintf('decode: 0x%02X is not whitespace and is rejected', $ws));
    };
}

push @tests, sub {
    err_like(sub { mb::JSON::decode('{"a":1}' . chr(0x0C)) },
             qr/trailing garbage/,
             'decode: form feed after the value is garbage, not whitespace');
};

######################################################################
# Deep recursion warning
#
# perl's core "Deep recursion on subroutine" warning fires past a
# fixed threshold of 100 nested calls, well below the default
# $MAX_DEPTH of 512.  Input in that range must decode/encode without
# printing that warning; it is not something the caller can silence,
# since it comes from a lexical `use warnings` inside this module.
######################################################################

push @tests, sub {
    my $depth = 150;
    my $j = ('[' x $depth) . (']' x $depth);
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $d = eval { mb::JSON::decode($j) };
    ok(!$@ && ref($d) eq 'ARRAY' && !@warnings,
       "decode: nesting past perl's recursion warning threshold prints no warning")
        or print "# warnings: @warnings\n";
};

push @tests, sub {
    my $depth = 150;
    my $data = [];
    my $leaf = $data;
    for (2 .. $depth) { my $n = []; push @$leaf, $n; $leaf = $n; }
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $j = eval { mb::JSON::encode($data) };
    ok(!$@ && defined($j) && !@warnings,
       "encode: nesting past perl's recursion warning threshold prints no warning")
        or print "# warnings: @warnings\n";
};

######################################################################
# Byte order mark
######################################################################

push @tests, sub {
    my $d = eval { mb::JSON::decode("\xEF\xBB\xBF" . '{"a":1}') };
    is(ref($d) eq 'HASH' ? $d->{a} : undef, 1, 'decode: leading UTF-8 BOM is skipped');
};

push @tests, sub {
    my $d = eval { mb::JSON::parse("\xEF\xBB\xBF" . '[1,2]') };
    is(ref($d) eq 'ARRAY' ? scalar(@$d) : undef, 2, 'parse: leading UTF-8 BOM is skipped');
};

# a BOM in the middle is not a BOM, it is data
push @tests, sub {
    err_like(sub { mb::JSON::decode('{"a":1}' . "\xEF\xBB\xBF") },
             qr/trailing garbage/, 'decode: a BOM after the value is still garbage');
};

######################################################################
# STRICT: raw control characters
######################################################################

push @tests, sub {
    my $d = eval { mb::JSON::decode(qq{"a\nb"}) };
    is($d, "a\nb", 'decode: raw control character accepted by default');
};

push @tests, sub {
    local $mb::JSON::STRICT = 1;
    err_like(sub { mb::JSON::decode(qq{"a\nb"}) },
             qr/raw control character/, 'decode: raw control character rejected under STRICT');
};

push @tests, sub {
    local $mb::JSON::STRICT = 1;
    my $d = eval { mb::JSON::decode('"a\nb"') };
    is($d, "a\nb", 'decode: escaped control character still accepted under STRICT');
};

######################################################################
# STRICT: UTF-8 validation
######################################################################

push @tests, sub {
    my $d = eval { mb::JSON::decode(qq{"\xFF"}) };
    is(defined($d) ? length($d) : undef, 1, 'decode: malformed UTF-8 accepted by default');
};

push @tests, sub {
    local $mb::JSON::STRICT = 1;
    err_like(sub { mb::JSON::decode(qq{"\xFF"}) },
             qr/malformed UTF-8/, 'decode: malformed UTF-8 rejected under STRICT');
};

push @tests, sub {
    local $mb::JSON::STRICT = 1;
    my $d = eval { mb::JSON::decode(qq{"\xE3\x81\x82"}) };
    is(defined($d) ? length($d) : undef, 3, 'decode: well-formed UTF-8 accepted under STRICT');
};

push @tests, sub {
    local $mb::JSON::STRICT = 1;
    my $d = eval { mb::JSON::decode('"\ud83d\ude00"') };
    is(defined($d) ? length($d) : undef, 4, 'decode: surrogate pair output is valid UTF-8 under STRICT');
};

push @tests, sub {
    local $mb::JSON::STRICT = 1;
    my $d = eval { mb::JSON::decode('"plain ascii"') };
    is($d, 'plain ascii', 'decode: ASCII accepted under STRICT');
};

######################################################################
# encode() with no argument at all uses $_
######################################################################

push @tests, sub {
    local $_ = { a => 1 };
    my $j = mb::JSON::encode();
    is($j, '{"a":1}', 'encode: uses $_ when called with no argument');
};

push @tests, sub {
    local $_ = [ 1, 2 ];
    my $j = mb::JSON::stringify();
    is($j, '[1,2]', 'stringify: uses $_ when called with no argument');
};

push @tests, sub {
    my $j = mb::JSON::encode(undef);
    is($j, 'null', 'encode: an explicit undef is still null');
};

######################################################################
# The aliases delegate in one hop.  They must still resolve an omitted
# or undefined argument to $_ exactly as they did when each copied the
# argument into a lexical of its own first.
######################################################################

push @tests, sub {
    local $_ = '[1,2,3]';
    my $d = eval { mb::JSON::parse() };
    is(ref($d) eq 'ARRAY' ? scalar(@$d) : undef, 3,
       'parse: uses $_ when called with no argument');
};

push @tests, sub {
    local $_ = '[1,2,3]';
    my $d = eval { mb::JSON::parse(undef) };
    is(ref($d) eq 'ARRAY' ? scalar(@$d) : undef, 3,
       'parse: uses $_ when the argument is undef');
};

push @tests, sub {
    local $_ = '{"a":1}';
    my $d = eval { mb::JSON::decode(undef) };
    is(ref($d) eq 'HASH' ? $d->{a} : undef, 1,
       'decode: uses $_ when the argument is undef');
};

push @tests, sub {
    my $j = mb::JSON::stringify(undef);
    is($j, 'null', 'stringify: an explicit undef is still null');
};

# parse() must not disturb the caller's string, the same as decode()
push @tests, sub {
    my $src = "\xEF\xBB\xBF" . '{"a":1}';
    eval { mb::JSON::parse($src) };
    is($src, "\xEF\xBB\xBF" . '{"a":1}',
       'parse: leaves the caller\'s string unmodified');
};

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
