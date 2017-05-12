#!perl -T

use 5.010001;
use strict;
use warnings;
use utf8;
use constant NL => "\n";

use POSIX;
use Test::More 0.98;
use Text::WideChar::Util qw(
    mbpad pad mbswidth_height length_height mbwrap wrap mbtrunc trunc);

# check if chinese locale is supported, otherwise bail
unless (POSIX::setlocale(&POSIX::LC_ALL, "zh_CN.utf8")) {
    plan skip_all => "Chinese locale not supported on this system";
}

subtest "mbswidth_height" => sub {
    is_deeply(mbswidth_height(""), [0, 0]);
    is_deeply(mbswidth_height("我不想回家"), [10, 1]);
    is_deeply(mbswidth_height("我不想\n回家"), [6, 2]);
    is_deeply(mbswidth_height("我不\n想回家\n"), [6, 3]);
};

subtest "length_height" => sub {
    is_deeply(length_height(""), [0, 0]);
    is_deeply(length_height("abc"), [3, 1]);
    is_deeply(length_height("abc\nde"), [3, 2]);
    is_deeply(length_height("ab\ncde\n"), [3, 3]);
};

# single paragraph
my $txt1 = <<_;
I dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.
_
#qq--------10--------20--------30--------40--------50
my $txt1w =
qq|I dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep me|.NL.
qq|company.|.NL;

# multiple paragraph
my $txt1b = <<_;
I dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.

I dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.
_
#qq--------10--------20--------30--------40--------50
my $txt1bw =
qq|I dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep me|.NL.
qq|company.|.NL.NL.
qq|I dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep me|.NL.
qq|company.|.NL;

# no terminating newline
my $txt1c = "\x1b[31;47mI\x1b[0m dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep...";
#qq--------10--------20--------30--------40--------50
my $txt1cw =
qq|\x1b[31;47mI\x1b[0m dont wan't to go home. Where do you|.NL.
qq|want to go? I'll keep you company. Mr|.NL.
qq|Goh, I'm fine. You don't have to keep...|;

# containing wide chars
my $txt2 = <<_;
I dont wan't to go home. 我不想回家. Where do you want to go? I'll keep you
company. 那你想去哪里？我陪你. Mr Goh, I'm fine. 吴先生. 我没事. You don't have
to keep me company. 你不用陪我.
_
#qq--------10--------20--------30--------40--------50
my $txt2w =
qq|I dont wan't to go home. 我不想回家.|.NL.
qq|Where do you want to go? I'll keep you|.NL.
qq|company. 那你想去哪里？我陪你. Mr Goh,|.NL.
qq|I'm fine. 吴先生. 我没事. You don't have|.NL.
qq|to keep me company. 你不用陪我.|.NL;

subtest "mbwrap" => sub {
    is(mbwrap($txt1 , 40), $txt1w );
    is(mbwrap($txt1b, 40), $txt1bw);
    is(mbwrap($txt2 , 40), $txt2w );
};

subtest "mbpad" => sub {
    my $foo = "你好吗";
    is(mbpad("",       10),           "          ", "empty");
    is(mbpad("你好吗", 10),           "你好吗    ", "rpad");
    is(mbpad("你好吗", 10, "l"),      "    你好吗", "lpad");
    is(mbpad("你好吗", 10, "c"),      "  你好吗  ", "centerpad");
    is(mbpad("你好吗", 10, "r", "x"), "你好吗xxxx", "padchar");
    is(mbpad("你好吗12345678", 10),   "你好吗12345678", "trunc=0");
    is(mbpad("你好吗12345678", 10, undef, undef, 1), "你好吗1234", "trunc=1");
    is(mbpad("你好吗", 3, undef, undef, 1), "你 ", "trunc=1 repadded");
};

subtest "pad" => sub {
    is(pad("我不想", 5), "我不想  ");
};

subtest "mbtrunc" => sub {
    is(mbtrunc("我不想",  0), "");
    is(mbtrunc("我不想",  1), "");
    is(mbtrunc("我不想",  2), "我");
    is(mbtrunc("我不想",  3), "我");
    is(mbtrunc("我wo"  ,  3), "我w");
    is(mbtrunc("我wo"  ,  4), "我wo");
    is(mbtrunc("我不想",  4), "我不");
    is(mbtrunc("我不想",  5), "我不");
    is(mbtrunc("我不想",  6), "我不想");
    is(mbtrunc("我不想", 10), "我不想");

    # 0.04
    is(mbtrunc("12345", 4), "1234");
};

subtest "trunc" => sub {
    is(trunc("我不想", 2), "我不");
};

DONE_TESTING:
done_testing();
