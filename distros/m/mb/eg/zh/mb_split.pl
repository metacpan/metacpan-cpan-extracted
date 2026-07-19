#!/usr/bin/perl
######################################################################
# eg/zh/mb_split.pl - 用 mb::split 在字符边界上切分
#
# 演示内容:
#   mb::split('', EXPR) 把字符串拆成整个多字节字符;
#   mb::split(PATTERN, EXPR) 按 MBCS 分隔符切分,绝不匹配
#   落在某个多字节字符内部的字节。
#
# 与 CORE 的区别:
#   CORE split(//) 把双字节平假名撕成两个字节;mb::split 把它
#   保留为一个字符。向下兼容到 Perl 5.005_03。
#
# 注:源码与 \xHH 数据保持 US-ASCII;本文件为 UTF-8(仅注释本地化为中文)。
#
#     perl eg/zh/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Shift_JIS 的三个平假名: a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)。
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) 看到字节:这里是六个。
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) 看到字符:三个。
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# 按 MBCS 分隔符切分。分隔符是平假名 a (\x82\xA0);mb::split 把它
# 当作整个字符来匹配,而不是任何位置出现的字节 \x82 或 \xA0。
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# 通过 mb::split 的列表上下文统计字符数(类似 chars() 辅助函数)。
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
