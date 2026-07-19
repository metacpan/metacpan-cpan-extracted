#!/usr/bin/perl
######################################################################
# eg/zh/mb_practical.pl - 按固定列宽裁剪而不破坏字符
#
# 演示内容(一个小的实际任务):
#   把一行 Shift_JIS 裁剪到固定显示宽度:半角字符算 1 列,全角
#   字符算 2 列(经典 1:2 比例),且绝不在边界处切断双字节字符。
#
# 与 CORE 的区别:
#   幼稚的 CORE substr 在第 N 字节处裁剪,可能留下半个字符。这里
#   用 mb::split('') 逐个整字符前进,按字节长度度量宽度,在超出
#   预算前停止。mb::length() 确认结果是整数个字符。
#
# 注:源码与 \xHH 数据保持 US-ASCII;本文件为 UTF-8(仅注释本地化为中文)。
#
#     perl eg/zh/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C,然后三个全角平假名 a i u,再两个半角片假名。
#   ASCII A B C            : 1 column each
#   full-width a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 columns each
#   half-width ka(\xB6) ki(\xB7)                   : 1 column each
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # 裁剪到 7 个显示列

# 字符边界安全、感知宽度的裁剪。
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 字节 -> 1 列,2 字节 -> 2 列
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC(3 列)+ a(2)+ i(2)= 7 列;u 会溢出而被丢弃,故末尾的
# 双字节字符保持完整。
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# 在纯双字节数据上对比:按固定字节数裁剪可能落在字符内部。平假名
# a i u 全是双字节,所以奇数字节长度意味着裁剪切断了字符;mb::substr
# 始终停在字符边界(这里是偶数字节长度)。
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + 一个悬空的前导字节
$char_cut  = mb::substr($aiu, 0, 1);    # 恰好是 a
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
