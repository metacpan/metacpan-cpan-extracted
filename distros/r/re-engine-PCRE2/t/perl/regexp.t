#!./perl

use Test::More;

# The tests are in a separate file 't/perl/re_tests'.
# Each line in that file is a separate test.
# There are five columns, separated by tabs.
#
# Column 1 contains the pattern, optionally enclosed in C<''> C<::> or
# C<//>.  Modifiers can be put after the closing delimiter.  C<''> will
# automatically be added to any other patterns.
#
# Column 2 contains the string to be matched.
#
# Column 3 contains the expected result:
# 	y	expect a match
# 	n	expect no match
# 	c	expect an error
#	B	test exposes a known bug in Perl, should be skipped
#	b	test exposes a known bug in Perl, should be skipped if noamp
#	T	the test is a TODO (can be combined with y/n/c/p)
#	M	skip test on miniperl (combine with y/n/c/T)
#	t	test exposes a bug with threading, TODO if qr_embed_thr
#       s       test should only be run for regex_sets_compat.t
#       S       test should not be run for regex_sets_compat.t
#       a       test should only be run on ASCII platforms
#       e       test should only be run on EBCDIC platforms
#       p       exposes a PCRE bug/limitation. TODO
#
# Columns 4 and 5 are used only if column 3 contains C<y> or C<c>.
#
# Column 4 contains a string, usually C<$&>.
#
# Column 5 contains the expected result of double-quote
# interpolating that string after the match, or start of error message.
#
# Column 6, if present, contains a reason why the test is skipped.
# This is printed with "skipped", for harness to pick up.
#
# Column 7 can be used for comments
#
# \n in the tests are interpolated, as are variables of the form ${\w+}.
#
# Blanks lines are treated as PASSING tests to keep the line numbers
# linked to the test number.
#
# If you want to add a regular expression test that can't be expressed
# in this format, don't add it here: put it in op/pat.t instead.
#
# Note that columns 2,3 and 5 are all enclosed in double quotes and then
# evalled; so something like a\"\x{100}$1 has length 3+length($1).
#
# \x... and \o{...} constants are automatically converted to the native
# character set if necessary.  \[0-7] constants aren't

# test individual tests, e.g. line 1840:
#   perl -Mblib t/perl/regexp.t 1 t/perl/re_tests 1840 1843 ...
# benchmarking:
#   time perl -Mblib t/perl/regexp.t 10000 --core >/dev/null
# vs
#   time perl -Mblib t/perl/regexp.t 10000 >/dev/null

my $iters = shift || 1;	# Poor man performance suite, 10000 is OK.
my $file = shift;       # or --core
my $num = shift;
if (defined $file) {
    if ($file ne '--core') {
        open TESTS, $file or die "Can't open $file";
    }
}

sub _comment {
    return map { /^#/ ? "$_\n" : "# $_\n" }
           map { split /\n/ } @_;
}

sub convert_from_ascii {
    my $string = shift;

    #my $save = $string;
    # Convert \x{...}, \o{...}
    $string =~ s/ (?<! \\ ) \\x\{ ( .*? ) } / "\\x{" . sprintf("%X", utf8::unicode_to_native(hex $1)) .  "}" /gex;
    $string =~ s/ (?<! \\ ) \\o\{ ( .*? ) } / "\\o{" . sprintf("%o", utf8::unicode_to_native(oct $1)) .  "}" /gex;

    # Convert \xAB
    $string =~ s/ (?<! \\ ) \\x ( [A-Fa-f0-9]{2} ) / "\\x" . sprintf("%02X", utf8::unicode_to_native(hex $1)) /gex;

    # Convert \xA
    $string =~ s/ (?<! \\ ) \\x ( [A-Fa-f0-9] ) (?! [A-Fa-f0-9] ) / "\\x" . sprintf("%X", utf8::unicode_to_native(hex $1)) /gex;

    #print STDERR __LINE__, ": $save\n$string\n" if $save ne $string;
    return $string;
}

use strict;
use warnings FATAL=>"all";
# to be overridden by other core tests:
use vars qw($bang $ffff $nulnul $OP);
use vars qw($skip_amp $qr $qr_embed); # set by our callers
if (!defined $file or $file ne '--core') {
    require re::engine::PCRE2; # for benchmarks and regression tests
}
use re 'eval';
use Data::Dumper;

if (!defined $file or $file eq '--core') {
    open(TESTS,'t/perl/re_tests') || open(TESTS,'re_tests') || open(TESTS,'t/re_tests')
      || die "Can't open t/perl/re_tests: $!";
}

my @tests = <TESTS>;
close TESTS;

if ($num) {
    my @t;
    push @t, $tests[$num-1];
    while ($num = shift @ARGV) {
        push @t, $tests[$num-1];
    }
    @tests = @t;
}

$bang = sprintf "\\%03o", ord "!"; # \41 would not be portable.
$ffff  = chr(0xff) x 2;
$nulnul = "\0" x 2;
my $OP = $qr ? 'qr' : 'm';

$| = 1;
printf "1..%d\n# $iters iterations\n", scalar @tests;
my $test;
my $skip_rest;

# Tests known to fail under PCRE2
my (@pcre_fail, %pcre_fail, @pcre_skip, %pcre_skip);
# see p in re_tests instead
my @pcre_fail_ignored = (

    # new patterns and pcre2 fails: need to fallback
    143..146, # \B{gcb} \B{lb} \B{sb} \B{wb}
    352,      # '^'i:ABC:y:$&:
    402,      # '(a+|b){0,1}?'i
    409,      # 'a*'i $&
    578,      # '(b.)c(?!\N)'s:a
    654,655,664, # unicode
    667,      # '[[:^cntrl:]]+'u:a\x80:y:$&:a

    # old PCRE fails:
    # Pathological patterns that run into run-time PCRE_ERROR_MATCHLIMIT,
    # even with huge set_match_limit 512mill
    880 .. 897, # .X(.+)+[X][X]:bbbbXXXaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

    # offset: +59+8
    # err: (?!)+ => nothing to repeat
    #970,
    # XXX: Some named capture error
    #1050 .. 1051,
    # (*F) / (*FAIL)
    #1191, 1192,
    # (*A) / (*ACCEPT)
    #1194 .. 1195,
    # (?'${number}$optional_stuff' key names)
    #1217 .. 1223,
    # XXX: Some named capture error
    #1253,
    # These cause utf8 warnings, see above
    #1307, 1309, 1310, 1311, 1312, 1318, 1320 .. 1323,

    # test errors:    
    # => range out of order in character class TODO
    900, # ([a-\d]+):-:c:-:False [] range => `-', match=1
    902, # ([\d-z]+):-:cc:$1:False [] range => `-', match=1
    904, # ([\d-\s]+):-:cc:$1:False [] range => `-', match=1
    906, # ([a-[:digit:]]+):-:cc:-:False [] range => `-', match=1
    908, # ([[:digit:]-z]+):-:cc:c:False [] range => `c', match=1
    910, # ([[:digit:]-[:alpha:]]+):-:c:-:False [] range => `-', match=1

    # aba =~ ^(a(b)?)+$ and aabbaa =~ ^(aa(bb)?)+$
    941, # ^(a(b)?)+$:aba:y:-$1-$2-:-a-- => `-a-b-', match=1
    942, # ^(aa(bb)?)+$:aabbaa:y:-$1-$2-:-aa-- => `-aa-bb-', match=1
    947, # ^(a\1?){4}$:aaaaaa:y:$1:aa => `', match=

    # empty codeblock
    1005, #TODO (??{}):x:y:-:- => error `Eval-group not allowed at runtime, use re 'eval' in regex m/(??{})/ at (eval 5663) line 1.'

    # XXX: <<<>>> pattern
    1096, # ^(<(?:[^<>]+|(?3)|(?1))*>)()(!>!>!>)$:<<!>!>!>><>>!>!>!>:y:$1:<<!>!>!>><>> => `', match=
    1126, # /^(?'main'<(?:[^<>]+|(?&crap)|(?&main))*>)(?'empty')(?'crap'!>!>!>)$/:<<!>!>!>><>>!>!>!>:yM:$+{main}:<<!>!>!>><>> => `', match=

    # XXX: \R doesn't match an utf8::upgraded \x{85}, we need to
    # always convert the subject and pattern to utf-8 for these cases
    # to work
    1378, # (utf8::upgrade($subject)) foo(\R+)bar:foo\r
    1380, # (utf8::upgrade($subject)) (\R+)(\V):foo\r
    1381, # (utf8::upgrade($subject)) foo(\R)bar:foo\x{85}bar:y:$1:\x{85} => `', match=
    1382, # (utf8::upgrade($subject)) (\V)(\R):foo\x{85}bar:y:$1-$2:o-\x{85} => `�-�', match=1
    1394, # (utf8::upgrade($subject)) foo(\v+)bar:foo\r
    1396..1398, # (utf8::upgrade($subject)) (\v+)(\V):foo\r
    1405,1407..1409, # (utf8::upgrade($subject)) foo(\h+)bar:foo\t\x{A0}bar:y:$1:\t\x{A0} => `', match=

    # regressions in 5.8.x (only) introduced by change 30638
    1433, # /^\s*i.*?o\s*$/s:io
    
    1446, #/\N{}\xe4/i:\xc4:y:$&:\xc4 => error `Unknown charname '' is deprecated. Its use will be fatal in Perl 5.28 at (eval 7892) line 2.'
    1484, # /abc\N {U+41}/x:-:c:-:Missing braces => `-', match=
    1485, # /abc\N {SPACE}/x:-:c:-:Missing braces => `-', match=
    1490, # /\N{U+BEEF.BEAD}/:-:c:-: => `-', match=
    
    1495, # \c`:-:ac:-:\"\\c`\" is more clearly written simply as \"\\ \" => `-', match=
    1496, # \c1:-:ac:-:\"\\c1\" is more clearly written simply as \"q\" => `-', match=
    
    1514, # \c?:\x9F:ey:$&:\x9F => `\', match=
    
    1575, # [\8\9]:\000:Sn:-:- => `-', match=
    1576, # [\8\9]:-:sc:$&:Unrecognized escape \\8 in character class => `[', match=
    
    1582, # [\0]:-:sc:-:Need exactly 3 octal digits => `-', match=
    1584, # [\07]:-:sc:-:Need exactly 3 octal digits => `-', match=
    1585, # [\07]:7\000:Sn:-:- => `-', match=
    1586, # [\07]:-:sc:-:Need exactly 3 octal digits => `-', match=
    
    1599, # /\xe0\pL/i:\xc0a:y:$&:\xc0a => `/', match=
    
    1618, # ^_?[^\W_0-9]\w\z:\xAA\x{100}:y:$&:\xAA\x{100} => `^', match=
    1621, # /s/ai:\x{17F}:y:$&:\x{17F} => `/', match=
    
    1630, # /[^\x{1E9E}]/i:\x{DF}:Sn:-:- => `-', match=
    1639, # /^\p{L}/:\x{3400}:y:$&:\x{3400} => `�', match=1
    1642, # /[s\xDF]a/ui:ssa:Sy:$&:ssa => `sa', match=1
    
    1648, # /ff/i:\x{FB00}\x{FB01}:y:$&:\x{FB00} => `/', match=
    1649, # /ff/i:\x{FB01}\x{FB00}:y:$&:\x{FB00} => `/', match=
    1650, # /fi/i:\x{FB01}\x{FB00}:y:$&:\x{FB01} => `/', match=
    1651, # /fi/i:\x{FB00}\x{FB01}:y:$&:\x{FB01} => `/', match=

    # These test that doesn't cut-off matching too soon in the string for
    # multi-char folds
    1669, # /ffiffl/i:abcdef\x{FB03}\x{FB04}:y:$&:\x{FB03}\x{FB04} => `/', match=
    1670, # /\xdf\xdf/ui:abcdefssss:y:$&:ssss => `/', match=
    1672, # /st/i:\x{DF}\x{FB05}:y:$&:\x{FB05} => `/', match=
    1673, # /ssst/i:\x{DF}\x{FB05}:y:$&:\x{DF}\x{FB05} => `/', match=
    # [perl #101970]
    1678, # /[[:lower:]]/i:\x{100}:y:$&:\x{100} => `/', match=
    1679, # /[[:upper:]]/i:\x{101}:y:$&:\x{101} => `/', match=
    # Was matching 'ss' only and failing the entire match, not seeing the
    # alternative that would succeed
    1683, # /s\xDF/ui:\xDFs:y:$&:\xDFs => `/', match=
    1684, # /sst/ui:s\N{LATIN SMALL LIGATURE ST}:y:$&:s\N{LATIN SMALL LIGATURE ST} => `/', match=
    1685, # /sst/ui:s\N{LATIN SMALL LIGATURE LONG S T}:y:$&:s\N{LATIN SMALL LIGATURE LONG S T} => `/', match=
    
    # [perl #111400].  Tests the first Y/N boundary above 255 for each of these.
    1699, # /[[:alnum:]]/:\x{2c1}:y:-:- => `-', match=
    1701, # /[[:alpha:]]/:\x{2c1}:y:-:- => `-', match=
    1703, # /[[:graph:]]/:\x{377}:y:-:- => `-', match=
    1706, # /[[:lower:]]/:\x{101}:y:-:- => `-', match=
    1708, # /[[:print:]]/:\x{377}:y:-:- => `-', match=
    1711, # /[[:punct:]]/:\x{37E}:y:-:- => `-', match=
    1713, # /[[:upper:]]/:\x{100}:y:-:- => `-', match=
    1715, # /[[:word:]]/:\x{2c1}:y:-:- => `-', match=

    # $^N, $+ on backtrackracking
    # BRANCH
    1739, # ^(.)(?:(..)|B)[CX]:ABCDE:y:$^N-$+:A-A => `-', match=1
    # TRIE
    1741, # ^(.)(?:BC(.)|B)[CX]:ABCDE:y:$^N-$+:A-A => `-', match=1
    # CURLYX
    1743, # ^(.)(?:(.)+)*[BX]:ABCDE:y:$^N-$+:A-A => `-', match=1
    # CURLYM
    1746, # ^(.)(BC)*[BX]:ABCDE:y:$^N-$+:A-A => `-', match=1
    # CURLYN
    1749, # ^(.)(B)*.[CX]:ABCDE:y:$^N-$+:A-A => `-', match=1

    # [perl #114220]
    1793, # (utf8::upgrade($subject)) /[\H]/:\x{BF}:y:$&:\xBF => `�', match=1
    1794, # (utf8::upgrade($subject)) /[\H]/:\x{A0}:n:-:- => false positive
    1795, # (utf8::upgrade($subject)) /[\H]/:\x{A1}:y:$&:\xA1 => `�', match=1

    # \W in pattern -> !UTF8: add UTF if subject is UTF8 [#15]
    1804..1807, # \w:\x{200C}:y:$&:\x{200C} => `\', match=
    #1805, # \W:\x{200C}:n:-:- => false positive
    #1806, # \w:\x{200D}:y:$&:\x{200D} => `\', match=
    #1807, # \W:\x{200D}:n:-:- => false positive
    
    # again missing UTF [#15]
    1818..1820, # /^\D{11}/a:\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}\x{10FFFF}:n:-:- => false positive
    1823, # (utf8::upgrade($subject)) \Vn:\xFFn/:y:$&:\xFFn => `�n', match=1
    1830, # a?\X:a\x{100}:y:$&:a\x{100} => `a�', match=1
    1892, # /^\S+=/d:\x{3a3}=\x{3a0}:y:$&:\x{3a3}= => `Σ=', match=1
    1893, # /^\S+=/u:\x{3a3}=\x{3a0}:y:$&:\x{3a3}= => `Σ=', match=1
    1936, # /[a-z]/i:\N{KELVIN SIGN}:y:$&:\N{KELVIN SIGN} => `/', match=
    1937, # /[A-Z]/ia:\N{KELVIN SIGN}:y:$&:\N{KELVIN SIGN} => `/', match=
    1939, # /[A-Z]/i:\N{LATIN SMALL LETTER LONG S}:y:$&:\N{LATIN SMALL LETTER LONG S} => `/', match=
    
    1964, # \N(?#comment){SPACE}:A:c:-:Missing braces on \\N{} => `-', match=
    1983, # /(?xx:[a b])/x:\N{SPACE}:n:-:- => false positive
    1985, # /(?xx)[a b]/x:\N{SPACE}:n:-:- => false positive

    # [perl #125825]
    1945, # /(a+){1}+a/:aaa:n:-:- => false positive
    
    # [perl 128420] recursive matches
    1976, # aa$|a(?R)a|a:aaa:y:$&:aaa => `a', match=1

    # /xx pcre2 10.30-RC1 regression
    1992, 1994
  );
# uninitialized stack element st.reg_sv and subsequent heap-buffer-overflow #19
# "a_\xF7" =~ /^(\x{100}|a)(??{ qr/.?\xF7/d})/
push @pcre_skip, (1840);

# version-specifics, older perls:
push @pcre_fail, (
    1443,1444
  ) if $] < 5.012;
push @pcre_fail, (
    1515..1517, 1522..1523, 1525..1526, 1622..1625, 1638, 1643
  ) if $] < 5.014;
push @pcre_fail, (
    554, 629, 653, 659, 662, 672, 939, 1101..1104,
    1107..1110, 1116..1119, 1122, 1124..1125, 1128..1129,
    1285, 1287..1293, 1322, 1324,
    1329..1330, 1334, 1361, 1364,
  ) if $] < 5.016;
# many tests pass with PCRE but fail with core.
# so it will be actually safer to use PCRE2 than core.
if (!$INC{'re/engine/PCRE2.pm'}) {
    push @pcre_skip, (629,1367) if $] < 5.014;
    push @pcre_fail, (
        40..51, 90..91, 93..94, 96..97, 105, 356, 539,
        541, 543, 577, 1360, 1416, 1418, 1456..1457,
        1461..1462) if $] < 5.012;
    push @pcre_fail, (
        1448, 1521, 1524, 1577..1578, 1594..1596,
        1598, 1674..1675) if $] < 5.014;
    push @pcre_fail, (
        1633..1634) if $] < 5.016;
    push @pcre_fail, (
        871, 1745, 1789, 1816
        )  if $] < 5.018;
    push @pcre_fail, (
        1674..1675, 1856..1857, 1885..1886, 1889
        )  if $] < 5.020;
    push @pcre_fail, (
        138..142)  if $] < 5.022;
    push @pcre_fail, (
        139, 1958, 1965)  if $] < 5.024;
    push @pcre_fail, (
        1977)  if $] < 5.026;
}

push @pcre_fail, (1638)     if "$]" =~ /^5\.01[34]/;
push @pcre_fail, (554, 672) if "$]" =~ /^5\.01[3-6]/;
push @pcre_fail, (629)      if "$]" =~ /^5\.01[3-8]/;
# codeblocks
push @pcre_fail, (1770..1776, 1778, 1809) if "$]" =~ /^5\.01[56]/;
push @pcre_fail, (1960..1962, 1966, 1987, 1989..1991)
  if "$]" =~ /^5\.0(19|20)/;
push @pcre_fail, (1960..1962, 1966, 1987..1992, 1994, 1996)
  if "$]" =~ /^5\.02[12]/;
push @pcre_fail, (1992, 1994) # cperl only
  if $] >= 5.026 and "$^V" =~ /^v5\.2[67]\.\dc/;
# return in codeblock
push @pcre_skip, (552,1753,1755,1758..1765)
  if $] >= 5.015007 and $] < 5.022; # syntax error crashes
push @pcre_skip, (1383,1399,1410,1548..1572,1639,1792,1830)
  if $] < 5.020; # Malformed UTF-8 character (fatal), group index overflow
push @pcre_skip, (1981) if $] < 5.026; # crashes
push @pcre_fail, (1976) if $] < 5.026; # fixed with 5.26 [perl 128420]
my %skip_ver;
$skip_ver{'5.015'} = 1684; # skip < 5.14, >= 1684
$skip_ver{'5.021'} = 1896; # skip < 5.20, >= 1896
$skip_ver{'5.026'} = 1981; # skip < 5.26, >= 1981
if ($INC{'re/engine/PCRE2.pm'}) {
    my $pcre2ver = re::engine::PCRE2::config('VERSION');
    if ($pcre2ver =~ /^10\.[01]0/) {
        diag("too old PCRE2 $pcre2ver, skipping 2 tests");
        push @pcre_skip, (1957,1958); # skip old pcre2 versions which do crash
    }
}
if (!$num) {
    @pcre_fail{@pcre_fail} = ();
    @pcre_skip{@pcre_skip} = ();
}

TEST:
foreach (@tests) {
    $test++;
    if (!/\S/ || /^\s*#/ || /^__END__$/) {
        print "ok $test #skip (blank line or comment)\n";
        if (/\S/) { print $_ };
        next;
    }
    #if (/\(\?\{/ || /\(\?\?\{/) {
    #    #but correctly falls back now
    #    print "# (PCRE doesn't support (?{}) or (??{}))\n";
    #    $pcre_fail{$test}++;
    #}
    if (exists $pcre_skip{$test}) {
        print "ok $test #SKIP fatal with this perl\n";
        next;
    }
    for my $ver (sort keys %skip_ver) {
        if ($test >= $skip_ver{$ver} && $] < $ver) {
            print "ok $test #SKIP test too new for $]\n";
            $skip_rest = 1;
            next TEST;
        }
    }
    if ($skip_rest) {
        print "ok $test #SKIP rest\n";
        next;
    }
    chomp;
    s/\\n/\n/g;
    my ($pat, $subject, $result, $repl, $expect, $reason, $comment) = split(/\t/,$_,7);
    if (!defined $subject) {
        die "Bad test definition on line $test: $_\n";
    }
    $reason = '' unless defined $reason;
    my $input = join(':',$pat,$subject,$result,$repl,$expect);
    $pat = "'$pat'" unless $pat =~ /^[:'\/]/;
    $pat =~ s/(\$\{\w+\})/$1/eeg;
    $pat =~ s/\\n/\n/g;
    $pat = convert_from_ascii($pat) if ord("A") != 65;

    $subject = convert_from_ascii($subject) if ord("A") != 65;
    $subject = eval qq("$subject"); die $@ if $@;

    $expect = convert_from_ascii($expect) if ord("A") != 65;
    $expect  = eval qq("$expect"); die $@ if $@;
    $expect = $repl = '-' if $skip_amp and $input =~ /\$[&\`\']/;

    #my $todo_qr = $qr_embed_thr && ($result =~ s/t//);
    my $skip = ($skip_amp ? ($result =~ s/B//i) : ($result =~ s/B//));
    ++$skip if $result =~ s/M// && !defined &DynaLoader::boot_DynaLoader;
    # regex_sets sS ? those 6 tests are failing
    $result =~ s/[sS]//g;
    if ($result =~ s/a// && ord("A") != 65) {
        $skip++;
        $reason = "Test is only valid for ASCII platforms.  $reason";
    }
    if ($result =~ s/e// && ord("A") != 193) {
        $skip++;
        $reason = "Test is only valid for EBCDIC platforms.  $reason";
    }
    $reason = 'skipping $&' if $reason eq '' && $skip_amp;
    $result =~ s/B//i unless $skip;

    my $todo= $result =~ s/T// ? " #TODO" : "";
    if ($result =~ s/p// or $todo) {
        $pcre_fail{$test}++;
    }
    $todo = " #TODO" if !$todo or $pcre_fail{$test};
    my $testname= $test;
    if ($comment) {
        $comment=~s/^\s*(?:#\s*)?//;
        $testname .= " - $comment" if $comment;
    }

    for my $study ('', 'study $subject', 'utf8::upgrade($subject)',
		   'utf8::upgrade($subject); study $subject') {
	# Need to make a copy, else the utf8::upgrade of an alreay studied
	# scalar confuses things.
        next if $study and ($pcre_fail{$test} or $skip);
	my $subject = $subject;
	my $c = $iters;
	my ($code, $match, $got);
        if ($repl eq 'pos') {
            $code= <<EOFCODE;
                $study;
                pos(\$subject)=0;
                \$match = ( \$subject =~ m${pat}g );
                \$got = pos(\$subject);
EOFCODE
        }
        elsif ($qr_embed) {
            $code= <<EOFCODE;
                my \$RE = qr$pat;
                $study;
                \$match = (\$subject =~ /(?:)\$RE(?:)/) while \$c--;
                \$got = "$repl";
EOFCODE
        }
        else {
            $code= <<EOFCODE;
                $study;
                \$match = (\$subject =~ $OP$pat) while \$c--;
                \$got = "$repl";
EOFCODE
        }
	{
	    # Probably we should annotate specific tests with which warnings
	    # categories they're known to trigger, and hence should be
	    # disabled just for that test
            no warnings qw(uninitialized regexp);
            if ($INC{'re/engine/PCRE2.pm'}) {
                eval "BEGIN { \$^H{regcomp} = re::engine::PCRE2->ENGINE; }; $code"
            } else {
                eval $code; # use perl's engine
            }
	}
	chomp( my $err = $@ );
	if ($result =~ /c/) {
	    if ($err !~ m!^\Q$expect!) {
                # TODO: 6 wrong tests with expecting 'False [] range'
                # Also broken upstream in perl5.
                print "not ok $testname$todo (compile) $input => '$err'\n"; next TEST
            }
	    last;  # no need to study a syntax error
	}
	elsif ( $skip ) {
	    print "ok $test # skipped", length($reason) ? " $reason" : '', "\n";
	    next TEST;
	}
	elsif ($@) {
	    print "not ok $test ";
            print "#TODO " if exists $pcre_fail{$test};
            print "$input => error `$err'\n$code\n"; next TEST;
	}
	elsif ($result =~ /n/) {
	    if ($match) {
              print "not ok $test ";
              print "#TODO " if exists $pcre_fail{$test};
              print "($study) $input => false positive\n";
              next TEST
            }
	}
	else {
	    if (!$match || $got ne $expect) {
                my $s = Data::Dumper->new([$subject],['subject'])->Useqq(1)->Dump;
                my $g = Data::Dumper->new([$got],['got'])->Useqq(1)->Dump;
                print "not ok $test ";
                print "#TODO " if exists $pcre_fail{$test};
                print "($study) $input => `$got', match=$match\n$s\n$g\n$code\n";
                next TEST;
	    }
	}
    }
    print "ok $test\n";
}

1;
