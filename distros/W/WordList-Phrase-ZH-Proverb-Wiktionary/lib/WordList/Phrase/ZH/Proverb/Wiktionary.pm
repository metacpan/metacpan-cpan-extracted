package WordList::Phrase::ZH::Proverb::Wiktionary;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("shortest_word_len",4,"num_words",292,"num_words_contains_whitespace",0,"num_words_contains_nonword_chars",108,"longest_word_len",13,"num_words_contains_unicode",292,"avg_word_len",7.1986301369863); # STATS

1;
# ABSTRACT: Chinese proverbs from wiktionary.org

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::ZH::Proverb::Wiktionary - Chinese proverbs from wiktionary.org

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::ZH::Proverb::Wiktionary (from Perl distribution WordList-Phrase-ZH-Proverb-Wiktionary), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::ZH::Proverb::Wiktionary;

 my $wl = WordList::Phrase::ZH::Proverb::Wiktionary->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+-----------------+
 | key                              | value           |
 +----------------------------------+-----------------+
 | avg_word_len                     | 7.1986301369863 |
 | longest_word_len                 | 13              |
 | num_words                        | 292             |
 | num_words_contains_nonword_chars | 108             |
 | num_words_contains_unicode       | 292             |
 | num_words_contains_whitespace    | 0               |
 | shortest_word_len                | 4               |
 +----------------------------------+-----------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-ZH-Proverb-Wiktionary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-ZH-Proverb-Wiktionary>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-ZH-Proverb-Wiktionary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://en.wiktionary.org/wiki/Category:Chinese_proverbs>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
一人得道，鸡犬升天
一分耕耘，一分收穫
一分耕耘，一分收获
一分錢，一分貨
一分钱，一分货
一山不容二虎
一日为师，终身为父
一日為師，終身為父
一朝被蛇咬，十年怕井繩
一朝被蛇咬，十年怕井绳
一朝被蛇咬，十年怕草繩
一朝被蛇咬，十年怕草绳
一枝草，一点露
一枝草，一點露
一样米养百样人
一樣米養百樣人
一步錯，步步錯
一步错，步步错
一粒老鼠屎，坏了一锅粥
一粒老鼠屎，壞了一鍋粥
一言兴邦
一言興邦
一醉解千愁
一飲一啄，莫非前定
一饮一啄，莫非前定
万事起头难
万恶淫为首
三个臭皮匠，胜过诸葛亮
三個臭皮匠，勝過諸葛亮
三十年河东，三十年河西
三十年河東，三十年河西
三思而后行
三思而後行
三思而行
三日不讀書，面目可憎
三日不读书，面目可憎
上有天堂，下有苏杭
上梁不正下梁歪
上樑不正下樑歪
不以成败论英雄
不入虎穴，焉得虎子
不在其位，不謀其政
不在其位，不谋其政
不孝有三，无后为大
不孝有三，無後為大
不患寡而患不均
不打不成器
不打不成相識
不打不成相识
不打不相識
不打不相识
不是一家人，不进一家门
不是一家人，不進一家門
不是冤家不聚头
不是冤家不聚頭
不知者不罪
不經一事，不長一智
不经一事，不长一智
不自由毋宁死
不自由毋寧死
不見棺材不掉淚
不见棺材不掉泪
与人方便，自己方便
为善不欲人知
举头三尺有神明
习惯成自然
书中自有颜如玉
书中自有黄金屋
书到用时方恨少
乳臭未干
事不过三
亲者痛，仇者快
人多嘴杂
人多嘴雜
人定勝天
人定胜天
人怕出名猪怕壮
人怕出名猪怕肥
人怕出名豬怕壯
人怕出名豬怕肥
人无千日好，花无百日红
人无远虑，必有近忧
人比人，氣死人
人無千日好，花無百日紅
人無遠慮，必有近憂
人生何处不相逢
人生何處不相逢
人算不如天算
人而无信，不知其可
人而無信，不知其可
人逢喜事精神爽
人非圣贤，孰能无过
人非圣贤，谁能无过
人非聖賢，孰能無過
人非聖賢，誰能無過
仇人相见，分外眼红
今日事，今日毕
侯门深似海
光阴似箭
兵来将挡，水来土掩
冰冻三尺，非一日之寒
几家欢乐几家愁
初生之犊不畏虎
割鸡焉用牛刀
劣币驱逐良币
劣幣驅逐良幣
勿以善小而不为
勿以恶小而为之
勿以惡小而為之
十年河东，十年河西
受人之托，忠人之事
古今多少事，都付笑谈中
吃人家的嘴软，拿人家的手软
同是天涯沦落人
名不正，则言不顺
君子一言，快马一鞭
君子之交淡如水
君子報仇，十年不晚
君子报仇，十年不晚
君辱臣死
塞翁失馬，焉知非福
塞翁失马，焉知非福
多行不义必自毙
多行不義必自斃
大事化小，小事化无
大人不計小人過
大人不記小人過
大人不计小人过
大人不记小人过
大难不死，必有后福
大難不死，必有後福
大魚吃小魚
大魚吃小魚，小魚吃蝦米
大鱼吃小鱼
大鱼吃小鱼，小鱼吃虾米
天下兴亡，匹夫有责
天下沒有不散的宴席
天下沒有白吃的午餐
天下没有不散的宴席
天下没有白吃的午餐
天下興亡，匹夫有責
天不從人願
天涯何处无芳草
天涯何處無芳草
天生我才必有用
天生我材必有用
天行健，君子以自強不息
天行健，君子以自强不息
夫妻本是同林鸟
失之东隅，收之桑榆
失敗乃成功之母
失敗是成功之母
失败乃成功之母
失败是成功之母
女人心，海底针
女大不中留
女子无才便是德
女子無才便是德
好酒沉瓮底
好酒沉甕底
好馬不吃回頭草
好马不吃回头草
如人飲水，冷暖自知
如人饮水，冷暖自知
孟母三迁
学而优则仕
學而優則仕
家书抵万金
家家有本难念的经
家書抵萬金
寧為太平犬，不做亂世人
小别胜新婚
屋漏偏逢连夜雨
山不转路转
己立立人，己达达人
幾家歡樂幾家愁
弱肉强食
強龍不壓地頭蛇
强宾不压主
强龙不压地头蛇
当局者迷，旁观者清
得饶人处且饶人
心静自然凉
心靜自然涼
忧道不忧贫
患难见真情
情人眼里出西施
愛人如己
愛才如命
慾速則不達
懒人多屎尿
懶人多屎尿
成者为王，败者为寇
扬汤止沸，不如去薪
挂羊头卖狗肉
授人以鱼不如授人以渔
无信不立
日有所思，夜有所梦
时势造英雄
明枪易躲，暗箭难防
春江水暖鸭先知
書中自有黃金屋
書到用時方恨少
有奶便是娘
有子万事足
有子萬事足
有理走遍天下
有錢能使鬼推磨
朝闻道，夕死可矣
杀鸡焉用牛刀
树倒猢狲散
树欲静而风不止
樹欲靜而風不止
欲加之罪，何患无词
欲加之罪，何患无辞
欲加之罪，何患無辭
欲速则不达
欲速則不達
死有重于泰山，轻于鸿毛
水涨船高
水漲船高
水能載舟，亦能覆舟
水能载舟，亦能覆舟
浪子回头金不换
清官难断家务事
爱之欲其生，恶之欲其死
爱人如己
爱才如命
牛仔不八虎
牛仔呣捌虎
牡丹花下死，做鬼也风流
物以类聚
生不带来，死不带去
男儿有泪不轻弹
男儿膝下有黄金
男女授受不亲
留得青山在，不怕没柴烧
病从口入，祸从口出
病急乱投医
病来如山倒，病去如抽丝
百闻不如一见
皇天不负苦心人
皇帝不急，急死太监
知之为知之，不知为不知
知之為知之，不知為不知
知耻近乎勇
礼之用，和为贵
礼轻情意重
祸不单行
秀才不出门，能知天下事
纸包不住火
聊胜于无
聪明一世，糊涂一时
聪明反被聪明误
自古皆有死，人无信不立
自古皆有死，民无信不立
自古红颜多薄命
船到桥头自然直
良禽择木
良禽择木而栖
花开堪折直须折
苛政猛于虎
英雄所见略同
英雄难过美人关
莫待无花空折枝
虎父无犬子
血浓于水
血濃於水
覆水难收
見面三分情
见面三分情
话不投机半句多
话不说不明
说曹操，曹操到
请神容易送神难
读万卷书，行万里路
货比三家不吃亏
这山望着那山高
退一步海阔天空
送君千里，终须一别
道不同，不相为谋
重赏之下必有勇夫
闻名不如见面
防人之心不可无
隔墙有耳
青出于蓝
预防重于治疗
饥不择食
饱暖思淫欲
鱼与熊掌不可兼得
鸟尽弓藏
鹬蚌相争，渔人得利
