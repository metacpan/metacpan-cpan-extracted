package WordList::Char::ZH::HSK2;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",1,"num_words_contains_nonword_chars",0,"avg_word_len",1,"longest_word_len",1,"num_words_contains_whitespace",0,"num_words_contains_unicode",172,"num_words",172); # STATS

1;
# ABSTRACT: HSK (level 2 only) characters

=pod

=encoding UTF-8

=head1 NAME

WordList::Char::ZH::HSK2 - HSK (level 2 only) characters

=head1 VERSION

This document describes version 0.01 of WordList::Char::ZH::HSK2 (from Perl distribution WordList-ZH-HSK), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::Char::ZH::HSK2;

 my $wl = WordList::Char::ZH::HSK2->new;

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
 | num_words                        | 172   |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 172   |
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
丈
两
为
乐
也
事
介
从
以
件
休
但
体
便
公
共
准
别
到
务
动
助
千
卖
可
右
司
告
员
咖
哥
唱
啡
因
场
备
外
夫
奶
妹
妻
始
姓
孩
它
完
宜
室
宾
就
左
已
希
帮
常
床
弟
往
得
忙
快
思
息
您
情
意
慢
懂
房
所
手
找
报
教
新
旁
旅
日
早
晚
晴
最
望
条
次
歌
正
步
每
比
汽
泳
洗
游
火
然
牛
玩
班
球
瓜
男
病
白
百
真
眼
着
睛
知
票
离
穿
站
笑
笔
第
等
篮
累
红
纸
绍
经
给
羊
考
肉
舞
色
药
虽
蛋
表
要
让
诉
试
课
贵
走
足
跑
路
跳
踢
身
边
过
运
近
还
进
远
送
道
铅
错
长
门
问
间
阴
雪
零
非
题
颜
馆
鱼
鸡
黑
