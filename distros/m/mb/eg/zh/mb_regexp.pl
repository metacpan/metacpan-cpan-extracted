#!/usr/bin/perl
######################################################################
# eg/zh/mb_regexp.pl - 用 mb::qr 进行可识别多字节的匹配
#
# 演示内容:
#   mb::qr(PATTERN) 编译的正则,其 "."、字符类和捕获在所选脚本
#   编码下都以整个多字节字符为单位工作。
#
# 与 CORE 的区别:
#   CORE 的 "." 匹配一个字节,故 /(.)/g 对三个平假名得到 6 段;
#   经 mb::qr 得到 3 段(每字符一段)。字符类范围与捕获都返回
#   整个字符。
#
# 注:源码与 \xHH 数据保持 US-ASCII;本文件为 UTF-8(仅注释本地化为中文)。
#
#     perl eg/zh/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS 的三个平假名: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)。
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE 的 "." 是一个字节 —— 六个字节得到六段。
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") 让 "." 成为一个整字符 —— 三段。编译一次,再把
# 编译好的模式插入匹配中。
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# 对平假名区段 a..n (\x82\xA0-\x82\xF1) 做字符类范围。该范围比较整
# 个字符,故 u 在其中而 ASCII "A" 不在。
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# 捕获返回一个整的多字节字符(这里是两个字节),绝不是半个。
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# 在混合字符串中以字符为单位找出每个平假名。
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
