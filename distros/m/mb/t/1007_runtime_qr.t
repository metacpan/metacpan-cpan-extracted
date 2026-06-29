# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

# Runtime UTF-8 codepoint regex engine test for $mb{qr/.../} (FETCH -> _r2_qr).
#
# mb's import() exports an *untied* copy of %mb (snapshot), so the runtime
# qr interface is exercised here by tie()ing %mb to 'mb' directly. This also
# keeps the test independent of the source-code filter: mb is loaded with
# require (which does not run import and does not install the filter), and
# the script encoding is set explicitly. The string and pattern literals are
# raw UTF-8 octets (no "use utf8"), exactly as the runtime engine expects.

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
require mb;
mb::set_script_encoding('utf8');
use vars qw(@test %mb);

tie %mb, 'mb';

@test = (

    # --- basic literal and character-class matching ---
    sub { 'あいうえお漢字ABC' =~ $mb{qr/[あ-お]+/}      ? 1 : 0 },
    sub { 'あいうえお漢字ABC' =~ $mb{qr/漢字/}          ? 1 : 0 },
    sub { ('漢' =~ $mb{qr/[a-z]/})                      ? 0 : 1 },
    sub { ('か'  =~ $mb{qr/[あ-お]/})                   ? 0 : 1 }, # か is just past お: out of range
    sub { ('お'  =~ $mb{qr/[あ-お]/})                   ? 1 : 0 }, # お is the range end: in range

    # --- substitution via $mb{qr/.../} ---
    sub { (my $t = 'あ漢A') =~ s<$mb{qr/漢/}><X>;  $t eq 'あXA' },
    sub { (my $t = 'あいうえお') =~ s<$mb{qr/[い-え]/}><_>g; $t eq 'あ___お' },

    # --- "." and \G one-codepoint walking (strict $x => one UTF-8 char) ---
    sub { my @c = ('あいう' =~ m<\G$mb{qr/(.)/}>g); scalar(@c) == 3 },
    sub { my @c = ('a漢b字' =~ m<\G$mb{qr/(.)/}>g); (scalar(@c)==4) and ($c[1] eq '漢') and ($c[3] eq '字') },

    # --- ASCII shorthand classes still work alongside multibyte ---
    sub { 'ABC123' =~ $mb{qr/\d+/}                     ? 1 : 0 },
    sub { 'foo_bar' =~ $mb{qr/\w+/}                    ? 1 : 0 },
    sub { ' \t ' =~ $mb{qr/\s/}                       ? 1 : 0 },

    # --- POSIX classes ---
    sub { '7' =~ $mb{qr/[[:digit:]]/}                   ? 1 : 0 },
    sub { '漢' =~ $mb{qr/[[:alpha:]]/}                  ? 0 : 1 }, # multibyte is not [:alpha:]

    # --- negated class with multibyte ---
    sub { ('漢' =~ $mb{qr/[^あ-お]/})                   ? 1 : 0 }, # 漢 is outside [あ-お]
    sub { ('い' =~ $mb{qr/[^あ-お]/})                   ? 0 : 1 }, # い is inside, so [^..] fails

    # --- quantifiers on multibyte codepoints ---
    sub { '漢漢漢' =~ $mb{qr/漢{2,3}/}                  ? 1 : 0 },
    sub { ('漢' =~ $mb{qr/漢{2,3}/})                    ? 0 : 1 }, # only one 漢: {2,3} fails
    sub { 'あ漢漢い' =~ $mb{qr/漢+/}                    ? 1 : 0 },
    sub { '' =~ $mb{qr/漢*/}                            ? 1 : 0 }, # zero-width ok

    # --- alternation ---
    sub { '字' =~ $mb{qr/あ|字/}                        ? 1 : 0 },

    # --- mixed ASCII range + multibyte range in one class ---
    sub { 'Z' =~ $mb{qr/[A-Zあ-ん]/}                    ? 1 : 0 },
    sub { 'ん' =~ $mb{qr/[A-Zあ-ん]/}                   ? 1 : 0 },
    sub { ('5' =~ $mb{qr/[A-Zあ-ん]/})                  ? 0 : 1 }, # digit not in either range

    # --- /i modifier on ASCII portion ---
    sub { 'ABC' =~ $mb{qr/abc/i}                        ? 1 : 0 },

    # --- /s modifier: "." matches everything incl. newline ---
    sub { "\n" =~ $mb{qr/./s}                          ? 1 : 0 },
    sub { ("\n" =~ $mb{qr/./})                         ? 0 : 1 }, # without /s, "." excludes \n
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
