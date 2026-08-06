use strict;
use warnings;
use Test::More;
use File::Temp 'tempfile';
use File::Spec;
use Text::Stencil;

# Loaded by name only, never imported: importing brings prototypes that change
# how the calls below PARSE, so a machine without the module could not even
# compile this file.
our $TS_HAVE_VMAGIC;
BEGIN { $TS_HAVE_VMAGIC = eval { require Variable::Magic; 1 } }

sub exception_from { my $c = shift; eval { $c->(); 1 } ? '' : $@ }

{   # scope-guarded alarm: the timer is always cleared, croak or not
    package TS_Alarm;
    sub new { my ($c, $secs) = @_; alarm $secs; bless \(my $x), $c }
    sub DESTROY { alarm 0 }
}

{   # a tied hash keeps its keys outside the backing HV
    package TS_TiedHash;
    sub TIEHASH  { bless { d => $_[1] }, $_[0] }
    sub FETCH    { $_[0]{d}{ $_[1] } }
    sub EXISTS   { exists $_[0]{d}{ $_[1] } }
    sub FIRSTKEY { my @k = sort keys %{ $_[0]{d} }; $_[0]{i} = 1; $k[0] }
    sub NEXTKEY  { my @k = sort keys %{ $_[0]{d} }; $k[ $_[0]{i}++ ] }
    sub STORE {} sub DELETE {} sub CLEAR {} sub SCALAR { 1 }
}

# Regression tests for the defects fixed in 0.03.  Each of these fails on
# 0.02 -- several by crashing the interpreter rather than by returning a
# wrong value, so they are grouped to keep a crash from hiding the rest.

sub rss_kb {
    open my $fh, '<', '/proc/self/status' or return undef;
    while (<$fh>) { return $1 if /^VmRSS:\s+(\d+)/ }
    return undef;
}

# A large leaked block comes from mmap and is mostly never written, so it never
# shows up in RSS.  Address space is the only signal that catches it.
sub vmsize_kb {
    open my $fh, '<', '/proc/self/status' or return undef;
    while (<$fh>) { return $1 if /^VmSize:\s+(\d+)/ }
    return undef;
}

# A buffer that is freed before the call returns leaves VmSize back where it
# started, so a transient over-allocation is only visible in the high-water mark.
sub vmpeak_kb {
    open my $fh, '<', '/proc/self/status' or return undef;
    while (<$fh>) { return $1 if /^VmPeak:\s+(\d+)/ }
    return undef;
}

# RSS is not a usable leak signal under a sanitizer or valgrind: redzones and
# quarantined frees make it grow whether or not anything leaked.  Those tools
# report leaks properly on their own, so leave the accounting to them.
sub instrumented {
    require Config;
    return 1 if ($ENV{LD_PRELOAD} || '') =~ /libasan|libubsan|vgpreload/;
    return 1 if ($Config::Config{ccflags} || '') =~ /-fsanitize/;
    if (open my $fh, '<', '/proc/self/maps') {
        while (<$fh>) { return 1 if /vgpreload|libasan/ }
    }
    return 0;
}

# --- transform parameters are validated instead of digit-accumulated -------
# "mask: 4" made param_int negative, so mask wrote slen-keep bytes into a
# buffer reserved for slen: an ASAN-confirmed heap-buffer-overflow.
{
    for my $p ('-1', ' 4', '+4', 'abc', '4x') {
        ok !eval { Text::Stencil->new(row => "{0:mask:$p}"); 1 },
            "mask:'$p' is rejected at compile time";
    }
    is(Text::Stencil->new(row => '{0:mask:4}')->render([['secret123456']]),
        '********3456', 'valid mask parameter still works');

    ok !eval { Text::Stencil->new(row => '{0:pad:abc}'); 1 },   'pad:abc rejected';
    ok !eval { Text::Stencil->new(row => '{0:trunc:-5}'); 1 },  'trunc:-5 rejected';
    ok !eval { Text::Stencil->new(row => '{0:float:-2}'); 1 },  'float:-2 rejected';
    ok !eval { Text::Stencil->new(row => '{0:substr:0:-1}'); 1 }, 'substr:0:-1 rejected';
    ok !eval { Text::Stencil->new(row => '{0:pad:2000000000}'); 1 },
        'absurd pad width rejected instead of allocating 2GB';
    like $@, qr/too large/, '  with a clear message';
}

# --- magical arrays as rows no longer segfault ----------------------------
# fetch_field/is_field_truthy used AvARRAY, which is NULL on a magical AV
# while av_top_index() still reports the real length.
{
    "hello world" =~ /(\w+) (\w+)/;
    my $out = Text::Stencil->new(row => '{0:raw}|{1:raw}')->render([\@-]);
    is $out, "$-[0]|$-[1]", 'core magical array (@-) as a row';

    package TA; require Tie::Array; our @ISA = ('Tie::StdArray');
    package main;

    tie my @row, 'TA'; @row = ('tied0', 'tied1');
    is(Text::Stencil->new(row => '{0:raw}/{1:raw}')->render([\@row]),
        'tied0/tied1', 'tied array as a row');

    tie my @sk, 'TA'; @sk = ('name', '1');
    is(Text::Stencil->new(row => '{0:raw}', skip_if => 1)->render([\@sk]),
        '', 'skip_if against a tied array row');

    tie my @rows, 'TA'; @rows = ([1, 'a'], [2, 'b']);
    is(Text::Stencil->new(row => '{0:int}-{1:raw}', separator => ',')->render(\@rows),
        '1-a,2-b', 'tied outer rows array (needs get-magic on the row SV)');

    # render_sorted extracts its keys in a separate loop, which needs the same
    # get-magic: without it every key came out "" and the sort silently did
    # nothing while the rows still rendered.
    my $s = Text::Stencil->new(row => '{0:raw};');
    tie my @unsorted, 'TA'; @unsorted = ([3], [1], [2]);
    is $s->render_sorted(\@unsorted, 0), '1;2;3;', 'render_sorted actually sorts tied rows';
    is $s->render_sorted(\@unsorted, 0, {descending => 1}), '3;2;1;', '  ...descending too';
    is $s->render_sorted(\@unsorted, 0, {numeric => 1}), '1;2;3;', '  ...and numerically';

    my $h = Text::Stencil->new(row => '{n:raw};');
    tie my @hrows, 'TA'; @hrows = ({n => 'c'}, {n => 'a'}, {n => 'b'});
    is $h->render_sorted(\@hrows, 'n'), 'a;b;c;', 'render_sorted sorts tied hashref rows';
}

# --- date: unchecked gmtime_r formatted uninitialised stack bytes ----------
{
    my $s = Text::Stencil->new(row => '{0:date}');
    is $s->render([['0']]), '1970-01-01 00:00:00', 'valid epoch still formats';
    # the first two overflow the digit scan and never reach gmtime; the third
    # does reach it and is rejected there, which is the branch the
    # uninitialised-tm bug actually lived in
    for my $e ('9999999999999999999999999', '99999999999999999999',
               '900000000000000000') {
        is $s->render([[$e]]), '', "out-of-range epoch $e renders empty";
    }
}

# --- output encoding follows the input instead of always claiming UTF-8 ----
{
    my $bytes = "caf\xe9";                        # 4 bytes, no UTF8 flag
    my $out = Text::Stencil->new(row => '{0:raw}')->render([[$bytes]]);
    ok !utf8::is_utf8($out), 'byte-string input yields a byte string';
    is length($out), 4, '  with its length intact (was 3, and malformed)';
    is $out, $bytes, '  and equal to the input';

    my $chars = "caf\x{e9} \x{2014}";
    my $cout = Text::Stencil->new(row => '{0:raw}')->render([[$chars]]);
    ok utf8::is_utf8($cout), 'character-string input still yields a character string';
    is $cout, $chars, '  round-tripped';

    my $u = "\x{e9}"; utf8::upgrade($u);
    my $b = "\xe9";   utf8::downgrade($b);
    my $mix = Text::Stencil->new(row => '{0:raw}/{1:raw}')->render([[$u, $b]]);
    ok !utf8::is_utf8($mix), 'a row mixing encodings yields bytes, never a malformed SV';
    # whether those bytes happen to decode is not the point; what matters is
    # that the result is either clean bytes or well-formed, never flagged junk
    ok !(utf8::is_utf8($mix) && !utf8::valid($mix)),
        '  and never flagged-but-malformed';

    # a UTF-8 template with ASCII byte fields keeps the template's encoding
    my $t = Text::Stencil->new(row => "\x{2014}{0:raw}");
    my $tout = $t->render([['x']]);
    is $tout, "\x{2014}x", 'template encoding is honoured';
    ok utf8::is_utf8($tout), '  and flagged accordingly';
}

# --- template errors are reported instead of silently mangling output -----
{
    ok !eval { Text::Stencil->new(row => '{0:raw}-{}'); 1 },
        'empty field reference dies (used to flip the whole template to hash mode)';
    like $@, qr/empty field reference/, '  with a clear message';

    ok !eval { Text::Stencil->new(row => '{0:int} {name:html}'); 1 },
        'mixing numeric and named references dies';
    like $@, qr/mixes numeric/, '  with a clear message';

    ok !eval { Text::Stencil->new(row => 'A{0:raw}B{oops'); 1 },
        'unclosed delimiter dies (used to drop the rest of the template)';
    like $@, qr/unclosed/, '  with a clear message';

    ok !eval { Text::Stencil->new(row => '{4294967297:raw}'); 1 },
        'out-of-range column index dies (used to wrap to another column)';

    # the documented literal-delimiter form is still not an "unclosed" error
    is(Text::Stencil->new(row => '{{"id":{0:int}}')->render([[42]]),
        '{"id":42}', 'literal {{ still compiles');
}

# --- transforms that silently ate or exceeded their input ------------------
{
    is(Text::Stencil->new(row => '{0:default:a|default:b}')->render([['v']]),
        'v', 'a chain of only defaults keeps a present value');
    is(Text::Stencil->new(row => '{0:default:a|default:b}')->render([[undef]]),
        'a', '  and still applies the first default for undef');

    is(Text::Stencil->new(row => '{0:wrap}')->render([['x']]),
        'x', 'wrap with no prefix/suffix passes the value through');

    is(Text::Stencil->new(row => '{0:trunc:0}')->render([['hello']]),
        '', 'trunc:0 emits nothing (used to emit "...")');
    is(Text::Stencil->new(row => '{0:trunc:2}')->render([['hello']]),
        'he', 'trunc:2 never exceeds the requested length');
    is(Text::Stencil->new(row => '{0:trunc:3}')->render([['hello']]),
        'hel', 'trunc:3 likewise');
    is(Text::Stencil->new(row => '{0:trunc:8}')->render([['hello world']]),
        'hello...', 'trunc:8 still ellipsises');

    is(Text::Stencil->new(row => '{0:plural:item}')->render([[1]]),
        '1 item', 'plural with one form: singular');
    is(Text::Stencil->new(row => '{0:plural:item}')->render([[5]]),
        '5 items', 'plural with one form: plural');

    my $long = 'z' x 300;
    is(length(Text::Stencil->new(row => '{0:sprintf:%s}')->render([[$long]])),
        300, 'sprintf:%s no longer truncates at 255 bytes');
    is(Text::Stencil->new(row => '{0:sprintf:%05d}')->render([[42]]),
        '00042', 'sprintf integer conversions still work');
    is(Text::Stencil->new(row => '{0:sprintf:%08x}')->render([[255]]),
        '000000ff', '  including hex');
    is(Text::Stencil->new(row => '{0:sprintf:%lld}')->render([[42]]),
        '42', 'a length modifier falls back to passthrough (ABI-unsafe)');

    # int/float as the first link of a chain read a block-scoped buffer that
    # had already gone out of scope (ASAN stack-use-after-scope)
    is(Text::Stencil->new(row => '{0:int|pad:8}')->render([[42]]),
        '      42', 'int|pad chain');
    is(Text::Stencil->new(row => '{0:float:2|pad:10}')->render([[3.14159]]),
        '      3.14', 'float|pad chain');
    is(Text::Stencil->new(row => '{0:count|pad:5}')->render([[[1,2,3]]]),
        '    3', 'count|pad chain');
}

# --- the output encoding follows the data, whatever order it arrives in ---
{
    my $u = "\x{2014}";          # character string
    my $b = "caf\xe9";           # byte string with a high byte
    my $a = "plain";             # byte string, pure ASCII

    my @cases = (
        ['all character',            '{0:raw}',        [[$u]],       1],
        ['all ASCII bytes',          '{0:raw}',        [[$a]],       0],
        ['all high bytes',           '{0:raw}',        [[$b]],       0],
        # a byte value that is not valid UTF-8 rules out a character result
        # whichever side of the character value it arrives on
        ['byte field then character', '{0:raw}{1:raw}', [[$b, $u]],  0],
        ['character field then byte', '{0:raw}{1:raw}', [[$u, $b]],  0],
        ['byte row then character row', '{0:raw}',      [[$b], [$u]], 0],
        ['character row then byte row', '{0:raw}',      [[$u], [$b]], 0],
        # ASCII is neutral -- it cannot make the result malformed
        ['ASCII then character',     '{0:raw}{1:raw}', [[$a, $u]],   1],
        ['character then ASCII',     '{0:raw}{1:raw}', [[$u, $a]],   1],
    );
    for my $c (@cases) {
        my ($name, $tpl, $rows, $want) = @$c;
        my $out = Text::Stencil->new(row => $tpl)->render($rows);
        is +(utf8::is_utf8($out) ? 1 : 0), $want, "encoding: $name";
        ok !utf8::is_utf8($out) || utf8::valid($out), "  ...and never malformed";
    }
}

# --- byte-level slicing must not leave a flagged half-character -----------
{
    my $two = "\x{2014}\x{2014}";        # 2 chars, 6 bytes
    my $mixed = "ab\x{2014}";
    my @cases = (
        ['trunc on a boundary',  '{0:trunc:6}',     $two,   1],
        ['trunc mid-character',  '{0:trunc:4}',     $two,   0],
        ['trunc:1 mid-character','{0:trunc:1}',     $mixed, 1],  # cuts "a"
        ['substr mid-character', '{0:substr:0:1}',  $two,   0],
        ['substr starts mid',    '{0:substr:1}',    $two,   0],
        ['substr on a boundary', '{0:substr:3}',    $two,   1],
        ['mask on a boundary',   '{0:mask:3}',      $two,   1],
        ['mask mid-character',   '{0:mask:1}',      $mixed, 0],
        ['pad never cuts',       '{0:pad:10}',      $two,   1],
    );
    for my $c (@cases) {
        my ($name, $tpl, $val, $want) = @$c;
        my $out = Text::Stencil->new(row => $tpl)->render([[$val]]);
        is +(utf8::is_utf8($out) ? 1 : 0), $want, "slicing: $name";
        ok !utf8::is_utf8($out) || utf8::valid($out), "  ...and never malformed";
    }
}

# --- sprintf precision slices bytes too -----------------------------------
# %.Ns is a fourth way to cut a value, and the padded output width is not the
# cut offset (%-8.2s cuts at 2 but emits 8), so this path defers to the final
# validation rather than testing a boundary.
{
    my $two = "\x{2014}\x{2014}";
    for my $tpl ('{0:sprintf:%.2s}', '{0:sprintf:%.3s}', '{0:sprintf:%-8.2s}',
                 '{0:sprintf:%.2s|uc}', '{0:sprintf:%.4s}', '{0:sprintf:%.1s}') {
        my $out = Text::Stencil->new(row => $tpl)->render([[$two]]);
        ok !(utf8::is_utf8($out) && !utf8::valid($out)),
            "$tpl never yields flagged-but-malformed output";
    }
    # an untruncated %s on character data still round-trips
    is(Text::Stencil->new(row => '{0:sprintf:%s}')->render([[$two]]), $two,
        'sprintf:%s round-trips character data');
}

# --- an empty slice must not poison the rest of the render ----------------
{
    my $out = Text::Stencil->new(row => '{0:substr:1:0}{1:raw}')
                  ->render([[ "\x{2014}\x{2014}", "\x{2014}\x{2014}" ]]);
    is $out, "\x{2014}\x{2014}", 'a zero-length slice emits nothing';
    ok utf8::is_utf8($out),
        '  ...and does not strip the encoding from the other fields';
}

# --- an empty render must not consult the leftover render buffer ----------
# is_utf8_string() reads len == 0 as "call strlen()", and the render buffer is
# not terminated at pos, so validating an empty result ran off the end of it
# (ASAN: heap-buffer-overflow).  The observable symptom is that the answer
# depended on whatever the previous render had left in the buffer.
{
    my $tpl = '{0:trunc:0}{1:trunc:0}';           # everything truncated away
    # a HIGH byte first, not plain ASCII: the encoding bookkeeping skips pure
    # ASCII, so 'abc' never engaged the path this test exists to cover
    my @row = ("caf\xe9", "\x{2014}");            # bytes first, then characters

    my $fresh = Text::Stencil->new(row => $tpl);
    my $a = $fresh->render([ \@row ]);

    my $warm = Text::Stencil->new(row => $tpl);
    $warm->render([[ 'x' x 400, "\x{2014}" x 100 ]]);   # grow and dirty the buffer
    my $b = $warm->render([ \@row ]);

    is length($a), 0, 'empty render produces an empty string';
    is length($b), 0, '  ...also from a reused, dirty buffer';
    is +(utf8::is_utf8($a) ? 1 : 0), +(utf8::is_utf8($b) ? 1 : 0),
        'empty-render encoding does not depend on leftover buffer contents';
}

# --- an empty substr offset means 0 (0.02 accepted this spelling) ---------
{
    is(Text::Stencil->new(row => '{0:substr::2}')->render([['Hello']]), 'He',
        'substr with an empty offset means 0');
    is(Text::Stencil->new(row => '{0:substr::2}')->render([['Hello']]),
       Text::Stencil->new(row => '{0:substr:0:2}')->render([['Hello']]),
        '  ...same as an explicit 0 offset');
}

# --- compile errors name what is actually wrong --------------------------
{
    # a stray literal brace lands in the mixed-mode check; the message has to
    # point at it rather than talk about {0} and {name} in the abstract
    eval { Text::Stencil->new(row => '.cls { color: red } {0:raw}') };
    like $@, qr/\Q{ color}\E/, 'mixed-reference error names the offending reference';
    like $@, qr/literal delimiter/, '  ...and suggests the fix';

    eval { Text::Stencil->new(row => 'trailing {') };
    like $@, qr/unclosed/,          'unclosed delimiter is reported';
    like $@, qr/literal delimiter/, '  ...and suggests the fix';
}

# --- from_file with an incomplete set of section markers ------------------
{
    my ($fh, $name) = tempfile(UNLINK => 1, SUFFIX => '.tpl');
    print $fh "__HEADER__\nH:\n__ROW__\n{0:int}\n";
    close $fh;
    is(Text::Stencil->from_file($name)->render([[42]]), "H:\n42\n",
        'from_file honours __HEADER__ + __ROW__ without __FOOTER__');

    my ($fh2, $name2) = tempfile(UNLINK => 1, SUFFIX => '.tpl');
    print $fh2 "__ROW__\n{0:int},\n";
    close $fh2;
    is(Text::Stencil->from_file($name2)->render([[1],[2]]), "1,\n2,\n",
        'from_file honours a lone __ROW__');

    my ($fh3, $name3) = tempfile(UNLINK => 1, SUFFIX => '.tpl');
    print $fh3 '{0:int}';
    close $fh3;
    is(Text::Stencil->from_file($name3, separator => ',')->render([[1],[2]]),
        '1,2', 'from_file without markers still uses the whole file');
}

# --- the sprintf conversion must be the last character of the format -------
# The argument pushed is chosen from the format's last character, so a format
# whose real conversion sits elsewhere pushed the wrong type: '%sx' handed
# printf the field value to dereference as a char * (SIGSEGV at the address the
# data spelled out), '%d_s' printed the low half of a heap pointer, and '%dx'
# leaked the spliced 'l' into the output.
{
    for my $fmt (qw(%sx %sd %so %s_d %d_s %dx %dd %fd %5dx %.2fx)) {
        is(Text::Stencil->new(row => "{0:sprintf:$fmt}")->render([[42]]), '42',
            "sprintf:$fmt is not applied and the value passes through");
    }
    # glibc aborts the process on a positional specifier it cannot satisfy
    for my $fmt ('%2$d', '%10$s', '%2$.3f', '%1$d') {
        is(Text::Stencil->new(row => "{0:sprintf:$fmt}")->render([[42]]), '42',
            "sprintf:$fmt is not applied (positional specifiers abort printf)");
    }
    # width and precision are bounded like every other numeric parameter
    is(Text::Stencil->new(row => '{0:sprintf:%999999999d}')->render([[42]]), '42',
        'an over-long width is not applied');
    is(length Text::Stencil->new(row => '{0:sprintf:%99999d}')->render([[42]]), 99999,
        '  ...but a width within the bound still pads');
    # everything the docs promise still formats
    my %ok = ('%d' => '42', '%s' => '42', '%.2f' => '42.00', '%05d' => '00042',
              '%#x' => '0x2a', '%+d' => '+42', '%-8.2s' => '42      ',
              '%X' => '2A', '%o' => '52', '%u' => '42', '%i' => '42');
    is(Text::Stencil->new(row => "{0:sprintf:$_}")->render([[42]]), $ok{$_},
        "sprintf:$_ still applies") for sort keys %ok;
}

# --- rendering must survive user code that drops our last reference --------
# A callback, an overloaded stringification or a tied FETCH runs arbitrary Perl
# in the middle of a render.  Nothing held a reference to the object, so that
# code could trigger DESTROY and free the compiled template out from under the
# loop (ASAN: heap-use-after-free in should_skip_row / render_field).
{
    my @q = ([1], [2], [3], [4]);
    my $cb_obj = Text::Stencil->new(row => '{0}-');
    my $out = $cb_obj->render_cb(sub {
        my $r = shift @q;
        undef $cb_obj if $r && $r->[0] == 1;   # last reference goes away here
        return $r;
    });
    is $out, '1-2-3-4-', 'render_cb survives a callback that destroys the object';

    {
        package TS_Selfdestruct;
        use overload '""' => sub { undef $TS_Selfdestruct::obj; 'o' }, fallback => 1;
    }
    our $obj = Text::Stencil->new(row => '{0}-{1}');
    local $TS_Selfdestruct::obj = $obj;
    my $ovl = $obj->render([[bless({}, 'TS_Selfdestruct'), 'b'], ['c', 'd']]);
    is $ovl, 'o-bc-d', 'render survives an overloaded value that destroys the object';
}

# --- one flagged template piece must not vouch for the others --------------
# tpl_high was computed only when no piece at all arrived flagged, so a decoded
# separator suppressed the high-byte scan of a byte-string row and the row's
# stray bytes shipped inside a UTF-8-flagged SV.
{
    my @mixed = (
        ['latin1 header, decoded row'   => { header => "Caf\xe9\n", row => "\x{2014} {0}\n" }],
        ['decoded header, latin1 row'   => { header => "\x{2014}\n", row => "Caf\xe9 {0}\n" }],
        ['latin1 footer, decoded sep'   => { row => '{0}', footer => "\xe9", separator => "\x{2014}" }],
    );
    for my $case (@mixed) {
        my ($what, $opts) = @$case;
        my $out = Text::Stencil->new(%$opts)->render([['x'], ['y']]);
        ok !(utf8::is_utf8($out) && !utf8::valid($out)),
            "$what does not yield flagged-but-malformed output";
    }
    # clone must re-decide the encoding of the piece it replaces
    my $c = Text::Stencil->new(row => '{0}', separator => "\x{2014}")
                ->clone(row => "\xe9{0}")->render([['a'], ['b']]);
    ok !(utf8::is_utf8($c) && !utf8::valid($c)),
        'clone re-decides the encoding of the row it replaces';
    # a wholly decoded template still comes back as characters
    my $u = Text::Stencil->new(row => "\x{2014}{0}")->render([['x']]);
    ok utf8::is_utf8($u), 'a fully decoded template still returns a character string';
}

# --- float:N must not truncate a large value into a different number -------
# Both float paths formatted into 64 bytes and clamped the length, so anything
# wider came back as a prefix of its own digits: float:2 was wrong from 1e61,
# float:30 from 1e32.  The fast path also handed printf an NV where it wanted a
# double, which formats garbage when perl is built -Duselongdouble.
{
    for my $p (2, 30) {
        for my $v ('1e32', '1e61', '-1e308', '3.14159') {
            # float formats a C double, so on a -Duselongdouble perl Perl's own
            # sprintf would print more precision than the XS ever sees; round
            # the oracle through a double so the comparison means the same
            # thing at every $Config{nvsize}
            my $want = sprintf '%.*f', $p, unpack('d', pack('d', $v));
            is(Text::Stencil->new(row => "{0:float:$p}")->render([[$v]]), $want,
                "float:$p on $v matches sprintf (fast path)");
            is(Text::Stencil->new(row => "{0:float:$p|raw}")->render([[$v]]), $want,
                "float:$p on $v matches sprintf (chained path)");
        }
    }
}

# --- a failing write must not be swallowed --------------------------------
# Every PerlIO_write return was ignored, so a read-only handle, a closed one or
# a full disk lost the output with no error at all.
{
    my $s = Text::Stencil->new(row => "{0}\n");
    open my $ro, '<', $0 or die "open $0: $!";
    like exception_from(sub { $s->render_to_fh($ro, [[1], [2]]) }),
        qr/write failed/, 'render_to_fh croaks on a handle it cannot write to';
    open my $closed, '>', File::Spec->devnull or die $!;
    close $closed;
    like exception_from(sub { $s->render_to_fh($closed, [[1]]) }),
        qr/write failed/, 'render_to_fh croaks on a closed handle';
    # a working handle is untouched by the check
    my $buf = '';
    open my $ok, '>', \$buf or die $!;
    $s->render_to_fh($ok, [[1], [2]]);
    close $ok;
    is $buf, "1\n2\n", 'a writable handle still receives everything';
}

# --- only an arrayref or hashref is a row ---------------------------------
# The stop check accepted any reference, so a callback returning e.g. \$x
# rendered an empty row and was called again forever, growing the buffer.
{
    my $s = Text::Stencil->new(row => '{0}-');
    for my $junk (['scalarref', sub { my $x = 1; \$x }],
                  ['coderef',   sub { sub { } }],
                  ['globref',   sub { \*STDOUT }],
                  ['qr//',      sub { qr/x/ }]) {
        my ($what, $mk) = @$junk;
        # disarm from a guard: a croak between alarm 10 and alarm 0 would
        # otherwise leave a live timer with $SIG{ALRM} back at DEFAULT, and
        # SIGALRM would kill the harness ten seconds later
        my $out = eval {
            local $SIG{ALRM} = sub { die "did not terminate\n" };
            my $disarm = TS_Alarm->new(10);
            $s->render_cb($mk);
        };
        is $out, '', "render_cb stops when the callback returns a $what";
    }
}

# --- transforms that quietly did the wrong thing --------------------------
{
    # replace with one parameter set no needle at all and returned the value
    is(Text::Stencil->new(row => '{0:replace:a}')->render([['abcabc']]), 'bcbc',
        'replace:OLD with no replacement deletes OLD');
    is(Text::Stencil->new(row => '{0:replace:a:}')->render([['abcabc']]), 'bcbc',
        '  ...the same as the explicit empty spelling');

    # HvUSEDKEYS reads the backing store, which a tied hash keeps empty
    my %h;
    my $tied = tie %h, 'TS_TiedHash', { a => 1, b => 2, c => 3 };
    is(Text::Stencil->new(row => '{0:count}')->render([[\%h]]), 3,
        'count sees the keys of a tied hash');
    is(Text::Stencil->new(row => '{0:count}')->render([[{ x => 1, y => 2 }]]), 2,
        '  ...and still counts a plain hash');

    # picking the SI tier by magnitude let rounding spill out of it
    is(Text::Stencil->new(row => '{0:number_si}')->render([['999.6']]), '1.0K',
        'number_si rounds up into the next tier instead of printing 1000');
    is(Text::Stencil->new(row => '{0:number_si}')->render([['999.4']]), '999',
        '  ...and leaves a value that rounds down alone');
    is(Text::Stencil->new(row => '{0:bytes_si}')->render([['1023.9']]), '1.0 KB',
        'bytes_si rounds up at its own 1024 boundary');
    is(Text::Stencil->new(row => '{0:bytes_si}')->render([['999.6']]), '1000 B',
        '  ...but 1000 bytes is not a kilobyte');

    # strftime reports "too big for the buffer" as 0, which rendered as empty
    cmp_ok length(Text::Stencil->new(row => '{0:date:' . ('%c' x 20) . '}')
                      ->render([[1700000000]])), '>', 256,
        'date grows its buffer instead of rendering a long format as empty';

    # columns repeated a field once per reference
    is_deeply(Text::Stencil->new(row => '{2}{0}{2}{0}')->columns, [2, 0],
        'columns lists each index once, in first-appearance order');
    is_deeply(Text::Stencil->new(row => '{a}{b}{a}')->columns, ['a', 'b'],
        '  ...and likewise for named fields');
}

# --- user code running mid-render must not invalidate what we are holding --
# render()/render_to_fh() held an SV** into the rows array across callbacks, so
# Perl that emptied the array left it dangling (SIGSEGV); render_sorted() cached
# raw key PVs before qsort, so freeing a row mid-collection gave the comparator
# freed memory (ASAN: heap-use-after-free in sort_cmp_multi).
{
    our @ROWS;
    {   package TS_Clears;
        sub TIEHASH { bless {}, shift }
        sub FETCH   { @main::ROWS = (); 'x' }
        sub STORE {} sub DELETE {} sub CLEAR {} sub EXISTS { 0 }
        sub FIRSTKEY { } sub NEXTKEY { }
    }
    {   package TS_Frees;
        sub TIEHASH { bless {}, shift }
        sub FETCH   { delete $main::ROWS[0]{a}; 'b' }
        sub STORE {} sub DELETE {} sub CLEAR {} sub EXISTS { 1 }
        sub FIRSTKEY { } sub NEXTKEY { }
    }

    my $t = Text::Stencil->new(row => '{a}{b}|');
    tie my %clears, 'TS_Clears';
    @ROWS = (\%clears, { a => 1, b => 2 });
    is eval { $t->render(\@ROWS) }, 'xx|', 'render survives a row that empties the rows array';

    @ROWS = (\%clears, { a => 1, b => 2 });
    my $buf = '';
    open my $fh, '>', \$buf or die $!;
    ok eval { $t->render_to_fh($fh, \@ROWS); 1 }, 'render_to_fh survives the same';
    close $fh;

    my $s = Text::Stencil->new(row => "{a}\n");
    tie my %frees, 'TS_Frees';
    @ROWS = ({ a => ('A' x 600) }, \%frees);
    ok eval { $s->render_sorted(\@ROWS, 'a'); 1 },
        'render_sorted survives a key fetch that frees an earlier row';
}

# --- a nested render must not wipe the outer render's encoding state -------
{
    our $T;
    {   package TS_Reenter;
        use overload '""' => sub { $main::T->render_one(['x', 'y']); 'Z' }, fallback => 1;
    }
    $T = Text::Stencil->new(row => "\x{263A}{0}{1}\n");
    my $out = $T->render([[ "\xff\xfe", bless({}, 'TS_Reenter') ]]);
    ok !(utf8::is_utf8($out) && !utf8::valid($out)),
        'a re-entrant render does not leave the outer output flagged-but-malformed';
}

# --- uc/lc are ASCII-only, whatever LC_CTYPE says -------------------------
# toupper/tolower follow the locale, and an 8-bit one maps 0xE0-0xFE onto
# 0xC0-0xDE -- UTF-8 lead bytes -- corrupting a flagged value.
{
    is(Text::Stencil->new(row => '{0:uc}')->render([["\xe9"]]), "\xe9",
        'uc leaves a high byte alone');
    is(Text::Stencil->new(row => '{0:lc}')->render([["\xc9"]]), "\xc9",
        'lc leaves a high byte alone');
    is(Text::Stencil->new(row => '{0:uc}')->render([['abc']]), 'ABC', 'uc still works on ASCII');
}

# --- an unknown transform is an error, not a silent raw passthrough --------
{
    eval { Text::Stencil->new(row => '{0:hmtl}') };
    like $@, qr/unknown transform/, 'a typo in an escaping transform is rejected';
    eval { Text::Stencil->new(row => '{0:HTML}') };
    like $@, qr/unknown transform/, 'transform names are case-sensitive';
    eval { Text::Stencil->new(row => '{0: html}') };
    like $@, qr/unknown transform/, 'stray whitespace is not silently ignored';
    eval { Text::Stencil->new(row => '{0:|html}') };
    like $@, qr/empty transform in chain/, 'an empty chain segment says so';
    ok eval { Text::Stencil->new(row => '{0:raw}'); 1 }, 'raw still compiles';
    ok eval { Text::Stencil->new(row => '{0:trim|uc|html}'); 1 }, 'a real chain still compiles';
}

# --- clone must survive an argument that destroys the object ---------------
# clone reads the original's header/footer/sep buffers and calls SvPV on its
# arguments, so an overloaded "" among them could free the original mid-call
# (SIGSEGV), and afterwards SvRV(self) was no longer a reference to bless with.
{
    our $VICTIM;
    {   package TS_CloneKiller;
        use overload '""' => sub { undef $main::VICTIM; '{0}row' }, fallback => 1;
    }
    $VICTIM = Text::Stencil->new(header => ('H' x 800), row => '{0}', footer => ('F' x 800));
    my $c = eval { $VICTIM->clone(row => bless({}, 'TS_CloneKiller')) };
    ok defined $c, 'clone survives an argument that destroys the original';
    isa_ok $c, 'Text::Stencil', '  ...and still returns a blessed object';
}

# --- transforms that truncated or wrapped their own output ----------------
{
    like(Text::Stencil->new(row => '{0:number_si}')->render([['1e45']]), qr/P$/,
        'number_si keeps its suffix instead of truncating at 32 bytes');
    like(Text::Stencil->new(row => '{0:bytes_si}')->render([['1e45']]), qr/EB$/,
        '  ...and so does bytes_si');
    unlike(Text::Stencil->new(row => '{0:elapsed}')->render([['9999999999999999999']]), qr/-/,
        'elapsed saturates instead of going negative');
}

# --- an unusable filehandle must not silently buffer to a string ----------
{
    my $t = Text::Stencil->new(row => "{0}\n");
    open my $closed, '>', File::Spec->devnull or die $!;
    close $closed;
    my @q = ([1], [2]);
    like exception_from(sub { $t->render_cb(sub { shift @q }, $closed) }),
        qr/not open for writing/, 'render_cb rejects a closed filehandle';
}

# --- the rows arrayref itself must be pinned ------------------------------
# The AV arrives from the typemap with no reference held, so Perl running
# mid-render (an overloaded "") could drop the caller's last one and leave
# av_fetch reading a freed body -- SIGSEGV in all three array-taking methods.
{
    our %H;
    {   package TS_DropsRows;
        use overload '""' => sub { delete $main::H{rows}; 'z' }, fallback => 1;
    }
    my $s = Text::Stencil->new(row => "{0}|{1}\n");
    my @mk = ([bless({}, 'TS_DropsRows'), 'one'], ['a', 'two'], ['b', 'three']);

    $H{rows} = [ @mk ];
    ok defined eval { $s->render($H{rows}) }, 'render pins the rows arrayref';

    $H{rows} = [ @mk ];
    my $buf = '';
    open my $fh, '>', \$buf or die $!;
    ok eval { $s->render_to_fh($fh, $H{rows}); 1 }, 'render_to_fh pins it too';
    close $fh;

    $H{rows} = [ @mk ];
    ok defined eval { $s->render_sorted($H{rows}, 0) }, 'render_sorted pins it too';
}

# --- new() must not hold the class name across argument overloads ---------
{
    our $C;
    {   package TS_DropsClass;
        use overload '""' => sub { undef $main::C; "{0}\n" }, fallback => 1;
    }
    $C = 'Text::'; $C .= 'Stencil';
    ok defined eval { $C->new(row => bless({}, 'TS_DropsClass')) },
        'new survives an argument that frees the class name';
}

# --- the encoding state must survive a skipped row and a caught croak -----
{
    our $S;
    {   package TS_SkipReenter;
        use overload '""' => sub { $main::S->render_one([(0) x 9, 1]); 'X' }, fallback => 1;
    }
    $S = Text::Stencil->new(row => '{0}{1}{2}{3}', skip_if => 9);
    my $out = $S->render([[ "\x{263A}", "\xff\xfe", bless({}, 'TS_SkipReenter'), "\x{263A}" ]]);
    ok !(utf8::is_utf8($out) && !utf8::valid($out)),
        'a nested render_one on a skipped row does not eat the outer state';

    {   package TS_Dies;    use overload '""' => sub { die "boom\n" }, fallback => 1; }
    {   package TS_CatchesCroak;
        use overload '""' => sub {
            eval { $main::S2->render([[ "\x{263A}", bless({}, 'TS_Dies') ]]) }; 'X';
        }, fallback => 1;
    }
    our $S2 = Text::Stencil->new(row => '{0}{1}{2}');
    my $o2 = $S2->render([[ "\xff\xfe", bless({}, 'TS_CatchesCroak'), "\x{263A}" ]]);
    ok !(utf8::is_utf8($o2) && !utf8::valid($o2)),
        'a nested render that croaks and is caught does not either';
}

# --- the blessed IV is only a pointer, so it has to be checked ------------
{
    my $o = Text::Stencil->new(row => '{0}');
    Text::Stencil::DESTROY($o);
    ok eval { undef $o; 1 }, 'an explicit DESTROY does not leave a double free';

    my $x = 0;
    like exception_from(sub { (bless \$x, 'Text::Stencil')->render([[1]]) }),
        qr/not a Text::Stencil object/, 'a foreign ref blessed into the class croaks';

    # The pin used to run SvRV and a refcount bump before the check, so a
    # non-reference invocant had its IV -- or its PV buffer -- incremented and
    # later decremented as if it were an SV.
    for my $bad (undef, 5, 'Text::Stencil', "AAAAAAAA\0\0\0\0AAAAAAAA") {
        my $label = defined $bad ? "'" . substr($bad, 0, 12) . "'" : 'undef';
        like exception_from(sub { Text::Stencil::render($bad, [[1, 2]]) }),
            qr/not a Text::Stencil object/, "render on a non-reference invocant ($label) croaks";
    }
    like exception_from(sub { Text::Stencil::render_cb(undef, sub { undef }) }),
        qr/not a Text::Stencil object/, 'render_cb likewise';
    like exception_from(sub { Text::Stencil::clone(undef, row => '{0}') }),
        qr/not a Text::Stencil object/, 'clone likewise';

    # A blessed IV alone proved nothing: any non-zero integer was dereferenced
    # as a tpl_compiled *.  Ours now carry magic, so a look-alike is rejected
    # without ever following the pointer.
    my $y = 1;
    like exception_from(sub { (bless \$y, 'Text::Stencil')->render([[1]]) }),
        qr/not a Text::Stencil object/, 'a look-alike blessed IV is rejected, not followed';
}

# --- the struct outlives any single owner or call -------------------------
# The pin held the SV, not the malloc'd struct, so an explicit ->DESTROY from
# inside a callback freed it mid-call; and a deep copy of the object handed a
# second SV the same pointer, so both freed it.
{
    {   package TS_SelfDestroy;
        use overload '""' => sub { $main::victim->DESTROY; 'X{0}' }, fallback => 1;
    }
    our $victim = Text::Stencil->new(row => "{0}\n", header => "H\n", footer => "F\n");
    ok eval { $victim->clone(row => bless {}, 'TS_SelfDestroy'); 1 },
        'an explicit DESTROY mid-call defers the free instead of pulling the struct';

    our $v2 = Text::Stencil->new(row => '{0}|');
    {   package TS_SelfDestroy2;
        use overload '""' => sub { $main::v2->DESTROY; 'z' }, fallback => 1;
    }
    ok eval { $v2->render([[bless({}, 'TS_SelfDestroy2')], ['b']]); 1 },
        '  ...and likewise during render';

    SKIP: {
        skip 'Clone not available', 2 unless eval { require Clone; 1 };
        my $o = Text::Stencil->new('{0}');
        my $c = Clone::clone($o);
        # the copy is not an owner, so using it must croak rather than share
        like exception_from(sub { $c->render([[1]]) }),
            qr/not a Text::Stencil object/, 'a Clone::clone copy is inert, not a second owner';
        ok eval { undef $c; undef $o; 1 },
            '  ...and dropping both does not double free';
    }

    SKIP: {
        skip 'Storable not available', 1 unless eval { require Storable; 1 };
        like exception_from(sub { Storable::dclone(Text::Stencil->new(row => '{0}')) }),
            qr/cannot be serialised/, 'Storable cloning is refused rather than double-freeing';
    }
}

# --- leaks -----------------------------------------------------------------
SKIP: {
    skip 'needs /proc/self/status', 3 unless defined rss_kb();
    skip 'RSS is meaningless under a sanitizer/valgrind', 3 if instrumented();

    my $s = Text::Stencil->new(row => '{0:int} {2:raw} {4:html}');
    $s->columns for 1 .. 20_000;             # warm up allocator
    my $before = rss_kb();
    $s->columns for 1 .. 200_000;
    my $grew = rss_kb() - $before;
    cmp_ok $grew, '<', 4096, "columns() does not leak its AV (grew ${grew}KB over 200k calls)";

    # every failed new() leaked the whole partially-built template
    eval { Text::Stencil->new(row => '{0:uc|count}') } for 1 .. 2_000;
    $before = rss_kb();
    eval { Text::Stencil->new(row => '{0:uc|count}') } for 1 .. 50_000;
    $grew = rss_kb() - $before;
    cmp_ok $grew, '<', 4096, "a croaking new() frees the template (grew ${grew}KB over 50k calls)";

    # a nested render re-attached its own buffer and orphaned ours
    my $r = Text::Stencil->new(row => ('y' x 500) . '{0:raw}');
    my $nested = sub {
        my $i = 0;
        $r->render_cb(sub { return undef if $i++ >= 3; $r->render_one(['nested']); ['x'] });
    };
    $nested->() for 1 .. 200;
    $before = rss_kb();
    $nested->() for 1 .. 20_000;
    $grew = rss_kb() - $before;
    cmp_ok $grew, '<', 4096, "re-entrant render does not leak (grew ${grew}KB over 20k calls)";
}

{   # hash keys carrying the UTF-8 flag were fetched with a positive
    # klen, which only ever matches a non-UTF8 HEK -- so every field naming a
    # non-ASCII key silently rendered empty.  from_file always decodes, so any
    # template with such a field name was dead on arrival.
    my $key = "caf\x{e9}"; utf8::upgrade($key);
    my $tpl = "{caf\x{e9}}"; utf8::upgrade($tpl);
    my $rows = [ { $key => 'VALUE' } ];

    is +Text::Stencil->new(row => $tpl)->render($rows), 'VALUE',
        'a flagged key is found by a flagged template';
    is +Text::Stencil->new(row => $tpl)->render_one($rows->[0]), 'VALUE',
        'render_one finds a flagged key';

    my $co = "{missing:coalesce:caf\x{e9}:dflt}"; utf8::upgrade($co);
    is +Text::Stencil->new(row => $co)->render($rows), 'VALUE',
        'coalesce falls back to a flagged key';

    is +Text::Stencil->new(row => 'x', skip_unless => $key)->render($rows), 'x',
        'skip_unless sees a flagged key';
    is +Text::Stencil->new(row => 'x', skip_if => $key)->render($rows), '',
        'skip_if sees a flagged key';

    my $many = [ map +{ $key => $_ }, qw(c a b) ];
    is +Text::Stencil->new(row => $tpl)->render_sorted($many, $key), 'abc',
        'render_sorted sorts on a flagged key';

    my ($tfh, $fn) = tempfile(UNLINK => 1);
    binmode $tfh, ':encoding(UTF-8)';
    print $tfh "__ROW__\n{caf\x{e9}}\n";
    close $tfh;
    is +Text::Stencil->from_file($fn)->render($rows), "VALUE\n",
        'from_file handles a non-ASCII field name';
}

{   # is_field_truthy used a raw hv_fetch, so a tied hash handed back an
    # unmaterialised PVLV and the skip test read it before FETCH ever ran.
    my %r; tie %r, 'TS_TiedHash', { v => 'keep', gone => 1 };
    is +Text::Stencil->new(row => '{v};', skip_if => 'gone')->render([\%r]), '',
        'skip_if runs FETCH on a tied hash row';
    my %r2; tie %r2, 'TS_TiedHash', { v => 'keep', ok => 1 };
    is +Text::Stencil->new(row => '{v};', skip_unless => 'ok')->render([\%r2]), 'keep;',
        'skip_unless runs FETCH on a tied hash row';
    my %r3; tie %r3, 'TS_TiedHash', { v => 'keep' };
    is +Text::Stencil->new(row => '{v};', skip_unless => 'ok')->render([\%r3]), '',
        'skip_unless still skips when the tied key is absent';
}

{   # new() on an instance stringified the invocant into gv_stashpv, so
    # the object was blessed into a per-address junk stash with no DESTROY,
    # leaking the whole compiled template.
    my $obj = Text::Stencil->new(row => '{0}');
    my $o2  = $obj->new(row => '{0}!');
    is ref($o2), 'Text::Stencil', 'new() on an instance blesses into the real class';
    is $o2->render([['a']]), 'a!', 'the instance-built object renders';
}

{   # the coalesce fallback parsed its column index without any of the
    # overflow checking a normal field reference gets, so 2**32 wrapped to 0.
    is +Text::Stencil->new(row => '{1:coalesce:4294967296:dflt}')->render([['P', '']]), 'dflt',
        'an out-of-range coalesce column falls through instead of wrapping';
    is +Text::Stencil->new(row => '{1:coalesce:0:dflt}')->render([['P', '']]), 'P',
        'an in-range coalesce column still resolves';
}

{   # mid-chain integer scanners accumulated v*10+d with no guard, so a
    # field of more than 19 digits wrapped to an arbitrary value.
    my $big = '9' x 23;
    my $max = '9223372036854775807';
    is +Text::Stencil->new(row => '{0:trim|int}')->render([[$big]]), $max,
        'mid-chain int saturates instead of wrapping';
    is +Text::Stencil->new(row => '{0:trim|int_comma}')->render([[$big]]),
        '9,223,372,036,854,775,807', 'mid-chain int_comma saturates';
    is +Text::Stencil->new(row => '{0:plural:item}')->render([[$big]]), "$max items",
        'plural saturates instead of wrapping';
}

{   # a parameterless {0:substr} truncated to zero and {0:sprintf} emitted
    # nothing at all; both now pass the value through.
    is +Text::Stencil->new(row => '{0:substr}')->render([['hello']]), 'hello',
        'bare substr passes the value through';
    is +Text::Stencil->new(row => '{0:sprintf}')->render([['hello']]), 'hello',
        'bare sprintf passes the value through';
}

SKIP: {
    # no render path protected its buffer against a croak raised from
    # inside the render -- a dying tied FETCH, say -- so the unwind ran straight
    # past the free.  render() lost its whole detached render_buf and render_cb
    # its entire 64KB stream buffer, on every single failure.  All four paths
    # now hand the buffer to the savestack for the duration.
    skip 'needs /proc and a non-instrumented build', 4 if instrumented() || !defined vmsize_kb();
    {   package TS_DyingFetch;
        sub TIEHASH  { bless {}, shift }
        sub FETCH    { die "boom\n" }
        sub FIRSTKEY { 'v' } sub NEXTKEY { undef } sub EXISTS { 1 }
        sub STORE {} sub DELETE {} sub CLEAR {} sub SCALAR { 1 }
    }
    my %h; tie %h, 'TS_DyingFetch';
    my $r = Text::Stencil->new(row => "{v}\n");
    open my $null, '>', File::Spec->devnull or skip 'no devnull', 4;

    # render and render_to_fh size their buffers from the row count, so they
    # need a big row set for one lost buffer to stand out above the noise.
    my $many = [ (\%h) x 2000 ];
    for my $case (['render',        200, sub { $r->render($many) }],
                  ['render_one', 20_000, sub { $r->render_one(\%h) }],
                  ['render_cb',    5_000, sub { $r->render_cb(sub { \%h }, $null) }],
                  ['render_to_fh',   200, sub { $r->render_to_fh($null, $many) }]) {
        my ($name, $n, $call) = @$case;
        eval { $call->() } for 1 .. 200;
        my $before = vmsize_kb();
        eval { $call->() } for 1 .. $n;
        my $grew = vmsize_kb() - $before;
        cmp_ok $grew, '<', 4096,
            "$name keeps its stream buffer when a render croaks (grew ${grew}KB over $n)";
    }
}

{   # The supported ways to stop a render_cb stream. Leaving the callback with
    # last/next/goto to an outer label is not among them, but it is contained
    # rather than catastrophic now -- see the non-local-exit block below.
    my $s = Text::Stencil->new(row => '{0}|');

    my $n = 0;
    is $s->render_cb(sub { $n < 3 ? [$n++] : undef }), '0|1|2|',
        'returning undef stops the stream cleanly';
    is $s->row_count, 3, '  with the right row count';

    my $i = 0;
    my $err = exception_from(sub {
        $s->render_cb(sub { $i++ ? die "stop here\n" : ['a'] })
    });
    is $err, "stop here\n", 'die propagates out of render_cb unchanged';

    for my $stop ('', 'plain string', \'scalarref', sub { 1 }, qr/x/) {
        my $j = 0;
        my $out = $s->render_cb(sub { $j++ ? $stop : ['z'] });
        is $out, 'z|', 'a non-row return value stops the stream';
    }
}

{   # last/next/goto out of the callback unwound straight through our C frame:
    # a pp_iter panic, or the caller resuming with the render half-done and a
    # lexical clobbered (ASAN: heap overflow in Perl_pp_unstack). The callback
    # now runs on its own stackinfo, so the jump becomes a catchable die.
    # These assert the containment, not the wording perl chooses.
    no warnings 'exiting';
    my $s = Text::Stencil->new(row => '{0}|');

    my ($n, $tail) = (0, 0);
    my $e_last = exception_from(sub {
        TS_NL1: for my $i (1 .. 3) {
            $s->render_cb(sub { $n++ >= 2 ? (last TS_NL1) : [$n] });
        }
        $tail++;
    });
    like $e_last, qr/Label not found/, 'last out of the callback is a catchable die';
    is $tail, 0, '  and the statement after the loop never runs';
    is $n, 3, '  and the callback ran exactly as far as it should have';

    ($n, $tail) = (0, 0);
    my $e_next = exception_from(sub {
        TS_NL2: for my $i (1 .. 3) {
            $s->render_cb(sub { $n++ >= 2 ? (next TS_NL2) : [$n] });
        }
        $tail++;
    });
    like $e_next, qr/Label not found/, 'next out of the callback is a catchable die';
    is $tail, 0, '  and it does not fall through either';

    # goto: the failure that used to run the trailing statements twice
    my $ran = 0;
    my $e_goto = exception_from(sub {
        my $k = 0;
        $s->render_cb(sub { $k++ >= 2 ? (goto TS_NL3) : [$k] });
        TS_NL3: $ran++;
    });
    like $e_goto, qr/label TS_NL3/i, 'goto out of the callback is a catchable die';
    is $ran, 0, '  and the label body does not run at all';

    # the object is still usable afterwards -- the unwind used to leave the
    # render buffer armed and the next render tripped over it
    my $m = 0;
    is $s->render_cb(sub { $m < 2 ? [$m++] : undef }), '0|1|',
        'the renderer still works after a contained non-local exit';
    is $s->row_count, 2, '  with a correct row count';
}

{   # columns() built its keys with newSVpvn, dropping the UTF-8 flag that
    # every other consumer of op->key had been taught to carry.  The returned
    # key then did not match the key the template itself matches, which breaks
    # the one thing columns() is for: indexing the caller's own rows.
    my $key = "n\x{101}me";
    my $s   = Text::Stencil->new(row => "[{n\x{101}me}]");
    my %row = ($key => 'Ada');
    is $s->render_one(\%row), '[Ada]', 'a wide-character key renders';
    my $c = $s->columns->[0];
    ok utf8::is_utf8($c), 'columns() keeps the UTF-8 flag on a wide key';
    is $c, $key, '  and equals the key the template matches';
    ok exists $row{$c}, '  so it can index the caller row';

    # an ASCII key from a flagged template must stay usable too
    my $a = Text::Stencil->new(row => "\x{2014}{id}")->columns->[0];
    is $a, 'id', 'an ASCII key from a flagged template is unchanged';
    # it may carry the template's UTF-8 flag, which is a no-op for ASCII; what
    # has to hold is that it still indexes the caller's own hash
    ok exists { id => 1 }->{$a}, '  and still indexes an ASCII key';
}

{   # av_element only ran get-magic when the AV itself was magical, so a plain
    # array holding a tied element -- tie $row[0], ... -- was read raw and came
    # back empty.  render_sorted used SvPV and did honour it, which made the
    # value appear only after a sort had materialised it into the SV.
    {   package TS_TiedElem;
        sub TIESCALAR { bless { v => $_[1] }, $_[0] }
        sub FETCH     { $_[0]{v} }
        sub STORE     {}
    }
    my $s = Text::Stencil->new(row => '[{0}]');

    my @a; tie $a[0], 'TS_TiedElem', 'HELLO';
    is $s->render_one(\@a), '[HELLO]', 'render_one runs FETCH on a tied element';

    my @b; tie $b[0], 'TS_TiedElem', 'HELLO';
    is $s->render([\@b]), '[HELLO]', 'render runs FETCH on a tied element';

    my @c; tie $c[0], 'TS_TiedElem', 'HELLO';
    my $out = '';
    open my $fh, '>', \$out or die;
    $s->render_to_fh($fh, [\@c]);
    close $fh;
    is $out, '[HELLO]', 'render_to_fh runs FETCH on a tied element';

    my @d; tie $d[0], 'TS_TiedElem', 'HELLO';
    my $n = 0;
    is $s->render_cb(sub { $n++ ? undef : \@d }), '[HELLO]',
        'render_cb runs FETCH on a tied element';

    # the asymmetry that made this hide: sorting materialised the value, so a
    # later render started returning it
    my @e; tie $e[0], 'TS_TiedElem', 'X';
    my $before = $s->render_one(\@e);
    Text::Stencil->new(row => '[{0}]')->render_sorted([\@e], 0);
    is "$before/" . $s->render_one(\@e), '[X]/[X]',
        'the value does not depend on whether a sort ran first';

    my @f; tie $f[0], 'TS_TiedElem', 1;
    is +Text::Stencil->new(row => '[{1}]', skip_if => 0)->render([\@f]), '',
        'skip_if runs FETCH on a tied element';
}

{   # First in a chain, sprintf numifies the way int and float do -- it used to
    # scrape digits out of the text instead, so {0:sprintf:%d} on 3.9 printed 39
    # and disagreed with {0:int} on the same value.  Mid-chain there is no SV
    # left to numify, so both fall back to digit-taking, and that accumulator
    # (the one that never got a saturation guard) must still saturate.
    my $big = '9' x 23;
    is +Text::Stencil->new(row => '{0:sprintf:%d}')->render([[$big]]),
       +Text::Stencil->new(row => '{0:int}')->render([[$big]]),
        'first-in-chain sprintf:%d numifies exactly like int';
    is +Text::Stencil->new(row => '{0:raw|sprintf:%d}')->render([[$big]]),
        '9223372036854775807', 'mid-chain sprintf:%d saturates';
    is +Text::Stencil->new(row => '{0:raw|int}')->render([[$big]]),
        '9223372036854775807', '  matching the mid-chain int path';
    is +Text::Stencil->new(row => '{0:sprintf:%d}')->render([['42']]), '42',
        '  and an ordinary value is untouched';

    # A format the formatter rejects must not be numified either, or the value
    # it is documented to pass through unchanged arrives already mangled.
    for my $bad ('%d%d', '%*d', '%ld', '%hhd', '%.*f', '%2$d', '%sx') {
        is +Text::Stencil->new(row => "{0:sprintf:$bad}")->render([['abc']]), 'abc',
            "an unsupported format ($bad) passes the value through untouched";
    }
    # A format too long to assemble is also unsupported. Deciding that and
    # deciding how to numify the value are the same question, so they are asked
    # of one function -- when they were two, the value passed through here had
    # already been numified to 0 by the other one.
    # 58 and 59 sit below the cutoff: without them the oracle's '0' arm never
    # runs and the loop cannot tell the cutoff from "reject everything".
    for my $n (58, 59, 60, 62, 64, 80) {
        my $long = '%' . ('-' x $n) . 'd';
        # the 58/59 arms are the supported ones, so the module numifies 'abc'
        # and perl warns exactly as its own sprintf "%d" would -- correct, but
        # not worth two lines of stderr in every smoke report
        no warnings 'numeric';
        my $got  = Text::Stencil->new(row => "{0:sprintf:$long}")->render([['abc']]);
        is $got, ($n + 2 >= 62 ? 'abc' : '0'),
            "a ${\($n + 2)}-character format is handled consistently";
    }

    # the cases that made this worth fixing: a float formatted as an integer
    for my $c ([ '%d', '3.9' ], [ '%d', '-3.9' ], [ '%d', '1000000.25' ],
               [ '%x', '255.5' ], [ '%d', '2026-08-03' ], [ '%.2f', '0x1f' ],
               [ '%.2f', '1.5' ], [ '%e', '1500' ], [ '%o', '9.9' ]) {
        my ($fmt, $val) = @$c;
        # the oracle is deliberately fed non-numeric input; that is the point of
        # the comparison, so keep its warning out of every smoke report
        my $want = do { no warnings 'numeric'; sprintf $fmt, $val };
        is +Text::Stencil->new(row => "{0:sprintf:$fmt}")->render([[$val]]), $want,
            "sprintf:$fmt on '$val' agrees with perl";
    }
}

{   # skip_if/skip_unless and the render_sorted sort spec narrowed an IV
    # straight into an int, so 2**32 aliased onto column 0 -- the same defect
    # that was fixed for template and coalesce indices.
    my $rows = [['ZERO', 'ONE']];
    ok !eval { Text::Stencil->new(row => '[{1}]', skip_if => 4294967296); 1 },
        'an out-of-range skip_if column is rejected';
    like $@, qr/out of range/, '  with a clear message';
    ok !eval { Text::Stencil->new(row => '[{1}]', skip_unless => 4294967296); 1 },
        'an out-of-range skip_unless column is rejected';

    my $s = Text::Stencil->new(row => '[{1}]');
    ok !eval { $s->render_sorted($rows, 4294967296); 1 },
        'an out-of-range sort column is rejected';
    ok !eval { $s->render_sorted($rows, [4294967296]); 1 },
        '  in the multi-field form too';

    is +Text::Stencil->new(row => '[{1}]', skip_if => 0)->render($rows), '',
        'an in-range skip_if column still works';
    is +Text::Stencil->new(row => '[{0}]', skip_if => -1)->render($rows), '',
        '  including a negative one';
    is $s->render_sorted([['b','B'],['a','A']], -1), '[A][B]',
        'a negative sort column still works';
}

{   # the '-' descending shorthand was handled only in the scalar form, so the
    # multi-field form sorted by a key literally named "-name", found nothing,
    # and silently returned the rows unsorted -- which {descending} could not
    # rescue either.
    my $h = Text::Stencil->new(row => '{n};');
    my @r = ({n => 'a'}, {n => 'b'}, {n => 'c'});
    is $h->render_sorted(\@r, '-n'),   'c;b;a;', "the scalar '-' shorthand descends";
    is $h->render_sorted(\@r, ['-n']), 'c;b;a;', "the multi-field '-' shorthand descends too";
    is $h->render_sorted(\@r, ['n']),  'a;b;c;', '  and a plain name still ascends';

    my $m = Text::Stencil->new(row => '{a}{b};');
    my @mr = ({a=>1,b=>'y'}, {a=>1,b=>'x'}, {a=>2,b=>'z'});
    is $m->render_sorted(\@mr, ['a','b']),  '1x;1y;2z;', 'multi-field ascending';
    is $m->render_sorted(\@mr, ['-a','b']), '2z;1y;1x;',
        "a '-' anywhere turns the whole sort around";
}

{   # render_one was the one render path that did not pin its row SV.  Field
    # rendering runs Perl (tie, overload) that can drop the caller's last
    # reference, and perl then hands the recycled SV head straight back out --
    # so the render read fields out of whatever took its place.
    {   package TS_Recycler;
        use overload '""' => sub {
            @main::TS_ROWS = ();                        # free the SV still in use
            push @main::TS_HOLD, undef;                 # reclaim its head
            $main::TS_HOLD[-1] = \@main::TS_OTHER;      # aim it elsewhere
            'K';
        }, fallback => 1;
        sub new { bless {}, shift }
    }
    our (@TS_ROWS, @TS_HOLD, $TS_KEEP);
    our @TS_OTHER = ('OTHER-A', 'OTHER-B', 'OTHER-C');
    my $s = Text::Stencil->new(row => '<{0}|{1}|{2}>');
    @TS_ROWS = ( [ TS_Recycler->new(), 'real1', 'real2' ] );
    $TS_KEEP = $TS_ROWS[0];                             # keep the AV, not the RV head
    is $s->render_one($TS_ROWS[0]), '<K|real1|real2>',
        'render_one pins its row against a recycling overload';
}

{   # render_sorted stored borrowed SvPV pointers as sort keys.  Pinning the SV
    # keeps it alive but not its buffer: reading a later row's key can run Perl
    # that grows an earlier one in place, freeing the PV the comparator still
    # points at.  ASAN caught this as a heap-use-after-free in the comparator.
    {   package TS_Grower;
        use overload '""' => sub { $main::TS_R0{k} = 'Z' x 200_000; 'mmm' }, fallback => 1;
        sub new { bless {}, shift }
    }
    our %TS_R0 = ( k => 'A' x 4000 );
    my $out = Text::Stencil->new(row => '[{k}]')->render_sorted(
        [ \%TS_R0, { k => TS_Grower->new() }, { k => 'b' }, { k => 'c' } ], 'k');
    like $out, qr/\[b\]/, 'render_sorted survives a key that reallocs an earlier key';
    like $out, qr/\[mmm\]/, '  and still sorts on the stringified value';

    # the array-mode path stores keys the same way
    {   package TS_GrowerA;
        use overload '""' => sub { $main::TS_A0->[0] = 'Z' x 200_000; 'mmm' }, fallback => 1;
        sub new { bless {}, shift }
    }
    our $TS_A0 = [ 'A' x 4000 ];
    my $o2 = Text::Stencil->new(row => '[{0}]')->render_sorted(
        [ $TS_A0, [ TS_GrowerA->new() ], ['b'], ['c'] ], 0);
    like $o2, qr/\[b\]/, 'the array-mode sort key is copied too';
}

{   # new() and clone() held raw PVs of earlier arguments while stringifying
    # later ones; an overloaded argument that grows an earlier string in place
    # freed the buffer tpl_compile was about to memcpy.
    {   package TS_ArgGrower;
        use overload '""' => sub { $main::TS_HDR = 'Z' x 300_000; '<{0}>' }, fallback => 1;
        sub new { bless {}, shift }
    }
    our $TS_HDR = 'HDR' . ('h' x 4000);
    my $s = Text::Stencil->new(header => $TS_HDR, row => TS_ArgGrower->new());
    like $s->render([['x']]), qr/\AHDRh+<x>\z/,
        'new() copies each template piece before a later argument can move it';

    our $TS_SEP = 'SEP' . ('s' x 4000);
    my $base = Text::Stencil->new(row => '{0}');
    my $c = $base->clone(separator => $TS_SEP, row => TS_ArgGrower->new());
    like $c->render([['x'], ['y']]), qr/\A<x>SEPs+<y>\z/,
        'clone() copies its pieces too';
}

{   # a nested render left its own row count behind, so the outer render
    # reported the inner one's total
    {   package TS_NestedCount;
        use overload '""' => sub { $main::TS_OBJ->render([[1], [2]]); 'N' }, fallback => 1;
        sub new { bless {}, shift }
    }
    our $TS_OBJ = Text::Stencil->new(row => '{0};');
    $TS_OBJ->render([[TS_NestedCount->new()], [2], [3], [4], [5]]);
    is $TS_OBJ->row_count, 5, 'a nested render does not clobber the outer row_count';

    # render_cb re-set the count after each row, so only a nested render in the
    # callback that *stops* the stream was left standing
    my $i = 0;
    $TS_OBJ->render_cb(sub {
        return [$i++] if $i < 3;
        $TS_OBJ->render([map { [$_] } 1 .. 7]);
        undef;
    });
    is $TS_OBJ->row_count, 3, '  including a nested render in the stopping callback';
}

SKIP: {
    # render_to_fh streams in 64KB chunks but sized its buffer from the row
    # count, so a large render reserved hundreds of MB it never used and could
    # hit an address-space limit that render_cb sails through.
    skip 'needs /proc and a non-instrumented build', 1 if instrumented() || !defined vmpeak_kb();
    my $s = Text::Stencil->new(row => "{0}\n");
    my @rows = map { [$_] } 1 .. 200_000;
    open my $null, '>', File::Spec->devnull or skip 'no devnull', 1;
    my $before = vmpeak_kb();
    $s->render_to_fh($null, \@rows);
    my $grew = vmpeak_kb() - $before;
    cmp_ok $grew, '<', 32_768,
        "render_to_fh does not reserve the whole output (peak grew ${grew}KB for 200k rows)";
}

{   # every croak carries the distribution prefix, so a caller can match on it
    my @msgs;
    push @msgs, exception_from(sub { Text::Stencil->new(row => '{0}', 'odd') });
    push @msgs, exception_from(sub { Text::Stencil->new(row => '{0}')->clone(separator => ',') });
    push @msgs, exception_from(sub { Text::Stencil->new(row => '{0}')->render_cb('not a coderef') });
    for my $m (@msgs) {
        like $m, qr/^Text::Stencil: /, 'the error message carries the class prefix';
    }
}

{   # The sort-key NAMES were still borrowed SvPV pointers after the row VALUES
    # were fixed, and they are re-read per row inside a loop that runs user
    # Perl.  An overload that reassigns the caller's key variable reallocs the
    # buffer the XS layer is still pointing at.
    {   package TS_KeyMover;
        use overload '""' => sub { $main::TS_SK[0] = 'z' x 70_000; $main::TS_SK[0] = 'k'; 'aaa' },
            fallback => 1;
        sub new { bless {}, shift }
    }
    our @TS_SK;
    { my $s = ''; $s .= $_ for ('k'); @TS_SK = ($s) }     # runtime-built, not COW
    my @rows = ({ k => TS_KeyMover->new() }, { k => 'b' }, { k => 'c' });
    is +Text::Stencil->new(row => '[{k}]')->render_sorted(\@rows, \@TS_SK), '[aaa][b][c]',
        'a sort-key name that gets reallocated mid-collection still sorts right';

    {   package TS_KeyMover2;
        use overload '""' => sub { $main::TS_SK1 = 'z' x 70_000; $main::TS_SK1 = 'k'; 'aaa' },
            fallback => 1;
        sub new { bless {}, shift }
    }
    our $TS_SK1;
    { my $s = ''; $s .= $_ for ('k'); $TS_SK1 = $s }
    my @r2 = ({ k => TS_KeyMover2->new() }, { k => 'b' }, { k => 'c' });
    is +Text::Stencil->new(row => '[{k}]')->render_sorted(\@r2, $TS_SK1), '[aaa][b][c]',
        '  and so does the scalar form';
}

{   # Reading the sort key's UTF-8 flag re-dereferenced the array slot after
    # stringifying it.  An overload that pushes to that same array makes
    # av_extend realloc AvARRAY, so the slot pointer is stale.
    {   package TS_KeyPusher;
        use overload '""' => sub { push @main::TS_SK2, ('x') x 64; 'k' }, fallback => 1;
        sub new { bless {}, shift }
    }
    our @TS_SK2 = (TS_KeyPusher->new());
    is +Text::Stencil->new(row => '[{k}]')->render_sorted([{ k => 'b' }, { k => 'a' }], \@TS_SK2),
        '[a][b]', 'a sort-key name that grows its own array does not strand the slot';
}

{   # Stringifying skip_if/skip_unless runs user Perl that can die.  It used to
    # happen after tpl_compile, so a die there abandoned the whole compiled
    # template with nothing left holding a pointer to free it.
    {   package TS_DyingKey;
        use overload '""' => sub { die "boom\n" }, fallback => 1;
        sub new { bless {}, shift }
    }
    for my $opt (qw(skip_if skip_unless)) {
        my $err = exception_from(sub {
            Text::Stencil->new(row => '{a}{b}', $opt => TS_DyingKey->new())
        });
        like $err, qr/boom/, "a dying $opt stringification propagates";
    }
    # and the template it would have stranded is gone: repeat enough that a
    # per-call leak would show
    SKIP: {
        skip 'needs /proc and a non-instrumented build', 1
            if instrumented() || !defined rss_kb();
        my $tpl = ('x' x 400) . '{a}{b}{c}' . ('y' x 400);
        eval { Text::Stencil->new(row => $tpl, skip_if => TS_DyingKey->new()) } for 1 .. 2_000;
        my $before = rss_kb();
        eval { Text::Stencil->new(row => $tpl, skip_if => TS_DyingKey->new()) } for 1 .. 30_000;
        my $grew = rss_kb() - $before;
        cmp_ok $grew, '<', 4096,
            "a dying skip_if frees the template (grew ${grew}KB over 30k)";
    }
}

{   # A column index wider than an IV arrives from SvIV already saturated or
    # wrapped -- "99999999999999999999" comes through as -1 -- so the bound
    # check has to look at the NV to see how big it really was.
    for my $big ('99999999999999999999', '1e30', '-1e30') {
        ok !eval { Text::Stencil->new(row => '[{0}]', skip_if => $big); 1 },
            "skip_if '$big' is rejected instead of aliasing to a column";
        ok !eval { Text::Stencil->new(row => '[{0}]')->render_sorted([['a']], $big); 1 },
            "  and so is the same sort index";
    }
    # the ordinary indices still work
    is +Text::Stencil->new(row => '[{1}]', skip_if => 0)->render([['Z', 'O']]), '',
        'an in-range skip_if column still works';
    is +Text::Stencil->new(row => '[{1}]')->render_sorted([['b','B'],['a','A']], -1), '[A][B]',
        'a negative sort column still works';
}

{   # elapsed/ago print an IV; they were still using %ld, which is only the
    # same type where perl's IV happens to be a C long.
    is +Text::Stencil->new(row => '{0:elapsed}')->render([[90061]]), '1d 1h 1m 1s',
        'elapsed formats an ordinary duration';
    SKIP: {
        # the expected span is IV_MAX seconds, so it only holds where an IV is
        # 64 bits; elsewhere the transform saturates at a smaller IV_MAX
        require Config;
        skip 'needs 64-bit IVs', 1 if $Config::Config{ivsize} < 8;
        is +Text::Stencil->new(row => '{0:elapsed}')->render([['9223372036854775807']]),
            '106751991167300d 15h 30m 7s', 'elapsed formats a full-width IV';
    }
    like +Text::Stencil->new(row => '{0:ago}')->render([[0]]), qr/\d+y ago\z/,
        'ago formats a large span';
}

{   # An unrecognised option used to be dropped in silence, which turns a typo
    # into a table that is quietly missing a feature.
    like exception_from(sub { Text::Stencil->new(row => '{0}', seperator => ',') }),
        qr/unknown option 'seperator'/, 'a misspelled option is an error';
    like exception_from(sub { Text::Stencil->new(row => '{0}', escape_chars => '[') }),
        qr/unknown option/, '  for any unknown key';
    like exception_from(sub { Text::Stencil->new(row => '{0}')->clone(row => '{0}', header => 'X') }),
        qr/clone does not take a 'header' option/, 'clone rejects an option it would ignore';
    is +Text::Stencil->new(row => '{0}', separator => ',')->render([['a'], ['b']]), 'a,b',
        '  and the correctly spelled option still works';
    is +Text::Stencil->new(header => 'H', row => '{0}')->clone(row => '[{0}]', separator => '-')
        ->render([['a'], ['b']]), 'H[a]-[b]', '  as does a legitimate clone';
}

{   # The single-argument shorthand only fired for an SV that already had a
    # string, so new(42) fell through to the options loop and complained about
    # an odd number of arguments -- for a call with one argument.
    is +Text::Stencil->new(42)->render([['x']]), '42',
        'the shorthand takes a number as a template';
    is +Text::Stencil->new('{0}')->render([['x']]), 'x',
        '  and still takes a string';
    like exception_from(sub { Text::Stencil->new({ a => 1 }) }), qr/Text::Stencil: /,
        '  while a reference is still an error';
}

{   # descending and a leading '-' select the same thing rather than cancelling
    my $h = Text::Stencil->new(row => '{n};');
    my @r = map { { n => $_ } } qw(a b c);
    is $h->render_sorted(\@r, '-n'), 'c;b;a;', "a leading '-' descends";
    is $h->render_sorted(\@r, '-n', { descending => 0 }), 'c;b;a;',
        "  and {descending => 0} does not cancel it, as documented";
    is $h->render_sorted(\@r, 'n', { descending => 1 }), 'c;b;a;',
        '  while descending alone still descends';
    is $h->render_sorted(\@r, 'n'), 'a;b;c;', '  and neither means ascending';
}

{   # IV_MIN is one larger in magnitude than IV_MAX, so a scanner that saturates
    # an IV and negates afterwards lands one short of the most negative value.
    # Every digit-taking transform shared that bug; they now share one scanner.
    my $min = '-9223372036854775808';
    my $max = '9223372036854775807';
    SKIP: {
        require Config;
        skip 'needs 64-bit IVs', 7 if $Config::Config{ivsize} < 8;
        is +Text::Stencil->new(row => '{0:int}')->render([[$min]]), $min,
            'int reaches IV_MIN';
        is +Text::Stencil->new(row => '{0:raw|int}')->render([[$min]]), $min,
            '  mid-chain too';
        is +Text::Stencil->new(row => '{0:sprintf:%d}')->render([[$min]]), $min,
            'sprintf reaches IV_MIN';
        is +Text::Stencil->new(row => '{0:raw|int_comma}')->render([[$min]]),
            '-9,223,372,036,854,775,808', 'int_comma reaches IV_MIN';
        is +Text::Stencil->new(row => '{0:raw|int}')->render([['-' . ('9' x 23)]]), $min,
            'an over-long negative saturates at IV_MIN, not one above it';
        is +Text::Stencil->new(row => '{0:raw|int}')->render([['9' x 23]]), $max,
            '  and the positive side still saturates at IV_MAX';
        like +Text::Stencil->new(row => '{0:raw|plural:x}')->render([[$min]]), qr/\A\Q$min\E xs\z/,
            'plural keeps the sign at IV_MIN';
    }
    # the ordinary values the scanner also has to keep getting right
    is +Text::Stencil->new(row => '{0:raw|int}')->render([['-42']]), '-42', 'a small negative';
    is +Text::Stencil->new(row => '{0:raw|plural:item}')->render([['1']]), '1 item', 'plural singular';
    is +Text::Stencil->new(row => '{0:raw|plural:item}')->render([['-1']]), '-1 items', 'plural negative';
    is +Text::Stencil->new(row => '{0:elapsed}')->render([['-5']]), '5s', 'elapsed stays positive';
}

{   # render_sorted's option hashref silently dropped anything it did not know,
    # so a misspelled key sorted the wrong way with nothing to explain it --
    # the same trap new() and clone() already refuse.
    my $h = Text::Stencil->new(row => '{n};');
    my @r = map { { n => $_ } } (3, 1, 2);
    like exception_from(sub { $h->render_sorted(\@r, 'n', { decending => 1 }) }),
        qr/unknown render_sorted option 'decending'/, 'a misspelled sort option is an error';
    like exception_from(sub { $h->render_sorted(\@r, 'n', { numerical => 1 }) }),
        qr/unknown render_sorted option/, '  for any unknown key';
    like exception_from(sub { $h->render_sorted(\@r, 'n', 'x') }),
        qr/options must be a hashref/, 'a non-hashref option argument is an error';
    is $h->render_sorted(\@r, 'n', { descending => 1 }), '3;2;1;', '  and the real keys still work';
    is $h->render_sorted(\@r, 'n', { numeric => 1 }), '1;2;3;', '  including numeric';
    is $h->render_sorted(\@r, 'n'), '1;2;3;', '  and omitting the hashref is fine';
}

{   # escape_char took the first byte of whatever it was given, so a two-char
    # string or a non-ASCII character matched nothing and the entire template
    # rendered literally with no field ever substituted.
    for my $bad ('ab', 123, '', "\x{263a}") {
        ok !eval { Text::Stencil->new(row => '[0]', escape_char => $bad); 1 },
            'escape_char rejects a value that is not one byte';
    }
    is +Text::Stencil->new(row => '[0]', escape_char => '[')->render([['V']]), 'V',
        '  while a single byte still works';
    is +Text::Stencil->new(row => '{0}')->render([['V']]), 'V',
        '  and the default is unchanged';
}

{   # a too-large substr parameter reported that it was not a non-negative
    # integer, which is exactly what it was
    like exception_from(sub { Text::Stencil->new(row => '{0:substr:100000001}') }),
        qr/'substr' offset is too large/, 'an oversized substr offset says so';
    like exception_from(sub { Text::Stencil->new(row => '{0:substr:0:100000001}') }),
        qr/'substr' length is too large/, 'an oversized substr length says so';
    like exception_from(sub { Text::Stencil->new(row => '{0:substr:abc}') }),
        qr/must be a non-negative integer/, '  and a non-numeric one still says that';
}

{   # a transform whose output is a multiple of its input must reserve that
    # multiple; where STRLEN is 32 bits the product can wrap while the input is
    # still under the passthrough limit, which would under-reserve the buffer
    is +Text::Stencil->new(row => '{0:html}')->render([['&' x 1000]]), '&amp;' x 1000,
        'a value that expands 5x is reserved correctly';
    is +Text::Stencil->new(row => '{0:url}')->render([[' ' x 1000]]), '%20' x 1000,
        '  and one that expands 3x';
    is +Text::Stencil->new(row => '{0:hex}')->render([['A' x 1000]]), '41' x 1000,
        '  and one that expands 2x';
    is +Text::Stencil->new(row => '{0:replace:a:XXXX}')->render([['a' x 500]]), 'XXXX' x 500,
        '  and replace, whose multiple comes from its own parameter';
}

{   # Sort keys are borrowed from the fields while nothing in the collection
    # loop can run Perl, and copied the moment something can. Both paths have
    # to produce the same order; the copy path is what stops an overload from
    # freeing a buffer the comparator still points at.
    my $h = Text::Stencil->new(row => '{n};');
    my $a = Text::Stencil->new(row => '{0};');

    # fast path: plain scalars
    is $h->render_sorted([map { { n => $_ } } qw(c a b)], 'n'), 'a;b;c;',
        'plain hashref keys sort';
    is $a->render_sorted([['c'], ['a'], ['b']], 0), 'a;b;c;', 'plain arrayref column sorts';
    is +Text::Stencil->new(row => '{a}{b};')->render_sorted(
        [{ a => 1, b => 'y' }, { a => 1, b => 'x' }, { a => 2, b => 'z' }], ['a', 'b']),
        '1x;1y;2z;', 'plain multi-key sorts';
    is $h->render_sorted([map { { n => $_ } } (30, 4, 200)], 'n', { numeric => 1 }),
        '4;30;200;', 'plain numeric sorts';

    # copy path: an overload that rewrites another row's key mid-collection
    {   package TS_KeyRewriter;
        use overload '""' => sub { $main::TS_RW{n} = 'zzz'; 'aaa' }, fallback => 1;
        sub new { bless {}, shift }
    }
    our %TS_RW = (n => 'mmm');
    is +Text::Stencil->new(row => '[{n}]')->render_sorted(
        [\%TS_RW, { n => TS_KeyRewriter->new() }, { n => 'b' }], 'n'),
        '[aaa][b][zzz]', 'an overloaded key sorts on the value captured at collection';

    # copy path: tied containers and tied elements
    {   package TS_SortTiedH;
        sub TIEHASH { bless { d => $_[1] }, $_[0] }
        sub FETCH { $_[0]{d}{ $_[1] } } sub EXISTS { 1 }
        sub FIRSTKEY { 'n' } sub NEXTKEY { undef }
        sub STORE {} sub DELETE {} sub CLEAR {} sub SCALAR { 1 }
    }
    my (%th1, %th2);
    tie %th1, 'TS_SortTiedH', { n => 'b' };
    tie %th2, 'TS_SortTiedH', { n => 'a' };
    is $h->render_sorted([\%th1, \%th2], 'n'), 'a;b;', 'tied hash rows sort';

    {   package TS_SortTiedE;
        sub TIESCALAR { bless { v => $_[1] }, $_[0] }
        sub FETCH { $_[0]{v} } sub STORE {}
    }
    my (@te1, @te2);
    tie $te1[0], 'TS_SortTiedE', 'b';
    tie $te2[0], 'TS_SortTiedE', 'a';
    is $a->render_sorted([\@te1, \@te2], 0), 'a;b;', 'tied array elements sort';

    {   package TS_SortTiedA; require Tie::Array; our @ISA = ('Tie::StdArray'); }
    tie my @rows, 'TS_SortTiedA';
    @rows = ({ n => 'c' }, { n => 'a' }, { n => 'b' });
    is $h->render_sorted(\@rows, 'n'), 'a;b;c;', 'a tied rows container sorts';

    # the switch happens part-way through: earlier keys were already borrowed
    is +Text::Stencil->new(row => '{a}{b};')->render_sorted(
        [{ a => '2', b => 'x' }, { a => '1', b => TS_KeyRewriter->new() }], ['a', 'b']),
        '1aaa;2x;', 'keys borrowed before the switch are still compared correctly';
}

SKIP: {
    # render() sized its buffer at 300 bytes a row and then kept it: a million
    # short rows producing 7.5MB reserved 294MB and left 278MB parked on the
    # object. Two separate fixes -- a cap on the up-front guess and a shrink of
    # a grossly oversized retained buffer -- and they mask each other, so pin
    # them apart. The cap is only visible in the HIGH-WATER mark, because the
    # oversized block is already freed by the time the call returns.
    skip 'needs /proc and a non-instrumented build', 3
        if instrumented() || !defined vmpeak_kb();
    my $s = Text::Stencil->new(row => "{0}\n");
    my @rows = map { ["r$_"] } 1 .. 300_000;

    my $before = vmpeak_kb();
    my $out = $s->render(\@rows);
    my $peak = vmpeak_kb() - $before;
    cmp_ok $peak, '<', 65_536,
        "render does not reserve the whole guess up front (peak grew ${peak}KB for "
        . int(length($out) / 1024) . "KB of output)";
    undef $out;

    # The shrink is a separate fix and needs its own shape: a render big enough
    # to grow the buffer past the keep-size, then a small one, which must hand
    # the big buffer back. Measure the drop ACROSS the small render -- perl
    # never returns its own SV arenas to the OS, so anything measured around
    # the row construction is swamped by that and tests nothing.
    my $b = Text::Stencil->new(row => "{0}\n");
    my @big = map { ['x' x 200] } 1 .. 50_000;
    $b->render(\@big);
    my $after_big = vmsize_kb();
    $b->render([['small']]);
    my $given_back = $after_big - vmsize_kb();
    cmp_ok $given_back, '>', 4_096,
        "  a small render hands back the big render's buffer (${given_back}KB returned)";
    is $b->render([['x'], ['y']]), "x\ny\n", '  and rendering still works after a shrink';
}

{   # a sort spec has to be read one way or the other; mixing a column index
    # and a field name used to push the odd one through the wrong path and
    # sort by the wrong field, with only a numeric warning to show for it
    my $h = Text::Stencil->new(row => '{n};');
    my @rows = ({ n => 'c' }, { n => 'a' });
    like exception_from(sub { $h->render_sorted(\@rows, [0, 'n']) }),
        qr/mixes column indices and field names/, 'a mixed sort spec is rejected';
    like exception_from(sub { $h->render_sorted(\@rows, ['n', 0]) }),
        qr/mixes column indices and field names/, '  in either order';
    is $h->render_sorted(\@rows, ['n']), 'a;c;', '  while an all-names spec works';
    is +Text::Stencil->new(row => '{0}{1};')->render_sorted([['b','x'],['a','y']], [0, 1]),
        'ay;bx;', '  and an all-columns spec works';
}

{   # escape_char reports how many bytes it got, rather than calling a
    # one-character string "a longer string"
    like exception_from(sub { Text::Stencil->new(row => '[0]', escape_char => "\x{263a}") }),
        qr/single byte, got 3/, 'a multi-byte character says how many bytes';
    like exception_from(sub { Text::Stencil->new(row => '[0]', escape_char => '') }),
        qr/single byte, got 0/, 'an empty escape_char says zero';
    is +Text::Stencil->new(row => "x\xe90\xe9", escape_char => "\xe9")->render([['V']]), 'xV',
        'a single byte above 0x7F is still accepted';
}

{   # The sort-key fast path borrows the field's own buffer while nothing in
    # the collection loop can run Perl. A plain rows array holding a magical
    # element is the case that slipped through first time: materialising the
    # row runs Perl before any field has been looked at, so the decision has to
    # be made there too, not only for a magical container.
    {   package TS_MagicRow;
        sub TIESCALAR { bless { n => $_[1] }, $_[0] }
        sub FETCH { $main::TS_MR{k} = 'z' x 9000; { k => "row$_[0]{n}" } }
        sub STORE {}
    }
    our %TS_MR = (k => 'a' x 500);
    my @rows = (\%TS_MR);
    tie $rows[1], 'TS_MagicRow', 1;
    $rows[2] = { k => 'b' };
    my $out = Text::Stencil->new(row => '[{k}]')->render_sorted(\@rows, 'k');
    # row 0's key is rewritten to z's by the tied FETCH; the sort must still be
    # ordered by the keys as captured, and must not read a freed buffer
    like $out, qr/\A\[[^]]+\]\[[^]]+\]\[[^]]+\]\z/,
        'a magical element in a plain rows array renders three rows';
    like $out, qr/\[row1\]/, '  including the tied row';
    like $out, qr/\[b\]/,    '  and the plain one';
}

{   # Stringifying undef is not free: perl reports it, and a __WARN__ handler is
    # arbitrary Perl running while the sort keys are still borrowed pointers.
    # The other render paths skip undef rather than warn; the sort collector
    # used to be the odd one out, warning on perfectly ordinary data.
    my $s = Text::Stencil->new(row => '{n},');
    my @rows = ({ n => 'b' }, { n => undef }, { n => 'a' });

    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };
        is $s->render_sorted([@rows], 'n'), ',a,b,', 'an undef sort key sorts as empty';
        is $s->render([@rows]), 'b,,a,', '  and render is unchanged';
    }
    is scalar @warnings, 0, 'neither path warns about the undef'
        or diag "got: @warnings";

    # a handler that mutates the rows is the memory-safety face of the same gap
    my $rows = [ { n => 'zzzz' . ('z' x 200) }, { n => undef }, { n => 'aaaa' . ('a' x 200) } ];
    {
        local $SIG{__WARN__} = sub { %{ $rows->[0] } = (); $rows->[0]{pad} = 'Q' x 4096 };
        my $out = $s->render_sorted($rows, 'n');
        ok length $out, 'a __WARN__ handler cannot corrupt the borrowed keys';
    }
}

{   # A sort spec that is not a column, a name, or an arrayref used to be
    # stringified into a field name like "HASH(0x...)", match nothing, and come
    # back unsorted with no complaint. A hashref is the easy mistake, because
    # the third argument really is one.
    my $h = Text::Stencil->new(row => '{n};');
    my @r = map { { n => $_ } } qw(c a b);
    like exception_from(sub { $h->render_sorted(\@r, { by => 'n' }) }),
        qr/must be an arrayref, not a HASH reference/, 'a hashref sort spec is rejected';
    like exception_from(sub { $h->render_sorted(\@r, sub { 1 }) }),
        qr/not a CODE reference/, 'a coderef sort spec is rejected';
    like exception_from(sub { $h->render_sorted(\@r, \'n') }),
        qr/not a SCALAR reference/, 'a scalarref sort spec is rejected';
    like exception_from(sub { $h->render_sorted(\@r, undef) }),
        qr/needs a column index, a field name, or an arrayref/, 'undef is rejected';
    is $h->render_sorted(\@r, 'n'), 'a;b;c;', '  while a field name still works';
    is $h->render_sorted(\@r, ['n']), 'a;b;c;', '  and an arrayref of them';
    is +Text::Stencil->new(row => '{0};')->render_sorted([['c'], ['a']], 0), 'a;c;',
        '  and a column index';
}

{   # The sort-key fast path borrows each field's buffer while nothing in the
    # collection loop can re-enter perl. Deciding that from individual magic
    # flavours was wrong three times; the last was PERL_MAGIC_uvar, which
    # hv_fetch dispatches on SvSMAGICAL && SvGMAGICAL and which is not
    # RMAGICAL, so it walked past the container guard with every earlier key
    # still borrowed.
    require Hash::Util::FieldHash;
    Hash::Util::FieldHash::fieldhashes(\my %fh);
    $fh{k} = 'mid';
    is +Text::Stencil->new(row => '{k};')
        ->render_sorted([{ k => 'zzz' }, \%fh, { k => 'aaa' }], 'k'), 'aaa;mid;zzz;',
        'a uvar-magical (fieldhash) row sorts correctly';

    # it is exactly the shape the old guard let through: magical, but not
    # RMAGICAL. If perl ever changes that, this is the canary.
    require B;
    my $fl = B::svref_2object(\%fh)->FLAGS;
    ok +($fl & 0x00600000) && !($fl & 0x00800000),
        '  and is GMG/SMG without RMG, the case SvRMAGICAL missed';
}

SKIP: {
    # The memory-safety half needs uvar magic whose callback really re-enters
    # perl; Hash::Util::FieldHash's does not. Variable::Magic is not core, so
    # this half is optional -- but it is the one that reproduced the
    # use-after-free.
    skip 'Variable::Magic not installed', 2 unless $TS_HAVE_VMAGIC;

    # Copied-vs-borrowed is observable without touching freed memory: let the
    # wizard edit an earlier row's key in place (tr///, same length, and a
    # runtime-built string so it is not COW). A copy sorts on the value as
    # captured; a borrowed pointer sees the edit and sorts elsewhere.
    our %TS_VM_ROW0;
    { my $s = ''; $s .= 'a' for 1 .. 3; $TS_VM_ROW0{k} = $s; }
    my $wiz = Variable::Magic::wizard(fetch => sub { $TS_VM_ROW0{k} =~ tr/a/z/; () });
    my %trigger;
    { my $s = ''; $s .= 'm' for 1 .. 3; $trigger{k} = $s; }
    # &-form: the prototype exists only when the module loaded, so calling
    # through it would change how this line parses depending on the machine
    &Variable::Magic::cast(\%trigger, $wiz);

    my $out = Text::Stencil->new(row => '[{k}]')
        ->render_sorted([\%TS_VM_ROW0, \%trigger, { k => 'ttt' }], 'k');
    is $out, '[zzz][mmm][ttt]',
        'a uvar row does not leave earlier sort keys borrowed';
    is $TS_VM_ROW0{k}, 'zzz', '  (the wizard did edit the key in place)';
}

{   # Rejecting a bad scalar $sort_by left the arrayref form validating nothing,
    # so [undef] or [{}] was stringified into a field name that matches nothing
    # and the rows came back unsorted with no complaint -- the exact failure the
    # scalar check exists to prevent, one level down.
    my $h = Text::Stencil->new(row => '{n};');
    my @r = map { { n => $_ } } qw(c a b);
    like exception_from(sub { $h->render_sorted(\@r, [undef]) }),
        qr/sort spec element 0 is undef/, 'an undef element is rejected';
    like exception_from(sub { $h->render_sorted(\@r, [{}]) }),
        qr/element 0 is a HASH reference/, 'a hashref element is rejected';
    like exception_from(sub { $h->render_sorted(\@r, [sub { 1 }]) }),
        qr/element 0 is a CODE reference/, 'a coderef element is rejected';
    like exception_from(sub { $h->render_sorted(\@r, ['n', undef]) }),
        qr/element 1 is undef/, '  and it names which element';

    # a string-overloaded object names a field perfectly well, so it must not be
    # swept up by that check
    {   package TS_NameObj;
        use overload '""' => sub { 'n' }, fallback => 1;
        sub new { bless {}, shift }
    }
    is $h->render_sorted(\@r, [TS_NameObj->new()]), 'a;b;c;',
        'an overloaded object is still usable as a field name';
    is $h->render_sorted(\@r, TS_NameObj->new()), 'a;b;c;', '  in the scalar form too';

    is $h->render_sorted(\@r, ['n']), 'a;b;c;', 'a plain name still works';
    is +Text::Stencil->new(row => '{0};')->render_sorted([['c'], ['a']], [0]), 'a;c;',
        '  and a plain column';
    like exception_from(sub { $h->render_sorted(\@r, [ ('n') x 1025 ]) }),
        qr/too many fields/, 'an absurd number of sort fields is rejected';
}

{   # The digit-taker bounded each step against a worst-case 9 instead of the
    # digit in hand, so the top eight magnitudes of the IV range saturated
    # although they fit. Mid-chain and first-position must agree throughout.
    for my $off (0 .. 12) {
        for my $iv (9223372036854775807 - $off, -9223372036854775808 + $off) {
            my $s = "$iv";
            is +Text::Stencil->new(row => '{0:raw|int}')->render_one([$s]),
               +Text::Stencil->new(row => '{0:int}')->render_one([$s]),
               "mid-chain int agrees with first-position int on $s";
        }
    }
    # saturation and digit-scraping must be untouched
    is +Text::Stencil->new(row => '{0:raw|int}')->render_one(['9' x 25]),
        '9223372036854775807', 'a value past IV_MAX still saturates';
    is +Text::Stencil->new(row => '{0:raw|int}')->render_one(['-' . '9' x 25]),
        '-9223372036854775808', '  and past IV_MIN';
    is +Text::Stencil->new(row => '{0:raw|int}')->render_one(['a1b2c3']), '123',
        '  and digit scraping still works';
}

{   # Deferred items, now done. Each was a silent no-op or an inconsistency of
    # the same class the module rejects elsewhere.

    # a parameter on a transform that takes none was dropped on the floor
    for my $spec (qw(uc:1 lc:x html:5 hex:9 int:3 trim:z json:2 length:4 base64:7)) {
        like exception_from(sub { Text::Stencil->new(row => "{0:$spec}") }),
            qr/takes no parameter/, "{0:$spec} is refused rather than ignored";
    }
    # A trailing delimiter is tolerated -- the segment loop ends at the final
    # separator so there is no empty segment to reject -- but an empty segment
    # anywhere else is an error. Undocumented until now; pinned so the two
    # halves cannot drift apart.
    is +Text::Stencil->new(row => '{0:trim|}')->render_one([' x ']), 'x',
        'a trailing | is ignored, like a trailing :';
    is +Text::Stencil->new(row => '{0:}')->render_one([' x ']), ' x ',
        '  and a trailing : still is';
    is +Text::Stencil->new(row => '{0|}')->render_one([' x ']), ' x ',
        '  including on a bare field';
    like exception_from(sub { Text::Stencil->new(row => '{0:|trim}') }),
        qr/empty transform in chain/, '  but a leading empty segment is an error';
    like exception_from(sub { Text::Stencil->new(row => '{0:trim||}') }),
        qr/empty transform in chain/, '  and an interior one';

    # int hands an infinite value to the platform's IV conversion rather than
    # printing "Inf" the way perl's %d does. What that conversion produces
    # varies by perl version -- 5.26/5.30/5.34 disagree with 5.38+ -- so pin
    # only that it is an integer and does not crash, not which one.
    like +Text::Stencil->new(row => '{0:int}')->render_one(['inf']), qr/^-?\d+$/,
        'an infinite value yields some integer rather than "Inf"';
    is +Text::Stencil->new(row => '{0:int}')->render_one(['nan']), '0',
        '  and NaN is the zero junk already becomes';

    # An unknown name leaves the type at its XF_RAW initialiser, which no
    # branch of the parameter chain claims -- so a misspelled transform WITH a
    # parameter fell into the no-parameter error and got told it takes none.
    # Worse, that hard error preempted the deferred one, and a stray literal
    # brace lost the mixed-mode message that explains it properly.
    like exception_from(sub { Text::Stencil->new(row => '{0:trnuc:80}') }),
        qr/unknown transform 'trnuc'/,
        'a misspelled transform with a parameter is still "unknown transform"';
    like exception_from(sub { Text::Stencil->new(row => '{0} .a { color: red; x: y }') }),
        qr/mixes numeric .* named .*literal delimiter/s,
        '  and a stray literal brace still gets the mixed-mode explanation';

    # ...but every transform that does take one still does
    for my $spec ('pad:6', 'trunc:4', 'float:2', 'sprintf:%d', 'replace:a:b',
                  'mask:2', 'substr:1:2', 'default:D', 'bool:Y:N', 'if:X',
                  'unless:X', 'map:a=A', 'wrap:[:]', 'coalesce:1:D', 'date:%Y',
                  'plural:item') {
        ok eval { Text::Stencil->new(row => "{0:$spec}"); 1 }, "  {0:$spec} still compiles";
    }
    # and the bare forms are untouched
    ok eval { Text::Stencil->new(row => '{0:uc}{1:html}{2:count}'); 1 },
        '  bare parameterless transforms still compile';

    # a sort spec of the wrong kind fetched nothing and returned input order
    my $arr = Text::Stencil->new(row => '{0}/');
    my $hash = Text::Stencil->new(row => '{n}/');
    for my $spec ('name', ['name']) {
        like exception_from(sub { $arr->render_sorted([['c'],['a']], $spec) }),
            qr/given a field name but the template uses numeric/,
            'a name spec against a numeric template croaks';
    }
    for my $spec (5, [5]) {
        like exception_from(sub { $hash->render_sorted([{n=>'c'},{n=>'a'}], $spec) }),
            qr/given a column index but the template uses named/,
            'a numeric spec against a named template croaks';
    }
    is $arr->render_sorted([['c'],['a']], 0), 'a/c/', '  matching specs still sort';
    is $hash->render_sorted([{n=>'c'},{n=>'a'}], 'n'), 'a/c/', '  both ways';
    is $hash->render_sorted([{n=>'c'},{n=>'a'}], '-n'), 'c/a/', '  including -name';
    # a template with no field refs at all is ambiguous, so neither is refused
    my $none = Text::Stencil->new(row => 'lit/');
    ok eval { $none->render_sorted([{n=>1}], 'n'); $none->render_sorted([[1]], 0); 1 },
        '  a template with no field references accepts either kind';

    # The sort spec got a kind check; the skip conditions are the same mistake
    # and did not. A numeric skip against a named template (or the reverse)
    # fetches nothing from any row, so skip_if never fires and skip_unless
    # drops every row and hands back an empty string.
    like exception_from(sub { Text::Stencil->new(row => '[{name}]', skip_unless => 0) }),
        qr/skip_unless was given a column index but the template uses named/,
        'a numeric skip_unless against a named template croaks';
    like exception_from(sub { Text::Stencil->new(row => '[{0}]', skip_unless => 'flag') }),
        qr/skip_unless was given a field name but the template uses numeric/,
        '  and a named one against a numeric template';
    like exception_from(sub { Text::Stencil->new(row => '[{name}]', skip_if => 0) }),
        qr/skip_if was given a column index/, '  skip_if too';
    # clone can change the row mode, so it has to re-check what it inherits
    like exception_from(sub { Text::Stencil->new(row => '[{0}]', skip_if => 1)
                                  ->clone(row => '[{name}]') }),
        qr/skip_if was given a column index/,
        '  and clone re-checks an inherited skip against the new row mode';
    # matching kinds, and a template with no field refs, are untouched
    is +Text::Stencil->new(row => '[{0}]', skip_if => 1)->render([['a',0],['b',1]]), '[a]',
        '  a matching numeric skip still works';
    is +Text::Stencil->new(row => '[{n}]', skip_if => 's')->render([{n=>'a',s=>0},{n=>'b',s=>1}]),
        '[a]', '  and a matching named one';
    ok eval { Text::Stencil->new(row => 'lit', skip_if => 0); 1 },
        '  a template with no field references accepts either kind';
    ok eval { Text::Stencil->new(row => '[{0}]', skip_if => 1)->clone(row => '[{1}]'); 1 },
        '  and a same-mode clone still works';

    # "nan" parses to NaN, which is neither < nor > anything, so it compared
    # equal to every key and the comparator stopped being a weak ordering --
    # garbage order, and an out-of-bounds read in glibc's qsort before 2.39.
    my $ns = Text::Stencil->new(row => '{0},');
    is $ns->render_sorted([map { [$_] } qw(9 NaN 2 7 NaN 4)], 0, { numeric => 1 }),
        'NaN,NaN,2,4,7,9,', 'NaN sorts as the zero every other junk value becomes';
    is $ns->render_sorted([map { [$_] } qw(nan 5 3 nan 1)], 0, { numeric => 1 }),
        'nan,nan,1,3,5,', '  lowercase too';
    is $ns->render_sorted([map { [$_] } qw(9 2 7 4)], 0, { numeric => 1 }),
        '2,4,7,9,', '  and an ordinary numeric sort is unchanged';

    # INT_MIN was rejected by the parser but accepted by skip_if and the sort
    # spec, so the same index was valid in one place and not another
    for my $v (-2147483648, -2147483647, 2147483647) {
        ok eval { Text::Stencil->new(row => "{$v}"); 1 }, "template accepts $v";
        ok eval { Text::Stencil->new(row => '{0}', skip_if => $v); 1 }, "  skip_if accepts $v";
    }
    for my $v (2147483648, -2147483649) {
        ok !eval { Text::Stencil->new(row => "{$v}"); 1 }, "template rejects $v";
        ok !eval { Text::Stencil->new(row => '{0}', skip_if => $v); 1 }, "  skip_if rejects $v";
    }
    is +Text::Stencil->new(row => '{-1}')->render_one([1,2,3]), '3',
        '  ordinary negative indexing still works';

    # one argument that is not a plain string is neither shorthand nor options
    like exception_from(sub { Text::Stencil->new(undef) }),
        qr/template string or an option list/,
        'new(undef) names the actual mistake';
    like exception_from(sub { Text::Stencil->new([]) }),
        qr/template string or an option list/, '  and new([])';
    is +Text::Stencil->new('{0}')->render_one([7]), '7', '  shorthand still works';
    is +Text::Stencil->new(row => '{0}')->render_one([7]), '7', '  option list still works';
}

{   # mg_findext does not check the SV type, and only PVMG-or-richer has a magic
    # chain, so on a smaller body it walked whatever the union held. sv_bless
    # upgrades every blessed referent, which is why method calls are safe and
    # twelve rounds missed this -- but the function-call form hands us an
    # unblessed low-type referent and segfaulted once the heap was warm enough
    # for the garbage to be non-NULL. A render first is what arms it.
    my $warm = Text::Stencil->new(row => '{0}');
    $warm->render([[1]]);
    for my $bad (\undef, \'str', \42, \3.14, [], {}, sub {}, undef, 'str', 42) {
        my $what = defined $bad ? (ref($bad) ? 'ref ' . (ref($bad) || 'SCALAR') : 'plain') : 'undef';
        like exception_from(sub { Text::Stencil::render($bad, [[1]]) }),
            qr/not a Text::Stencil object/,
            "a non-object invocant ($what) croaks instead of crashing";
    }
    # DESTROY takes the same path and must survive it too
    my $ok = eval { Text::Stencil::DESTROY(\'str'); 1 };
    ok $ok, 'DESTROY on a non-object invocant does not crash';
}

{   # The strtod scratch was 64 bytes, which truncated a longer numeric to its
    # first 63 digits -- not a precision nit but a wrong magnitude, and numeric
    # sort then ordered a 70-digit value below a 64-digit one.
    my $long = '1' x 70;
    is +Text::Stencil->new(row => '{0:raw|float:0}')->render_one([$long]),
       +Text::Stencil->new(row => '{0:float:0}')->render_one([$long]),
        'a long numeric reads the same mid-chain as first-position';
    my $s = Text::Stencil->new(row => '{0};');
    is $s->render_sorted([['1' x 70], ['9' x 64]], 0, { numeric => 1 }),
        ('9' x 64) . ';' . ('1' x 70) . ';',
        '  and numeric sort orders by magnitude, not by truncated prefix';
    # past DBL_MAX the answer is inf either way, which is correct
    like +Text::Stencil->new(row => '{0:raw|float:0}')->render_one(['9' x 400]),
        qr/^-?inf/i, '  a value past DBL_MAX is still infinite';
}

{   # wrap is the only transform that ADDS to slen in the accumulator, and that
    # accumulator was an int while the guard above only caps slen at INT_MAX --
    # so a prefix on a value near the cap overflowed to negative and the length
    # became ~SIZE_MAX. Reproduced at 1/65536 scale (short accumulator, 32767
    # guard): ASAN reported an allocation of 0xffffffffffff000e. No portable
    # test can reach it at full scale, so this pins the ordinary shapes.
    is +Text::Stencil->new(row => '{0:wrap:[:]}')->render_one(['mid']), '[mid]',
        'wrap with both affixes';
    is +Text::Stencil->new(row => '{0:wrap:PRE}')->render_one(['x']), 'PREx',
        '  prefix only';
    is +Text::Stencil->new(row => '{0:wrap:[:]}')->render_one(['']), '',
        '  and an empty value emits nothing, not the wrapper';
    my $big = 'x' x 100_000;
    is length +Text::Stencil->new(row => '{0:wrap:AB:CD}')->render_one([$big]),
        100_004, '  length is exact on a large value';

    # count on an undef field is empty, so a later default must survive it. The
    # use_default walk skipped render_field's count handler and apply_xform then
    # wrote 0 over the default: {items:count|default:none} printed 0.
    is +Text::Stencil->new(row => '{a:count|default:D}')->render_one({ a => undef }), 'D',
        'count on an undef field lets a later default through';
    is +Text::Stencil->new(row => '{a:count|default:D}')->render_one({}), 'D',
        '  and on an absent one';
    is +Text::Stencil->new(row => '{a:count|wrap:[:]}')->render_one({ a => undef }), '',
        '  wrap sees nothing rather than a 0';
    # the container cases must be untouched
    is +Text::Stencil->new(row => '{a:count|default:D}')->render_one({ a => [1,2,3] }), '3',
        '  a real container still counts';
    is +Text::Stencil->new(row => '{a:count|default:D}')->render_one({ a => [] }), '0',
        '  and an empty one still counts 0, not the default';
    is +Text::Stencil->new(row => '{#:count}')->render([[1],[2]]), '00',
        '  {#:count} still reports 0, the answer for a scalar';

    # Dropping the count stage also changed what map sees on an undef field:
    # it used to match 0= (count had written a 0), now it matches * like map
    # alone does. That consistency is the point -- but an array that really is
    # empty must still count 0 and match 0=.
    is +Text::Stencil->new(row => '{a:count|map:0=zero:*=some}')->render_one({ a => undef }),
       +Text::Stencil->new(row => '{a:map:0=zero:*=some}')->render_one({ a => undef }),
        'count|map on undef agrees with map alone';
    is +Text::Stencil->new(row => '{a:count|map:0=zero:*=some}')->render_one({ a => [] }), 'zero',
        '  but a genuinely empty container still counts 0';
    is +Text::Stencil->new(row => '{a:count|map:0=zero:*=some}')->render_one({ a => [1,2] }), 'some',
        '  and a non-empty one still counts';
}

{   # render_sorted croaks on a swallowed extra argument; render_cb did not, so
    # a stray third argument was silently ignored.
    my $s = Text::Stencil->new(row => '{0}');
    my $out = '';
    open my $fh, '>', \$out or die;
    like exception_from(sub { $s->render_cb(sub { undef }, $fh, 'EXTRA') }),
        qr/render_cb takes at most two arguments/,
        'render_cb rejects a swallowed extra argument';
    # the two supported arities still work
    my $n = 0;
    is $s->render_cb(sub { $n < 2 ? [$n++] : undef }), '01', '  two-arg form still works';
    $n = 0;
    my $o2 = '';
    open my $fh2, '>', \$o2 or die;
    $s->render_cb(sub { $n < 2 ? [$n++] : undef }, $fh2);
    close $fh2;
    is $o2, '01', '  three-arg form still works';
}

{   # A hole in the rows array reads as undef and cannot be told from an
    # assigned undef, but render/render_to_fh skipped it while still counting
    # it, and render_sorted rendered it -- so the paths disagreed on identical
    # input and row_count disagreed with the output it described.
    my $s = Text::Stencil->new(row => '[{0}]', separator => ',');
    my @hole; $hole[0] = [1]; $hole[2] = [2];
    my @expl = ([1], undef, [2]);

    for my $c ([hole => \@hole], ['explicit undef' => \@expl]) {
        my ($what, $rows) = @$c;
        is $s->render($rows), '[1],[],[2]', "render emits an empty row for a $what";
        is $s->row_count, 3, "  and counts it ($what)";
        my $out = '';
        open my $fh, '>', \$out or die;
        $s->render_to_fh($fh, $rows);
        close $fh;
        is $out, '[1],[],[2]', "  render_to_fh agrees ($what)";
        is $s->render_sorted([@$rows], 0), '[],[1],[2]',
            "  render_sorted agrees ($what)";
    }

    # sv_2mortal returns early for an immortal without registering it, so
    # pinning an undef row left the refcount increment unmatched -- one leaked
    # reference per undef row. Invisible until it wraps, hence a test.
    SKIP: {
        skip 'Devel::Peek not available', 1 unless eval { require Devel::Peek; 1 };
        my $refcnt = sub {
            open my $tmp, '+>', undef       or return;
            open my $saved, '>&', \*STDERR  or return;
            open STDERR, '>&', $tmp         or return;
            Devel::Peek::Dump(\undef);
            open STDERR, '>&', $saved;
            seek $tmp, 0, 0;
            my $d = do { local $/; <$tmp> };
            return $d =~ /REFCNT = (\d+)\s*\n\s*FLAGS = \(READONLY,PROTECT\)/ ? $1 : undef;
        };
        my $before = $refcnt->();
        skip 'could not read PL_sv_undef refcount', 1 unless defined $before;

        my @sparse; $sparse[$_ * 2] = [$_] for 0 .. 499;
        $s->render(\@sparse);
        my $sink = '';
        open my $nfh, '>', \$sink or die;
        $s->render_to_fh($nfh, \@sparse);
        close $nfh;
        $s->render_sorted([@sparse], 0);
        $s->render_one(undef) for 1 .. 100;

        is $refcnt->() - $before, 0,
            'an undef row does not leak a reference to PL_sv_undef';
    }

    # ...but an array that SHRINKS mid-render must stop, not emit a row per
    # index that no longer exists. (The tied-FETCH case is covered above; this
    # pins the boundary the hole handling has to leave alone.)
    our @TS_SHRINK;
    {   package TS_ShrinkRow;
        sub TIEHASH  { bless {}, shift }
        sub FETCH    { splice @main::TS_SHRINK, 1; 'x' }
        sub STORE {} sub DELETE {} sub CLEAR {} sub EXISTS { 1 }
        sub FIRSTKEY { } sub NEXTKEY { }
    }
    tie my %shrink, 'TS_ShrinkRow';
    @TS_SHRINK = (\%shrink, { k => 'second' }, { k => 'third' });
    my $sh = Text::Stencil->new(row => '[{k}]');
    is $sh->render(\@TS_SHRINK), '[x]',
        'a rows array truncated mid-render stops instead of emitting empty rows';
}

{   # The POD once claimed a character-string input plus well-formed output was
    # enough for a character result. Both hold here and the result is bytes: a
    # high byte from anything that arrived as bytes rules it out regardless.
    # Pinned so the prose cannot drift back.
    my $tpl = '[{0}]';
    utf8::upgrade($tpl);
    ok utf8::is_utf8($tpl), 'the template is a character string';
    my $out = Text::Stencil->new(row => $tpl)->render([["\xc3\xa9"]]);
    ok !utf8::is_utf8($out),
        'a byte field with high bytes forces a byte result, well-formed or not';
    is $out, "[\xc3\xa9]", '  and the bytes come back untouched';
    ok utf8::valid(do { my $c = $out; utf8::decode($c); $c }),
        '  (the output really was well-formed UTF-8, so the rule is not vacuous)';

    # the flagged-wins case, for contrast: nothing arrived as high bytes
    my $wide = Text::Stencil->new(row => $tpl)->render([["\x{263a}"]]);
    ok utf8::is_utf8($wide), 'a wide field still yields a character string';
}

{   # A delimiter above 0x7F cut a decoded template inside a multi-byte
    # character and every piece stayed flagged, so render() and columns()
    # returned SvUTF8 strings whose bytes were not UTF-8 and uc() died.
    # Upgraded below so U+00E9 is stored as c3 a9, as from_file produces; the
    # delimiter is the continuation byte, which is what lands mid-character.
    my $tpl = "caf\x{e9}0\x{e9} tail";
    utf8::upgrade($tpl);
    ok utf8::is_utf8($tpl), 'the probe template really is a character string';
    like exception_from(sub { Text::Stencil->new(row => $tpl, escape_char => "\xa9") }),
        qr/escape_char must be an ASCII byte/,
        'a high-bit escape_char is refused for a decoded row template';

    # the two shapes that must keep working
    my $bytes = Text::Stencil->new(row => "x\xe90\xe9", escape_char => "\xe9");
    is $bytes->render([['V']]), 'xV', '  a byte template still takes a high-bit delimiter';
    my $ascii = Text::Stencil->new(row => "caf\x{e9} [0] \x{2014}", escape_char => '[');
    is $ascii->render([['V']]), "caf\x{e9} V \x{2014}",
        '  and a decoded template still takes an ASCII one';
    ok utf8::valid($ascii->render([['V']])), '  whose output is well-formed';

    # NUL fell through `esc_char ? esc_char : '{'` and silently meant '{'
    like exception_from(sub { Text::Stencil->new(row => '{0}', escape_char => "\0") }),
        qr/escape_char must not be NUL/, 'a NUL escape_char is refused, not ignored';
}

{   # from_file checked only the open, so a path that opens but cannot be read
    # warned from inside the module and handed back an empty renderer. Which
    # message comes back depends on whether open() on a directory succeeds --
    # it does on Unix, not on Win32 -- so accept either.
    like exception_from(sub { Text::Stencil->from_file(File::Spec->tmpdir) }),
        qr/can't (?:read|open) /, 'from_file reports a directory rather than warning';

    # a genuinely empty file reads as a defined "" and must still be accepted
    my ($fh, $path) = File::Temp::tempfile(UNLINK => 1);
    close $fh;
    my $empty = eval { Text::Stencil->from_file($path) };
    ok defined $empty, '  and an empty file is still a valid template';
    is $empty->render([['x']]), '', '  that renders nothing';
}

{   # The literal default is what follows the final ':'. Finding it by walking
    # forwards and keeping the last segment seen never visited the empty tail of
    # `coalesce:FIELD:`, so it settled on FIELD and emitted that field's NAME --
    # a slice of the template text -- as the default. The natural spelling of
    # "fall back to FIELD, else nothing" printed the word instead of nothing.
    is +Text::Stencil->new(row => '{name:coalesce:nick:}')
        ->render_one({ name => '', nick => '' }), '',
        'a trailing : is an empty default, not the fallback field name';
    is +Text::Stencil->new(row => '{0:coalesce:1:}')->render_one(['', '']), '',
        '  in array mode too';
    is +Text::Stencil->new(row => '{0:coalesce:1:2:}')->render_one(['', '', '']), '',
        '  and with several fallbacks';
    # the fallback and the non-empty default must still work
    is +Text::Stencil->new(row => '{name:coalesce:nick:}')
        ->render_one({ name => '', nick => 'N' }), 'N',
        '  a non-empty fallback still wins';
    is +Text::Stencil->new(row => '{name:coalesce:nick:D}')
        ->render_one({ name => '', nick => '' }), 'D',
        '  and a spelled-out default is untouched';
}

{   # is_field_truthy already ran get-magic (both container branches do), then
    # plain SvPV ran it a second time. A tied element's second FETCH can return
    # something else, so the skip decision was taken on a value no other part of
    # the render ever sees. fetch_field uses SvPV_nomg after the same
    # SvGETMAGIC; this was the one site still spelled the magic-honouring way.
    package TS_CountFetch;
    sub TIESCALAR { my ($c, $vals) = @_; bless { v => $vals, n => 0 }, $c }
    sub FETCH     { my $s = shift; $s->{n}++; $s->{v}[ $s->{n} - 1 ] // $s->{v}[-1] }
    sub STORE     { }
    sub count     { $_[0]{n} }

    package main;
    # first FETCH says "skip", a second would say "keep"
    my @row = (undef, 'payload');
    my $obj = tie $row[0], 'TS_CountFetch', [1, 0];
    is +Text::Stencil->new(row => '{1}', skip_if => 0)->render([\@row]), '',
        'skip_if acts on the first FETCH, not a second one';
    is $obj->count, 1, '  and fetches a tied element exactly once';

    my %h;
    my $hobj = tie $h{flag}, 'TS_CountFetch', [1, 0];
    is +Text::Stencil->new(row => '{x}', skip_if => 'flag')->render([\%h]), '',
        '  same for a tied hash value';
    is $hobj->count, 1, '  fetched once there too';
}

{   # Two documented details nothing asserted, both found by re-reading the POD
    # against the build: coalesce selects on non-empty rather than on truth
    # (the POD had said "truthy" in one place and "non-empty" in another), and
    # columns() lists field references only, not the row number.
    is +Text::Stencil->new(row => '{0:coalesce:1:D}')->render_one(['0', 'fb']), '0',
        'coalesce keeps a "0" primary -- non-empty, not truthy';
    is +Text::Stencil->new(row => '{0:coalesce:1:D}')->render_one(['', 'fb']), 'fb',
        '  and still falls through an empty one';
    is_deeply +Text::Stencil->new(row => '{#} {0} {2}')->columns, [0, 2],
        'columns skips the row number';

    # render_sorted was the one render path whose row_count nothing checked
    my $rs = Text::Stencil->new(row => '{0};', skip_if => 1);
    is $rs->render_sorted([['c', 0], ['a', 1], ['b', 0]], 0), 'b;c;',
        'render_sorted skips as the other paths do';
    is $rs->row_count, 3, '  and counts the rows in, skipped ones included';
}

{   # Existing tests used values holding SEVERAL special bytes at once, so
    # clearing any single table entry left the others to keep the output
    # looking right -- dropping backslash from json_special shipped invalid
    # JSON with the suite green. Check every byte on its own instead.
    my %ref = (
        html => sub {
            my $c = shift;
            return '&amp;'  if $c eq '&';
            return '&lt;'   if $c eq '<';
            return '&gt;'   if $c eq '>';
            return '&quot;' if $c eq '"';
            return '&#39;'  if $c eq "'";
            return $c;
        },
        html_br => sub {
            my $c = shift;
            return '<br>' if $c eq "\n";
            return '&amp;'  if $c eq '&';
            return '&lt;'   if $c eq '<';
            return '&gt;'   if $c eq '>';
            return '&quot;' if $c eq '"';
            return '&#39;'  if $c eq "'";
            return $c;
        },
        json => sub {
            my $c = shift;
            return '\\"'  if $c eq '"';
            return '\\\\' if $c eq "\\";
            return '\\b'  if $c eq "\x08";
            return '\\f'  if $c eq "\x0c";
            return '\\n'  if $c eq "\x0a";
            return '\\r'  if $c eq "\x0d";
            return '\\t'  if $c eq "\x09";
            return sprintf '\\u%04x', ord $c if ord($c) < 0x20;
            return $c;
        },
    );

    for my $t (sort keys %ref) {
        my $s = Text::Stencil->new(row => "{0:$t}");
        my @bad;
        for my $b (0 .. 255) {
            my $c   = chr $b;
            my $got = $s->render([[$c]]);
            my $want = $ref{$t}->($c);
            push @bad, sprintf('0x%02x got %s want %s', $b, _vis($got), _vis($want))
                if $got ne $want;
        }
        is scalar @bad, 0, "$t escapes every byte 0x00-0xff on its own"
            or diag join "\n", @bad[0 .. ($#bad > 7 ? 7 : $#bad)];
    }

    sub _vis { my $s = shift; $s =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ge; "[$s]" }
}

done_testing;
