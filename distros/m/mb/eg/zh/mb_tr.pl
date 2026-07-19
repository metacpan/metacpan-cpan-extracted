#!/usr/bin/perl
######################################################################
# eg/zh/mb_tr.pl - 用 mb::tr 做以字符为单位的转写
#
# 演示内容:
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) 转写整个多字节字符。
#   不带 /r 时就地修改第一个参数并返回计数;带 /r 时返回结果
#   而保持参数不变。
#
# 与 CORE 的区别:
#   CORE tr/// 逐字节处理,可能损坏 DAMEMOJI —— 第二字节为 ASCII
#   元字符的双字节字符(如 So \x83\x5C,末字节 \x5C 是反斜杠)。
#   mb::tr 把 So 视为一个字符,原样保留。
#
# 注:mb::tr 中连字符范围(a-z)只对 US-ASCII 端点展开;SEARCH 中
# 的多字节字符必须逐个列出。
#
# 注:源码与 \xHH 数据保持 US-ASCII;本文件为 UTF-8(仅注释本地化为中文)。
#
#     perl eg/zh/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# Full-width digits in Shift_JIS: 0(\x82\x4F) .. 9(\x82\x58).
# SEARCH 把全部十个全角数字列为整字符;REPLACE 是 US-ASCII
# 范围 "0-9"(一个 ASCII 连字符范围,由 mb::tr 展开)。
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# 全角 "1" "3" "6" -> 半角 "136"。
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# DAMEMOJI 安全。字符串是 A So(\x83\x5C) B。针对反斜杠字节 \x5C 的
# CORE tr 会损坏该字符;mb::tr 只映射 ASCII 字母,原样保留 So。
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr 命中了 So 的尾字节
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# /r 修饰符:非破坏性,返回转写后的副本。
$keep = "\x82\x50\x82\x51";                 # 全角 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
