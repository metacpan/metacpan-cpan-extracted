# This file is encoded in US-ASCII.
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# An escaped delimiter in a codepoint class: m/[^\/]/, m{[\}]}, s/[\/]/-/,
# split /[\/]/, qr/[\/]/ ...
#
# mb 0.67 before this fix wrote "\/" of a codepoint class as \\/ into
# qq[...] of the transpiled qr/.../, so the "/" was no longer escaped and
# closed the qr/.../: every such script died with "Can't find string
# terminator" or a syntax error.  The escaped delimiter is now written as
# \\\/ and stays escaped.  Checked for every kind of delimiter, with and
# without /x and /xx, in sjis (also with the DAMEMOJI \x83\x5C) and utf8.
#
# The script is US-ASCII; multibyte octets are written as \xHH.  Runs on
# every perl from 5.005_03 up.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        m{\AHaving more than one /x regexp modifier is deprecated at } ? return :
        warn $_[0];
    };
}

# transpile and run; returns the result, or a word of what went wrong
sub run {
    my($encoding, $script) = @_;
    mb::set_script_encoding($encoding);
    my $parsed = CORE::eval { mb::parse($script) };
    if (not defined $parsed) {
        my $error = $@;
        $error =~ s/\n.*//s;
        print "# mb::parse died: $error\n";
        return 'PARSE-ERROR';
    }
    my $result = CORE::eval $parsed;
    if (not defined $result) {
        my $error = $@;
        $error =~ s/\n.*//s;
        print "# transpiled script died: $error\n";
        return 'EVAL-ERROR';
    }
    return $result;
}

my @delimiter = (
    ['/',  '/'],
    ['!',  '!'],
    ['|',  '|'],
    [',',  ','],
    ['#',  '#'],
    ['{',  '}'],
    ['(',  ')'],
    ['<',  '>'],
);

for my $encoding (qw( sjis utf8 )) {
    for my $modifier ('', 'x', 'xx') {
        for my $pair (@delimiter) {
            my($open, $close) = @{$pair};

            # escaped close delimiter
            push @test, sub {
                run($encoding, "join '', map { m$open\\A[a\\$close]\\z$close$modifier ? 1 : 0 } ('a','b','$close');") eq '101';
            };

            # escaped open delimiter of a bracket pair
            if ($open ne $close) {
                push @test, sub {
                    run($encoding, "join '', map { m$open\\A[a\\$open]\\z$close$modifier ? 1 : 0 } ('a','b','$open');") eq '101';
                };
            }
        }

        # negated codepoint class
        push @test, sub {
            run($encoding, "join '', map { m/\\A[^\\/]+\\z/$modifier ? 1 : 0 } ('ab','a/b');") eq '10';
        };

        # escaped delimiter and an escaped backslash
        push @test, sub {
            run($encoding, "join '', map { m/\\A[^\\/\\\\]+\\z/$modifier ? 1 : 0 } ('ab','a/b','a\\\\b');") eq '100';
        };

        # qr//
        push @test, sub {
            run($encoding, "my \$re = qr/\\A[a\\/]\\z/$modifier; join '', map { (\$_ =~ \$re) ? 1 : 0 } ('a','b','/');") eq '101';
        };

        # s/// and s{}{}
        push @test, sub {
            run($encoding, "my \$s = 'a/b/c'; \$s =~ s/[\\/]/-/g$modifier; \$s;") eq 'a-b-c';
        };
        push @test, sub {
            run($encoding, "my \$s = 'a}b}c'; \$s =~ s{[\\}]}{-}g$modifier; \$s;") eq 'a-b-c';
        };

        # split
        push @test, sub {
            run($encoding, "join ',', split(/[\\/]/$modifier, 'a/b/c');") eq 'a,b,c';
        };
    }
}

# structure: the escaped delimiter is written as \xHH, so no delimiter
# octet is left in qq[...] of mb::_cc().  The transpiled qr{...} is nested
# in m{...}, and Perl 5.005_03 removes the backslash of \} at the outer
# level, so a \} (even as \\\}) closed the inner qr{...} early there: this
# checks on every perl what failed only on Perl 5.005_03.
for my $encoding (qw( sjis utf8 )) {
    for my $pair (@delimiter) {
        my($open, $close) = @{$pair};
        for my $escaped ($open eq $close ? ($close) : ($open, $close)) {
            push @test, sub {
                mb::set_script_encoding($encoding);
                my $parsed = CORE::eval { mb::parse("m$open\\A[a\\$escaped]\\z$close;") };
                return 0 if not defined $parsed;
                my $hex = CORE::sprintf('\\x%02X', CORE::ord($escaped));
                if ($parsed !~ /mb::_cc\(qq\[a\\\\\Q$hex\E\]\)/) {
                    print "# transpiled: $parsed\n";
                    return 0;
                }
                return 1;
            };
        }
    }
}

# sjis: the DAMEMOJI \x83\x5C just before an escaped delimiter
push @test, sub {
    run('sjis', "join '', map { m/\\A[" . "\x83\x5C" . "\\/]\\z/ ? 1 : 0 } (\"\\x83\\x5C\",'/','\\\\');") eq '110';
};
push @test, sub {
    run('sjis', "my \$s = 'a/" . "\x83\x5C" . "/b'; \$s =~ s/[" . "\x83\x5C" . "\\/]/-/g; \$s;") eq 'a---b';
};

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
