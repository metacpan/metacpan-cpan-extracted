#!perl

use 5.010001;
use strict;
use warnings;
use utf8;
use constant NL => "\n";

use Data::Dump qw(dump);
use POSIX;
use Test::More 0.98;
use Text::ANSI::WideUtil qw(
                               ta_mbpad ta_mbswidth ta_mbswidth_height ta_mbtrunc
                               ta_mbwrap);

# check if chinese locale is supported, otherwise bail
unless (POSIX::setlocale(&POSIX::LC_ALL, "zh_CN.utf8")) {
    plan skip_all => "Chinese locale not supported on this system";
}

subtest "ta_mbswidth_height" => sub {
    is_deeply(ta_mbswidth_height(""), [0, 0]);
    is_deeply(ta_mbswidth_height("\e[0m"), [0, 0]);
    is_deeply(ta_mbswidth_height(" "), [1, 1]);
    is_deeply(ta_mbswidth_height(" \n"), [1, 2]);
    is_deeply(ta_mbswidth_height("\e[31;47m你好吗\e[0m\nhello\n"), [6, 3]);
};

subtest "ta_mbswidth" => sub {
    is_deeply(ta_mbswidth(""), 0);
    is_deeply(ta_mbswidth("\e[0m"), 0);
    is_deeply(ta_mbswidth(" "), 1);
    is_deeply(ta_mbswidth(" \n"), 1);
    is_deeply(ta_mbswidth("\e[31;47m你好吗\e[0m\nhello\n"), 6);
};

my $txt2 = <<_;
\e[31;47mI\e[0m dont wan't to go home. 我不想回家. Where do you want to go? I'll keep you
company. 那你想去哪里？我陪你. Mr Goh, I'm fine. 吴先生. 我没事. You don't have
to keep me company. 你不用陪我.
_
#qq--------10--------20--------30--------40--------50
my $txt2w =
qq|\e[31;47mI\e[0m dont wan't to go home. 我不想回家.|.NL.
qq|Where do you want to go? I'll keep you|.NL.
qq|company. 那你想去哪里？我陪你. Mr Goh,|.NL.
qq|I'm fine. 吴先生. 我没事. You don't have|.NL.
qq|to keep me company. 你不用陪我.|.NL;
subtest "ta_mbwrap" => sub {
    my ($res, $cres);

    $res  = ta_mbwrap($txt2, 40);;
    $cres = $txt2w;
    is($res, $cres)
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_mbwrap("\e[31m啊啊啊啊啊啊啊啊啊啊啊啊啊\e[0m", 11);
    $cres = join("",
                 "\e[31m啊啊啊啊啊\e[0m\n",
                 "\e[31m啊啊啊啊啊\e[0m\n",
                 "\e[31m啊啊啊\e[0m",
             );
    is($res, $cres, "long CJK word")
        or diag dump([split /^/, $cres], [split /^/, $res]);

    $res  = ta_mbwrap("aku mau \e[31m吃饭吃饭吃饭吃饭\e[0m kuingat kamu", 15);
    $cres = join("",
                 "aku mau\e[31m 吃饭吃\e[0m\n",
                 "\e[31m饭吃饭吃饭\e[0m\n",
                 "kuingat kamu",
             );
    is($res, $cres, "chinese")
        or diag dump([split /^/, $cres], [split /^/, $res]);
};

subtest "ta_mbtrunc" => sub {
    my $t = "\e[31m不\e[32m用\e[33m陪\e[0m我";
    is(ta_mbtrunc($t, 9), $t);
    is(ta_mbtrunc($t, 8), $t);
    is(ta_mbtrunc($t, 7), "\e[31m不\e[32m用\e[33m陪\e[0m");
    is(ta_mbtrunc($t, 6), "\e[31m不\e[32m用\e[33m陪\e[0m");
    is(ta_mbtrunc($t, 5), "\e[31m不\e[32m用\e[33m\e[0m");
    is(ta_mbtrunc($t, 4), "\e[31m不\e[32m用\e[33m\e[0m");
    is(ta_mbtrunc($t, 3), "\e[31m不\e[32m\e[33m\e[0m");
    is(ta_mbtrunc($t, 2), "\e[31m不\e[32m\e[33m\e[0m");
    is(ta_mbtrunc($t, 1), "\e[31m\e[32m\e[33m\e[0m");
    is(ta_mbtrunc($t, 0), "\e[31m\e[32m\e[33m\e[0m");
};

subtest "ta_mbpad" => sub {
    my $foo = "\e[31;47m你好吗\e[0m";
    is(ta_mbpad(""    , 10), "          ", "empty");
    is(ta_mbpad("$foo", 10), "$foo    ");
    is(ta_mbpad("$foo", 10, "l"), "    $foo");
    is(ta_mbpad("$foo", 10, "c"), "  $foo  ");
    is(ta_mbpad("$foo", 10, "r", "x"), "${foo}xxxx");
    is(ta_mbpad("${foo}12345678", 10), "${foo}12345678");
    is(ta_mbpad("${foo}12345678", 10, undef, undef, 1), "${foo}1234");
    is(ta_mbpad("$foo", 3, undef, undef, 1), "\e[31;47m你\e[0m ",
       "repad truncated");
};

DONE_TESTING:
done_testing;
