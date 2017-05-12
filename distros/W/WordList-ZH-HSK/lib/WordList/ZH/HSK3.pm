package WordList::ZH::HSK3;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",0,"num_words",302,"num_words_contains_unicode",302,"shortest_word_len",1,"num_words_contains_nonword_chars",0,"avg_word_len",1.72847682119205,"longest_word_len",4); # STATS

1;
# ABSTRACT: HSK (level 3 only) words

=pod

=encoding UTF-8

=head1 NAME

WordList::ZH::HSK3 - HSK (level 3 only) words

=head1 VERSION

This document describes version 0.01 of WordList::ZH::HSK3 (from Perl distribution WordList-ZH-HSK), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::ZH::HSK3;

 my $wl = WordList::ZH::HSK3->new;

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
 | avg_word_len                     | 1.72847682119205 |
 | longest_word_len                 | 4                |
 | num_words                        | 302              |
 | num_words_contains_nonword_chars | 0                |
 | num_words_contains_unicode       | 302              |
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
一会儿
一共
一定
一样
一直
一般
一边
万
上网
不但
世界
东
个子
中文
中间
为
为了
主要
久
习惯
了解
以前
会议
伞
位
体育
作业
信用卡
借
健康
像
元
先
公园
公斤
关
关于
关心
关系
其他
其实
冬
冰箱
决定
几乎
分
刚才
别人
刮风
刷牙
刻
办公室
办法
动物
努力
包
北方
半
南
历史
参加
又
双
发
发烧
发现
叔叔
变化
口
句子
只
只
只有
可爱
司机
同事
同意
后来
向
周末
哭
啊
啤酒
嘴
回答
国家
图书馆
地
地图
地方
地铁
坏
城市
声音
复习
夏
多么
太阳
头发
奇怪
奶奶
如果
姨
季节
安静
完成
客人
害怕
容易
小心
层
差
带
帮忙
帽子
干净
年级
年轻
应该
张
当然
影响
必须
忘记
总是
感兴趣
感冒
愿意
成绩
或者
才
打扫
打算
把
护照
担心
拿
换
接
提高
搬
放
放心
故事
教
数学
文化
新闻
新鲜
方便
旧
明白
春
更
最后
最近
月亮
有名
机会
条
极
树
校长
根据
检查
楼
欢迎
段
比赛
比较
水平
注意
洗手间
洗澡
清楚
渴
游戏
满意
灯
热情
然后
照片
照相机
照顾
熊猫
爬山
爱好
爷爷
特别
环境
班
瓶子
甜
生气
用
电子邮件
电梯
画
留学
疼
瘦
皮鞋
盘子
相信
着急
短
矮
碗
礼物
离开
秋
种
空调
突然
站
笔记本
筷子
简单
米
练习
终于
经常
经理
经过
结婚
结束
绿
老
而且
耳朵
聊天
聪明
胖
脚
脸
腿
自己
自行车
舒服
船
节日
节目
花
花
草
菜单
蓝
蛋糕
行李箱
街道
衬衫
被
裙子
裤子
西
要求
见面
角
解决
认为
认真
记得
讲
词典
试
请假
起来
起飞
超市
越
跟
辆
过
过去
还
还是
迟到
选择
遇到
邻居
重要
银行
锻炼
长
附近
除了
难
难过
需要
面包
音乐
饮料
饱
饿
香蕉
马
马上
骑
鸟
黄河
黑板
鼻子
