#!perl -T

use 5.010001;
use strict;
use warnings;
use utf8;
use constant NL => "\n";

use POSIX;
use Test::More 0.98;
use Text::WideChar::Util qw(wrap mbwrap);

# XXX test flindent opt is wider than width
# XXX test flindent from text is wider than width

{
    my $u = <<_;
I dont wan't to go home. Where do you want to go? I'll keep you company. Mr Goh,
I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    my $w = <<_;
I dont wan't to go home. Where do you
want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me
company.
_
    is(wrap($u, 40), $w, "single paragraph");
}

{
    my $u = <<_;
I dont wan't to go home.
Where do you want to go?
I'll keep you company.
Mr Goh, I'm fine. You
don't have to keep me
company.
_
#--------1---------2---------3---------4
    my $w = <<_;
I dont wan't to go home. Where do you
want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me
company.
_
    is(wrap($u, 40), $w, "reflow");
}

{
    my $u = "I dont wan't to go home.
Where do you want to go?
I'll keep you company.
Mr Goh, I'm fine. You
don't have to keep me
company.";
#--------1---------2---------3---------4
    my $w = "I dont wan't to go home. Where do you
want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me
company.";
    is(wrap($u, 40), $w, "trailing newline state is preserved (no newline)");
}

subtest "paragraph break characters are maintained" => sub {
    is(wrap("a\n\nb", 40), "a\n\nb", "\\n\\n");
    is(wrap("a\n\n\nb", 40), "a\n\n\nb", "\\n\\n\\n");
    is(wrap("a\n \nb", 40), "a\n \nb", "\\n \\n");
    is(wrap("a\n\n\nb\n\n", 40), "a\n\n\nb\n\n", "\\n\\n at the end");
};

subtest "flindent & slindent deduced from text" => sub {
    my $u = <<_;
  I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    my $w = <<_;
  I dont wan't to go home. Where do you
want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me
company.
_
    is(wrap($u, 40), $w, "flindent");

    $u = <<_;
  I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
    Goh, I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    $w = <<_;
  I dont wan't to go home. Where do you
    want to go? I'll keep you company.
    Mr Goh, I'm fine. You don't have to
    keep me company.
_
    is(wrap($u, 40), $w, "flindent + slindent");

#--------1---------2---------3---------4
    $u = <<_;
I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
    Goh, I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    $w = <<_;
I dont wan't to go home. Where do you
    want to go? I'll keep you company.
    Mr Goh, I'm fine. You don't have to
    keep me company.
_
    is(wrap($u, 40), $w, "slindent");

    $u = <<_;
  I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
    Goh, I'm fine. You don't have to keep me company.

    I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    $w = <<_;
  I dont wan't to go home. Where do you
    want to go? I'll keep you company.
    Mr Goh, I'm fine. You don't have to
    keep me company.

    I dont wan't to go home. Where do
you want to go? I'll keep you company.
Mr Goh, I'm fine. You don't have to keep
me company.
_
    is(wrap($u, 40), $w, "flindent + slindent is reset every para");
};

subtest "flindent & slindent option" => sub {
    my $u = <<_;
I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    my $w = <<_;
  I dont wan't to go home. Where do you
 want to go? I'll keep you company. Mr
 Goh, I'm fine. You don't have to keep
 me company.
_
    is(wrap($u, 40, {flindent=>'  ', slindent=>' '}), $w,
       "flindent + slindent");

    $u = <<_;
I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
Goh, I'm fine. You don't have to keep me company.

  I dont wan't to go home. Where do you want to go? I'll keep you company. Mr
    Goh, I'm fine. You don't have to keep me company.
_
#--------1---------2---------3---------4
    $w = <<_;
  I dont wan't to go home. Where do you
 want to go? I'll keep you company. Mr
 Goh, I'm fine. You don't have to keep
 me company.

  I dont wan't to go home. Where do you
 want to go? I'll keep you company. Mr
 Goh, I'm fine. You don't have to keep
 me company.
_
    is(wrap($u, 40, {flindent=>'  ', slindent=>' '}), $w,
       "flindent + slindent is the same at every para");
};

subtest "tab_width option (flindent)" => sub {
# --------1---------2
    my $u0 = "I don't want to go home.\n";
    is(wrap($u0, 20, {flindent=>"\t"}), "\tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>" \t"}), " \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"  \t"}), "  \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"   \t"}), "   \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"    \t"}), "    \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"     \t"}), "     \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"      \t"}), "      \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"       \t"}), "       \tI don't want\nto go home.\n");
    is(wrap($u0, 20, {flindent=>"        \t"}), "        \tI\ndon't want to go\nhome.\n");
};

# TODO: tab_width option (slindent)

subtest "chop long word" => sub {
    is(wrap("1234567890",  5), "12345\n67890");
    is(wrap("12345678901", 5), "12345\n67890\n1");
    is(wrap("  12345678901", 5), "  \n12345\n67890\n1");
    is(wrap("  12345678901", 5, {slindent=>" "}), "  \n 1234\n 5678\n 901");
};

subtest "chop long word (mb)" => sub {
    is(mbwrap("1234567890",  5), "12345\n67890");
    is(mbwrap("12345678901", 5), "12345\n67890\n1");
    is(mbwrap("  12345678901", 5), "  \n12345\n67890\n1");
    is(mbwrap("  12345678901", 5, {slindent=>" "}), "  \n 1234\n 5678\n 901");
};

subtest "opt return_stats" => sub {
    is_deeply(wrap("12345 123", 10, {return_stats=>1}),
              ["12345 123", {max_word_width=>5, min_word_width=>3}],
              "opt return_stats");
};

subtest "chinese text" => sub {
    my $input = <<'_';
存储和信息管理公司Iron Mountain位于阿根廷首都布宜诺斯艾利斯的一个大数据中心周三遭大火烧毁，九名消防员在救火中丧生，2人失踪，7人受伤。数据中心储存了阿根廷央行和企业档案，因此损失可能非常巨大。这个数据中心配备了私人的救火队，自动喷水灭火系统，火灾控制系统以及其它火灾预防的措施。但即便如此，仍然没有预防灾难的发生。目前还不清楚数据中心起火的原因。
_
    my $res = <<'_';
存储和信息管理公司
Iron Mountain位于阿
根廷首都布宜诺斯艾利
斯的一个大数据中心周
三遭大火烧毁，九名消
防员在救火中丧生，2
人失踪，7人受伤。数
据中心储存了阿根廷央
行和企业档案，因此损
失可能非常巨大。这个
数据中心配备了私人的
救火队，自动喷水灭火
系统，火灾控制系统以
及其它火灾预防的措施
。但即便如此，仍然没
有预防灾难的发生。目
前还不清楚数据中心起
火的原因。
_
    is(mbwrap($input, 20), $res);
};

subtest "long cjk word is not truncated before line-broken" => sub {
    my $input = <<'_';
aku mau 吃饭吃饭吃饭吃饭 kuingat kamu.
_
    my $res = <<'_';
aku mau 吃饭吃
饭吃饭吃饭
kuingat kamu.
_
    is(mbwrap($input, 15), $res);
};

DONE_TESTING:
done_testing();
