#!/usr/bin/perl
######################################################################
# eg/zh/mb_length.pl - 用 mb 数字符数与字节数的区别
#
# 演示内容:
#   CORE 的 length() 数字节;mb::length() 按所选脚本编码把整个
#   多字节字符数为 1。mb::substr() 与 mb::index() 也以字符为单位,
#   双字节字符绝不会被从中间截断。
#
# 与 CORE 的区别:
#   length 对双字节平假名得到 2(字节),而 mb::length 得到 1
#   (一个 Shift_JIS 平假名字符)。
#
# 注:源码与 \xHH 数据保持 US-ASCII;本文件为 UTF-8(仅注释本地化为中文)。
#
#     perl eg/zh/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS 的三个平假名,共 6 字节:
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE 的 length() 数字节;mb::length() 数字符。
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() 以字符为单位切取,双字节字符不会被切成两半。
# 前 2 个字符恰好是 4 字节的字符串。
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() 返回字符位置而非字节位置。第 3 个字符从第 4
# 字节开始,但字符索引为 2。
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
