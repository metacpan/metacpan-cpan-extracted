#!perl

use 5.010001;
use strict;
use warnings;
use constant NL => "\n";

use Data::Dump qw(dump);
use POSIX;
use Test::More 0.98;
use Text::ANSI::Util qw(
                           ta_add_color_resets
                           ta_detect ta_length ta_length_height ta_pad
                           ta_split_codes ta_split_codes_single
                           ta_strip ta_trunc ta_wrap ta_highlight
                           ta_highlight_all ta_extract_codes
                           ta_substr
                   );

subtest "ta_detect" => sub {
    ok(!ta_detect("a"), 'neg 1');
    ok(!ta_detect("\e"), 'neg 2');
    ok( ta_detect("\e[0m"), 'pos 1');
    ok( ta_detect("\e[31;47mhello\e[0m"), 'pos 2');
};

subtest "ta_strip" => sub {
    is(ta_strip(""), "");
    is(ta_strip("hello"), "hello");
    is(ta_strip("\e[31;47mhello\e[0m"), "hello");
};

subtest "ta_extract_codes" => sub {
    is(ta_extract_codes(""), "");
    is(ta_extract_codes("hello"), "");
    is(ta_extract_codes("\e[31;47mhello\e[0m"), "\e[31;47m\e[0m");
};

subtest "ta_split_codes" => sub {
    is_deeply([ta_split_codes("")], []);
    is_deeply([ta_split_codes("a")], ["a"]);
    is_deeply([ta_split_codes("a\e[31m")], ["a", "\e[31m"]);
    is_deeply([ta_split_codes("\e[31ma")], ["", "\e[31m", "a"]);
    is_deeply([ta_split_codes("\e[31ma\e[0m")], ["", "\e[31m", "a", "\e[0m"]);
    is_deeply([ta_split_codes("\e[31ma\e[0mb")], ["", "\e[31m", "a", "\e[0m", "b"]);
    is_deeply([ta_split_codes("\e[31m\e[0mb")], ["", "\e[31m\e[0m", "b"]);
};

subtest "ta_split_codes_single" => sub {
    is_deeply([ta_split_codes_single("\e[31m\e[0mb")], ["", "\e[31m", "", "\e[0m", "b"]);
};

subtest "ta_length" => sub {
    is(ta_length(""), 0);
    is(ta_length("hello"), 5);
    is(ta_length("\e[0m"), 0);
    is(ta_length("\e[31;47mhello\e[0m"), 5);
};

subtest "ta_length_height" => sub {
    is_deeply(ta_length_height(""), [0, 0]);
    is_deeply(ta_length_height("\e[0m"), [0, 0]);
    is_deeply(ta_length_height(" "), [1, 1]);
    is_deeply(ta_length_height(" \n"), [1, 2]);
    is_deeply(ta_length_height("\e[31;47myellow\e[0m\nhello\n"), [6, 3]);
};

# single paragraph
my $txt1 = <<_;
\e[31;47mI\e[0m dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.
_
#qq--------10--------20--------30--------40--------50
my $txt1w =
qq|\e[31;47mI\e[0m dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep me|.NL.
qq|company.|.NL;

# multiple paragraph
my $txt1b = <<_;
\e[31;47mI\e[0m dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.

\e[31;47mI\e[0m dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.
_
#qq--------10--------20--------30--------40--------50
my $txt1bw =
qq|\e[31;47mI\e[0m dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep me|.NL.
qq|company.|.NL.NL.
qq|\e[31;47mI\e[0m dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep me|.NL.
qq|company.|.NL;

# no terminating newline
my $txt1c = "\e[31;47mI\e[0m dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep...";
#qq--------10--------20--------30--------40--------50
my $txt1cw =
qq|\e[31;47mI\e[0m dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep...|;

subtest "ta_wrap" => sub {
    my ($res, $cres);

    $res  = ta_wrap($txt1 , 40);
    $cres = $txt1w;
    is($res, $cres, "single paragraph")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap($txt1b, 40);
    $cres = $txt1bw;
    is($res, $cres, "multiple paragraph")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap($txt1c, 40);
    $cres = $txt1cw;
    is($res, $cres, "no terminating newline")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap("x 12345678901234 x", 10);
    $cres = "x\n1234567890\n1234 x";
    is($res, $cres, "truncate long word 1")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap("x \e[1m12345678901234\e[0m x", 10);
    $cres = "x\e[1m\e[0m\n\e[1m1234567890\e[0m\e[0m\n\e[1m1234\e[0m x";
    is($res, $cres, "truncate long word 2")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap("\e[1m12345678901234\e[0m", 10);
    $cres = "\e[1m1234567890\e[0m\n\e[1m1234\e[0m";
    is($res, $cres, "truncate long word 3 (broken in v0.08)")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap("x\n\e[1m\nx", 10);
    $cres = "x\n\n\e[1mx";
    is($res, $cres, "color code in parabreak")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap("12345 123", 7, {flindent=>"xx", slindent=>"x"});
    $cres = "xx12345\nx123";
    is($res, $cres, "flindent & slindent opts (no color codes)")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_wrap("\e[1m1\e[0m23\e[31m45 123\e[0m", 7, {flindent=>"xx", slindent=>"x"});
    $cres = "xx\e[1m1\e[0m23\e[31m45\e[0m\n\e[31mx123\e[0m";
    is($res, $cres, "flindent & slindent opts (with color codes)")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    # XXX flindent & slindent deduced
    # XXX pad opt

    $res = ta_wrap("12345 123", 10, {return_stats=>1});
    is_deeply($res, ["12345 123", {max_word_width=>5, min_word_width=>3}],
              "opt return_stats");
};

subtest "ta_trunc" => sub {
    my $t = "\e[31m1\e[32m2\e[33m3\e[0m4";
    is(ta_trunc($t, 5), $t);
    is(ta_trunc($t, 4), $t);
    is(ta_trunc($t, 3), "\e[31m1\e[32m2\e[33m3\e[0m");
    is(ta_trunc($t, 2), "\e[31m1\e[32m2\e[33m\e[0m");
    is(ta_trunc($t, 1), "\e[31m1\e[32m\e[33m\e[0m");
    is(ta_trunc($t, 0), "\e[31m\e[32m\e[33m\e[0m");
};

subtest "ta_pad" => sub {
    my $foo = "\e[31;47mfoo\e[0m";
    is(ta_pad(""    , 10), "          ", "empty");
    is(ta_pad("$foo", 10), "$foo       ");
    is(ta_pad("$foo", 10, "l"), "       $foo");
    is(ta_pad("$foo", 10, "c"), "   $foo    ");
    is(ta_pad("$foo", 10, "r", "x"), "${foo}xxxxxxx");
    is(ta_pad("${foo}12345678", 10), "${foo}12345678");
    is(ta_pad("${foo}12345678", 10, undef, undef, 1), "${foo}1234567");
};

subtest "ta_highlight" => sub {
    is(ta_highlight("\e[1m\e[31m12345\e[32m64567\e[0m", "456", "\e[7m"),
       "\e[1m\e[31m123\e[7m45\e[0m\e[1m\e[31m\e[7m6\e[0m\e[1m\e[31m\e[32m4567\e[0m");
};

subtest "ta_highlight_all" => sub {
    is(ta_highlight_all("\e[1m\e[31m12345\e[32m674567\e[0m", "456", "\e[7m"),
       "\e[1m\e[31m123\e[7m45\e[0m\e[1m\e[31m\e[7m6\e[0m\e[1m\e[31m\e[32m7\e[7m456\e[0m\e[1m\e[31m\e[32m7\e[0m");
};

subtest "ta_add_color_resets" => sub {
    is_deeply([ta_add_color_resets("\e[31mred and \e[1mbold", "beureum", "merah\e[0m normal", "normale")],
              ["\e[31mred and \e[1mbold\e[0m",
               "\e[31m\e[1mbeureum\e[0m",
               "\e[31m\e[1mmerah\e[0m normal",
               "\e[0mnormale"]);
};

subtest "ta_substr" => sub {
    diag dump(ta_substr("\e[31m1234\e[32m5678\e[0m", 2, 4, "foo"));
    is(ta_substr("\e[31m1234\e[32m5678\e[0m", 2, 4), "\e[31m34\e[32m56\e[0m");
    is(ta_substr("\e[31m1234\e[32m5678\e[0m", 2, 4, "foo"), "\e[31m12\e[0mfoo\e[31m\e[32m78\e[0m");
};

DONE_TESTING:
done_testing();
