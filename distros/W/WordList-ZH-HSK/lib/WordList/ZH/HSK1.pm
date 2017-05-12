package WordList::ZH::HSK1;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",0,"num_words_contains_unicode",149,"num_words",149,"shortest_word_len",1,"longest_word_len",3,"avg_word_len",1.50335570469799,"num_words_contains_nonword_chars",0); # STATS

1;
# ABSTRACT: HSK (level 1 only) words

=pod

=encoding UTF-8

=head1 NAME

WordList::ZH::HSK1 - HSK (level 1 only) words

=head1 VERSION

This document describes version 0.01 of WordList::ZH::HSK1 (from Perl distribution WordList-ZH-HSK), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::ZH::HSK1;

 my $wl = WordList::ZH::HSK1->new;

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
 | avg_word_len                     | 1.50335570469799 |
 | longest_word_len                 | 3                |
 | num_words                        | 149              |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 149              |
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
一
一点儿
七
三
上
上午
下
下午
下雨
不
不客气
东西
个
中午
中国
九
书
买
了
二
五
些
人
什么
今天
他
会
住
你
做
儿子
先生
八
六
再见
写
冷
几
出租车
分钟
前面
北京
医生
医院
十
去
叫
号
吃
同学
名字
后面
吗
听
呢
和
哪
哪儿
商店
喂
喜欢
喝
四
回
在
坐
块
多
多少
大
天气
太
女儿
她
好
妈妈
字
学习
学校
学生
家
对不起
小
小姐
少
岁
工作
年
开
很
怎么
怎么样
想
我
我们
打电话
时候
明天
星期
昨天
是
月
有
朋友
本
来
杯子
桌子
椅子
水
水果
汉语
没关系
没有
漂亮
点
热
爸爸
狗
猫
现在
电影
电脑
电视
的
看
看见
睡觉
米饭
老师
能
苹果
茶
菜
衣服
认识
说
请
读
谁
谢谢
这
那
都
里
钱
飞机
饭店
高兴
