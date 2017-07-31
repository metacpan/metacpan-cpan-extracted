# NAME 

re::engine::PCRE2 - PCRE2 regular expression engine with jit

# SYNOPSIS

    use re::engine::PCRE2;

    if ("Hello, world" =~ /(?<=Hello|Hi), (world)/) {
        print "Greetings, $1!";
    }

# DESCRIPTION

Replaces perl's regex engine in a given lexical scope with PCRE2
regular expressions provided by libpcre2-8.

This provides jit support and faster matching, but may fail in corner
cases. See
[pcre2compat](http://www.pcre.org/current/doc/html/pcre2compat.html).
It is typically 50% faster than the core regex engine. See ["BENCHMARKS"](#benchmarks).

The goal is to pass the full core re testsuite, identify all
problematic patterns and fall-back to the core re engine.  From the
1330 core tests, 46 currently fail. 90% of the most popular cpan
modules do work fine already. Note that older perl version do fail
more regression tests. See ["FAILING TESTS"](#failing-tests).

Note that some packaged libpcre2-8 libraries do not enable the jit
compiler. `CFLAGS=-fPIC cmake -DPCRE2_SUPPORT_JIT=ON; make`
PCRE2 then silently falls back to the normal PCRE2 compiler and matcher.

Check with:

    perl -Mre::engine::PCRE2 -e'print re::engine::PCRE2::JIT'

# METHODS

Since re::engine::PCRE2 derives from the `Regexp` package, you can call
compiled `qr//` objects with these methods.
See [PCRE2 NATIVE API MATCH CONTEXT FUNCTIONS](http://www.pcre.org/current/doc/html/pcre2api.html#SEC5)
and [INFORMATION ABOUT A COMPILED PATTERN](http://www.pcre.org/current/doc/html/pcre2api.html#SEC22).

With older library versions which do not support a particular info method, undef is returned.
E.g. hasbackslashc and framesize.

- \_alloptions (RX)

    The result of pcre2\_pattern\_info(PCRE2\_INFO\_ALLOPTIONS) as unsigned integer.

        my $q=qr/(a)/; print $q->_alloptions
        => 64

    64 stands for PCRE2\_DUPNAMES which is always set. See `pcre2.h`

- \_argoptions (RX)

    The result of pcre2\_pattern\_info(PCRE2\_INFO\_ARGOPTIONS) as unsigned integer.

        my $q=qr/(a)/i; print $q->_argoptions
        => 72

    72 = 64+8
    64 stands for PCRE2\_DUPNAMES which is always set.
    8 for PCRE2\_CASELESS.
    See `pcre2.h`

- backrefmax (RX)

    Return the number of the highest back reference in the pattern.

        my $q=qr/(a)\1/; print $q->backrefmax
        => 1
        my $q=qr/(a)(?(1)a|b)/; print $q->backrefmax
        => 1

- bsr (RX)

    What character sequences the `\R` escape sequence matches.
    1 means that `\R` matches any Unicode line ending sequence;
    2 means that `\R` matches only CR, LF, or CRLF.

- capturecount (RX)

    Return the highest capturing subpattern number in the pattern. In
    patterns where `(?|` is not used, this is also the total number of
    capturing subpatterns.

        my $q=qr/(a(b))/; print $q->capturecount
        => 2

- firstbitmap (RX)

    In the absence of a single first code unit for a non-anchored pattern,
    `pcre2_compile()` may construct a 256-bit table that defines a fixed set
    of values for the first code unit in any match. For example, a pattern
    that starts with `[abc]` results in a table with three bits set. When
    code unit values greater than 255 are supported, the flag bit for 255
    means "any code unit of value 255 or above". If such a table was
    constructed, it is returned as string.

- firstcodetype (RX)

    Return information about the first code unit of any matched string,
    for a non-anchored pattern. If there is a fixed first value, for
    example, the letter "c" from a pattern such as `(cat|cow|coyote)`, 1
    is returned, and the character value can be retrieved using
    ["firstcodeunit"](#firstcodeunit). If there is no fixed first value, but it is known
    that a match can occur only at the start of the subject or following a
    newline in the subject, 2 is returned. Otherwise, and for anchored
    patterns, 0 is returned.

- firstcodeunit (RX)

    Return the value of the first code unit of any matched string in the
    situation where ["firstcodetype (RX)"](#firstcodetype-rx) returns 1; otherwise return
    0\. The value is always less than 256.

        my $q=qr/(cat|cow|coyote)/; print $q->firstcodetype, $q->firstcodeunit
        => 1 99

- framesize (RX)

    Undocumented. Only available since pcre-10.24.
    Returns undef on older versions.
    The pcre2\_match() frame size.

- hasbackslashc (RX)

    Return 1 if the pattern contains any instances of \\C, otherwise 0.
    Note that \\C is forbidden since perl 5.26 (?).
    With an older pcre2 library undef will be returned.

- hascrorlf (RX)

    Return 1 if the pattern contains any explicit matches for CR or LF
    characters, otherwise 0. An explicit match is either a literal CR or LF
    character, or \\r or \\n.

- heaplimit (RX, \[INT\])

    Get or set the backtracking heap limit in a match context.  If the
    option is not set, build-time 'HEAPLIMIT' option is in effect, which
    is 20000000.  See ["config (OPTION)"](#config-option).  Added only since 10.30, with
    earlier versions it will return undef.  The setter method is not yet
    implemented.

- jchanged (RX)

    Return 1 if the (?J) or (?-J) option setting is used in the pattern,
    otherwise 0. (?J) and (?-J) set and unset the local PCRE2\_DUPNAMES
    option, respectively.

- jitsize (RX)

    If the compiled pattern was successfully processed by
    pcre2\_jit\_compile(), return the size of the JIT compiled code,
    otherwise return zero.

- lastcodetype (RX)

    Returns 1 if there is a rightmost literal code unit that must exist in
    any matched string, other than at its start. If there is no such value, 0 is
    returned. When 1 is returned, the code unit value itself can be
    retrieved using ["lastcodeunit (RX)"](#lastcodeunit-rx). For anchored patterns, a last
    literal value is recorded only if it follows something of variable
    length. For example, for the pattern `/^a\d+z\d+/` the returned value is
    1 (with "z" returned from lastcodeunit), but for `/^a\dz\d/`
    the returned value is 0.

- lastcodeunit (RX)

    Return the value of the rightmost literal data unit that must exist in
    any matched string, other than at its start, if such a value has been
    recorded. If there is no such value, 0 is returned.

- matchempty (RX)

    Return 1 if the pattern might match an empty string, otherwise 0. When
    a pattern contains recursive subroutine calls it is not always
    possible to determine whether or not it can match an empty
    string. PCRE2 takes a cautious approach and returns 1 in such cases.

- matchlimit (RX, \[INT\])

    Get or set the match\_limit match context.  Corresponds to the
    pcre-specific `(*LIMIT_MATCH=nnnn)` option. If the option is not set,
    build-time 'MATCHLIMIT' option is in effect, which is 10000000.
    See ["config (OPTION)"](#config-option).

- maxlookbehind (RX)

    Return the number of characters (not code units) in the longest
    lookbehind assertion in the pattern. This information is useful when
    doing multi-segment matching using the partial matching
    facilities. Note that the simple assertions \\b and \\B require a
    one-character lookbehind. \\A also registers a one-character
    lookbehind, though it does not actually inspect the previous
    character. This is to ensure that at least one character from the old
    segment is retained when a new segment is processed. Otherwise, if
    there are no lookbehinds in the pattern, \\A might match incorrectly at
    the start of a new segment.

- minlength (RX)

    If a minimum length for matching subject strings was computed, its
    value is returned. Otherwise the returned value is 0. The value is a
    number of characters, which in UTF mode may be different from the
    number of code units. The value is a lower bound to the length of any
    matching string. There may not be any strings of that length that do
    actually match, but every string that does match is at least that
    long.

- namecount (RX)
- nameentrysize (RX)

    PCRE2 supports the use of named as well as numbered capturing
    parentheses. The names are just an additional way of identifying the
    parentheses, which still acquire numbers. Several convenience
    functions such as pcre2\_substring\_get\_byname() are provided for
    extracting captured substrings by name. It is also possible to extract
    the data directly, by first converting the name to a number in order
    to access the correct pointers in the output vector. To do the
    conversion, you need to use the name-to-number map, which is described
    by these three values.

    The map consists of a number of fixed-size
    entries. namecount gives the number of entries, and
    nameentrysize gives the size of each entry in code units;
    The entry size depends on the length of the longest name.

    The nametable itself is not yet returned.

- newline (RX, \[INT\]))

    Get or set the newline regime.
    The default is the build-time 'NEWLINE' option, i.e. 2 on non-windows systems.
    See ["config (OPTION)"](#config-option).
    The setter method is not yet implemented.

- recursionlimit (RX, \[INT\])

    Get or set a recursion limit, i.e. the pcre specific
    `(*LIMIT_RECURSION=nnnn)` option.
    The default is the build-time 'RECURSIONLIMIT' option.
    See ["config (OPTION)"](#config-option).
    The setter method is not yet implemented.

- size (RX)

    Return the size of the compiled pattern in bytes.  This value includes
    the size of the general data block that precedes the code units of the
    compiled pattern itself. The value that is used when
    `pcre2_compile()` is getting memory in which to place the compiled
    pattern may be slightly larger than the value returned by this option,
    because there are cases where the code that calculates the size has to
    over-estimate. Processing a pattern with the JIT compiler does not
    alter the value returned by this option.

# FUNCTIONS

- import

    import lexically sets the PCRE2 engine to be active.

    import will later accept compile context options.
    See [PCRE2 NATIVE API COMPILE CONTEXT FUNCTIONS](http://www.pcre.org/current/doc/html/pcre2api.html#SEC4).

        bsr            => INT (default: 1)
        max_pattern_length => INT
        newline        => INT (default: 2)
        parenslimit    => INT (default: 250)
        matchlimit     => INT (default: 10000000)
        offsetlimit    => INT (default: ?)
        recursionlimit => INT (default: 10000000) i.e. the depthlimit
        heaplimit      => INT (default: 20000000) ony since 10.30

- unimport

    unimport sets the regex engine to the previous one.
    If PCRE2 with the previous context options.

- offsetlimit (\[INT\])

    Get or set the offset\_limit in the match context.
    The method is not yet implemented.

- parenslimit (\[INT\])

    Get or set the parens\_nest\_limit in the match context.
    The default is the build-time 'PARENSLIMIT' option, 250.
    See ["config (OPTION)"](#config-option).
    The method is not yet implemented.

- ENGINE

    Returns a pointer to the internal PCRE2 engine, suitable for the
    XS API `(regexp*)re->engine` field.

- JIT

    Returns 1 or 0, if the JIT engine is available or not.

- config (OPTION)

    Returns build-time information about libpcre2.
    Note that some of these options may later be set'able at run-time.

    OPTIONS can be one of the following strings:

        JITTARGET
        UNICODE_VERSION
        VERSION

        BSR
        JIT
        LINKSIZE
        MATCHLIMIT
        HEAPLIMIT       (Only since 10.30)
        NEWLINE
        PARENSLIMIT
        DEPTHLIMIT      (Not always defined)
        RECURSIONLIMIT  (Obsolete synonym for DEPTHLIMIT)
        STACKRECURSE    (Obsolete. Always 0 in newer libs)
        UNICODE

    The first three options return a string, the rest an integer.
    In case of internal errors, e.g. the new option is not yet supported by libpcre,
    undef is returned.
    See [http://www.pcre.org/current/doc/html/pcre2api.html#SEC17](http://www.pcre.org/current/doc/html/pcre2api.html#SEC17).

    NEWLINE returns an integer, representing:

        PCRE2_NEWLINE_CR          1
        PCRE2_NEWLINE_LF          2
        PCRE2_NEWLINE_CRLF        3
        PCRE2_NEWLINE_ANY         4  Any Unicode line ending
        PCRE2_NEWLINE_ANYCRLF     5  Any of CR, LF, or CRLF

    The default is OS specific.

    BSR returns an integer, representing:

        PCRE2_BSR_UNICODE         1
        PCRE2_BSR_ANYCRLF         2

    A value of PCRE2\_BSR\_UNICODE means that `\R` matches any Unicode line
    ending sequence; a value of PCRE2\_BSR\_ANYCRLF means that `\R` matches
    only CR, LF, or CRLF.

    The default is 1 for UNICODE, as all libpcre2 libraries are now compiled
    with unicode support builtin. (`--enable-unicode`).

# BENCHMARKS

    time perl5.24.1 -Mblib t/perl/regexp.t 10000 >/dev/null

Without PCRE2:

    34.327s

With PCRE2:

    17.922s - 50% faster

# FAILING TESTS

About 90% of all core tests and cpan modules do work with re::engine::PCRE2
already, but there are still some unresolved problems.
Esp. when the pattern is not detectable or marked as UTF-8 but the subject is,
the match will be performed without UTF-8.

Try the new faster matcher with `export PERL5OPT=-Mre::engine::PCRE2`.

Known problematic popular modules are: Test-Harness-3.38,
Params-Util-1.07 _t/12\_main.t 552-553, 567-568_, HTML-Parser-3.72
_(unicode)_, DBI-1.636 _(EUMM problem)_, DBD-SQLite-1.54
_(xsubpp)_, Sub-Name-0.21 _t/exotic\_names.t:105_, XML-LibXML-2.0129
_(local charset)_, Module-Install-1.18 _unrecognized character after
(?  or (?-_, Text-CSV\_XS-1.28 _(unicode)_, YAML-Syck-1.29, MD5-2.03,
XML-Parser-2.44, Module-Build-0.4222, libwww-perl-6.25.

As of 0.05 the following core regression tests still fail:

    perl -C -Mblib t/perl/regexp.t | grep -a TODO

    # new patterns and pcre2 fails: need to fallback
    143..146, # \B{gcb} \B{lb} \B{sb} \B{wb}
    352,      # '^'i:ABC:y:$&:
    402,      # '(a+|b){0,1}?'i
    409,      # 'a*'i $&
    578,      # '(b.)c(?!\N)'s:a
    654,655,664, # unicode
    667,      # '[[:^cntrl:]]+'u:a\x80:y:$&:a

    # Pathological patterns that run into run-time PCRE_ERROR_MATCHLIMIT,
    # even with huge set_match_limit 512mill
    880 .. 897, # .X(.+)+[X][X]:bbbbXXXaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

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

Note that core tests suite also reveals that about a similar number of
fails occur with older perls, without PCRE2. Many of them pass with PCRE2.

**Failures in older perls**:

    -5.12:  629, 1367 (fatal)
    -5.10:  40..51, 90..91, 93..94, 96..97, 105, 356, 539,
            541, 543, 577, 1360, 1416, 1418, 1456..1457,
            1461..1462
    -5.12:  1448, 1521, 1524, 1577..1578, 1594..1596,
            1598, 1674..1675
    -5.14:  1633..1634
    -5.16:  871, 1745, 1789, 1816
    -5.18:  1674..1675, 1856..1857, 1885..1886, 1889
    -5.20:  138..142
    -5.22:  139, 1958, 1965
    -5.24:  1977

Invalid tests for older perls (fatal):

    -5.14: 1684..1996
    -5.20: 1896..1996
    -5.26: 1981..1996

# AUTHORS

Reini Urban <rurban@cpan.org>

# COPYRIGHT

Copyright 2007 Ævar Arnfjörð Bjarmason.
Copyright 2017 Reini Urban.

The original version was copyright 2006 Audrey Tang
<cpan@audreyt.org> and Yves Orton.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
