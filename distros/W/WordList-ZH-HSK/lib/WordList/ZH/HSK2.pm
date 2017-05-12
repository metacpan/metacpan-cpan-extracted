package WordList::ZH::HSK2;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("avg_word_len",1.56953642384106,"longest_word_len",4,"num_words_contains_nonword_chars",0,"shortest_word_len",1,"num_words_contains_unicode",151,"num_words",151,"num_words_contains_whitespace",0); # STATS

1;
# ABSTRACT: HSK (level 2 only) words

=pod

=encoding UTF-8

=head1 NAME

WordList::ZH::HSK2 - HSK (level 2 only) words

=head1 VERSION

This document describes version 0.01 of WordList::ZH::HSK2 (from Perl distribution WordList-ZH-HSK), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::ZH::HSK2;

 my $wl = WordList::ZH::HSK2->new;

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

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 1.56953642384106 |
 | longest_word_len                 | 4                |
 | num_words                        | 151              |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 151              |
 | num_words_contains_whitespace    | 0                |
 | shortest_word_len                | 1                |
 +----------------------------------+------------------+

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

L<WordList::ZH::HSK>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
一下
一起
丈夫
上班
两
为什么
也
事情
介绍
从
件
休息
但是
便宜
公共汽车
公司
再
准备
出
别
到
千
卖
去年
可以
可能
右边
告诉
咖啡
哥哥
唱歌
因为
外
大家
女
好吃
妹妹
妻子
姐姐
姓
孩子
它
完
宾馆
对
对
小时
就
左边
已经
希望
帮助
开始
弟弟
往
得
忙
快
快乐
您
意思
慢
懂
房间
所以
手机
手表
打篮球
找
报纸
教室
新
旁边
旅游
日
早上
时间
晚上
晴
最
服务员
机场
次
正在
每
比
洗
游泳
火车站
牛奶
玩
生日
生病
男
白
百
真
眼睛
着
知道
票
离
穿
笑
第一
等
累
红
给
羊肉
考试
药
虽然
西瓜
要
觉得
让
说话
课
贵
走
起床
跑步
路
跳舞
踢足球
身体
过
运动
近
还
进
远
送
铅笔
错
长
门
问
问题
阴
雪
零
非常
面条
题
颜色
高
鱼
鸡蛋
黑
