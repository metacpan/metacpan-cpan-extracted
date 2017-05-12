package WordList::Char::ZH::HSK3;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",0,"num_words_contains_unicode",270,"num_words",270,"shortest_word_len",1,"num_words_contains_nonword_chars",0,"avg_word_len",1,"longest_word_len",1); # STATS

1;
# ABSTRACT: HSK (level 3 only) characters

=pod

=encoding UTF-8

=head1 NAME

WordList::Char::ZH::HSK3 - HSK (level 3 only) characters

=head1 VERSION

This document describes version 0.01 of WordList::Char::ZH::HSK3 (from Perl distribution WordList-ZH-HSK), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::Char::ZH::HSK3;

 my $wl = WordList::Char::ZH::HSK3->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 DESCRIPTION

=head1 STATISTICS

 +----------------------------------+-------+
 | key                              | value |
 +----------------------------------+-------+
 | avg_word_len                     | 1     |
 | longest_word_len                 | 1     |
 | num_words                        | 270   |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 270   |
 | num_words_contains_whitespace    | 0     |
 | shortest_word_len                | 1     |
 +----------------------------------+-------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-ZH-HSK>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-ZH-HSK>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-ZH-HSK>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList::Char::ZH::HSK>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
万
且
世
业
主
久
乎
于
伞
位
信
借
假
健
像
元
其
典
冒
冬
冰
决
净
刚
刮
刷
刻
力
办
加
努
包
化
半
单
南
卡
历
参
又
双
发
叔
变
口
句
只
史
向
周
响
哭
啊
啤
嘴
园
图
地
坏
城
境
声
复
夏
头
奇
如
姨
婚
季
安
定
实
害
容
层
居
山
差
己
市
带
帽
干
平
应
康
张
当
心
必
忘
怕
急
怪
总
惯
感
愿
戏
成
或
才
扫
把
护
担
择
拿
换
据
接
提
搬
放
故
数
文
料
斤
方
旧
易
春
更
末
朵
李
束
板
极
查
树
根
梯
检
楚
楼
段
求
河
法
注
清
渴
满
澡
灯
炼
烧
照
熊
爬
爱
爷
片
牙
物
特
环
理
瓶
甜
用
画
界
留
疼
瘦
皮
盘
目
直
相
短
矮
碗
礼
秋
种
空
突
答
筷
简
算
箱
糕
级
练
终
结
绩
绿
网
者
而
耳
聊
聪
育
胖
脚
脸
腿
自
舒
般
船
节
花
草
蓝
蕉
行
街
衫
衬
被
裙
裤
角
解
议
记
讲
词
该
调
赛
超
越
趣
跟
轻
较
辆
迎
迟
选
遇
邮
邻
酒
重
铁
银
锻
闻
阳
附
除
难
需
静
鞋
音
须
顾
风
饮
饱
饿
香
马
骑
鲜
鸟
黄
鼻
