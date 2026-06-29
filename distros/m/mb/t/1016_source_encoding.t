die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Step 7 test for mb::_insert_source_encoding_unimport().
#
# Perl 5.41+ turns on the source::encoding pragma (UTF-8 source by default)
# whenever "use v5.41" (or "use 5.041") or later appears in a script. mb
# transpiles to octet-oriented Perl and keeps comments / POD as raw octets,
# so it appends "no source::encoding;" on the SAME physical line as the
# version statement (before any trailing comment) to cancel that pragma
# without shifting line numbers in error messages.
#
# This file inspects the transpiled text directly (no Perl 5.41 interpreter
# is required), so it runs on every perl from 5.005_03 up: it uses no source
# filter and no version-specific feature. The body is pure US-ASCII.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
use vars qw(@test);

# transpile-injection under test
sub inj {
    return mb::_insert_source_encoding_unimport($_[0]);
}

# does the result carry the unimport?
sub has {
    return $_[0] =~ /no source::encoding;/ ? 1 : 0;
}

# count newlines (to prove no extra physical line is introduced)
sub nl {
    my $s = $_[0];
    my $n = ($s =~ tr/\n//);
    return $n;
}

@test = (
# 1 -- "use v5.41" gets the unimport
    sub { has(inj("use v5.41;\n"))            },
# 2 -- "use v5.42" gets the unimport
    sub { has(inj("use v5.42;\n"))            },
# 3 -- numeric "use 5.041" gets the unimport
    sub { has(inj("use 5.041;\n"))            },
# 4 -- numeric "use 5.042" gets the unimport
    sub { has(inj("use 5.042;\n"))            },
# 5 -- a higher v-string ("use v5.50") still matches
    sub { has(inj("use v5.50;\n"))            },
# 6 -- a higher numeric ("use 5.050") still matches
    sub { has(inj("use 5.050;\n"))            },
# 7 -- a three-part v-string ("use v5.41.0") still matches
    sub { has(inj("use v5.41.0;\n"))          },
    sub {1},
# 9 -- below threshold: "use v5.40" is NOT touched (no source::encoding there)
    sub { !has(inj("use v5.40;\n"))           },
# 10 -- below threshold: "use 5.040" is NOT touched
    sub { !has(inj("use 5.040;\n"))           },
# 11 -- old v-string "use v5.8" is NOT touched
    sub { !has(inj("use v5.8;\n"))            },
# 12 -- old numeric "use 5.008" is NOT touched
    sub { !has(inj("use 5.008;\n"))           },
    sub {1},
# 14 -- injection adds NO new physical line (line numbers stay put)
    sub { nl(inj("use v5.42;\n")) == nl("use v5.42;\n") },
# 15 -- the unimport sits on the same line, exactly as designed
    sub { inj("use v5.42;\n") eq "use v5.42; no source::encoding;\n" },
# 16 -- numeric form yields the exact same-line result
    sub { inj("use 5.041;\n") eq "use 5.041; no source::encoding;\n" },
# 17 -- a leading-indented statement keeps its indent and is still injected
    sub { inj("    use v5.42;\n") eq "    use v5.42; no source::encoding;\n" },
    sub {1},
# 19 -- a trailing comment is preserved after the unimport
    sub { inj("use v5.42; # tail\n") =~ /\# tail/ },
# 20 -- the unimport is placed BEFORE the trailing comment, not after it
    sub {
        my $o = inj("use v5.42; # tail\n");
        index($o, 'no source::encoding;') < index($o, '#');
    },
# 21 -- the comment text itself is left intact
    sub { inj("use v5.42; # tail\n") eq "use v5.42; no source::encoding; # tail\n" },
    sub {1},
# 23 -- a CRLF line ending is preserved
    sub { inj("use v5.42;\r\n") eq "use v5.42; no source::encoding;\r\n" },
# 24 -- a bare CR line ending is preserved
    sub { inj("use v5.42;\r") eq "use v5.42; no source::encoding;\r" },
    sub {1},
# 26 -- two version statements each receive their own unimport
    sub {
        my $o = inj("use v5.42;\nuse v5.43;\n");
        my $c = () = ($o =~ /no source::encoding;/g);
        $c == 2;
    },
# 27 -- the second statement keeps the correct same-line form
    sub {
        inj("use v5.42;\nuse v5.43;\n")
            eq "use v5.42; no source::encoding;\nuse v5.43; no source::encoding;\n";
    },
    sub {1},
# 29 -- "require VERSION" does NOT enable source::encoding, so it is left alone
    sub { !has(inj("require v5.41;\n"))       },
# 30 -- "no v5.41" (not a "use") is left alone
    sub { !has(inj("no v5.41;\n"))            },
    sub {1},
# 32 -- a statement with no version directive is returned unchanged
    sub { inj("print qq{hello};\n") eq "print qq{hello};\n" },
# 33 -- the injected literal is exactly "; no source::encoding;"
    sub { inj("use v5.42;\n") =~ /use v5\.42; no source::encoding;/ },
# 34 -- a missing trailing semicolon is still handled (semicolon optional)
    sub { inj("use v5.42 # tail\n") =~ /no source::encoding;/ },
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } for my $t (@test) { ok($t->()); }

__END__
