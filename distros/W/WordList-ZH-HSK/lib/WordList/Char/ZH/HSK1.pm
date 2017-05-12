package WordList::Char::ZH::HSK1;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words",173,"num_words_contains_unicode",173,"num_words_contains_whitespace",0,"avg_word_len",1,"longest_word_len",1,"num_words_contains_nonword_chars",0,"shortest_word_len",1); # STATS

1;
# ABSTRACT: HSK (level 1 only) characters

=pod

=encoding UTF-8

=head1 NAME

WordList::Char::ZH::HSK1 - HSK (level 1 only) characters

=head1 VERSION

This document describes version 0.01 of WordList::Char::ZH::HSK1 (from Perl distribution WordList-ZH-HSK), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::Char::ZH::HSK1;

 my $wl = WordList::Char::ZH::HSK1->new;

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
 | num_words                        | 173   |
 | num_words_contains_nonword_chars | 0     |
 | num_words_contains_unicode       | 173   |
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
一
七
三
上
下
不
东
个
中
么
九
习
书
买
了
二
五
些
京
亮
人
什
今
他
们
会
住
作
你
候
做
儿
先
八
六
关
兴
再
写
冷
几
出
分
前
北
医
十
午
去
友
叫
号
吃
同
名
后
吗
听
呢
和
哪
商
喂
喜
喝
四
回
国
在
坐
块
多
大
天
太
女
她
好
妈
姐
子
字
学
客
家
对
小
少
岁
工
师
年
店
开
影
很
怎
想
我
打
时
明
星
昨
是
月
有
朋
服
期
本
机
来
杯
果
校
样
桌
椅
欢
气
水
汉
没
漂
点
热
爸
狗
猫
现
生
电
的
看
睡
租
米
系
老
能
脑
苹
茶
菜
衣
西
见
视
觉
认
识
话
语
说
请
读
谁
谢
起
车
这
那
都
里
钟
钱
院
雨
面
飞
饭
高
