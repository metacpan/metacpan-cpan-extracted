package Text::Util::Chinese;
use strict;
use warnings;
use utf8;

use Exporter 5.57 'import';
use Unicode::UCD qw(charscript);

our $VERSION = '0.08';
our @EXPORT_OK = qw(sentence_iterator phrase_iterator presuf_iterator word_iterator extract_presuf extract_words tokenize_by_script looks_like_simplified_chinese);

my $RE_simplified_chinese_characters = qr/[厂几儿亏与万亿个勺么广门义尸卫飞习马乡丰开无专扎艺厅区历车冈贝见气长仆币仅从仓风匀乌凤为忆订计认队办劝书击扑节术厉龙灭轧东业旧帅归叶电号叹们仪丛乐处鸟务饥闪兰汇头汉宁讨写让礼训议讯记辽边发圣对纠丝动执巩扩扫扬场亚朴机权过协压厌页夺达夹轨迈毕贞师尘当吓虫团吗屿岁岂刚则网迁乔伟传优伤价华伪会杀众爷伞创肌杂负壮冲庄庆刘齐产决闭问闯并关汤兴讲军许论农讽设访寻迅尽导异孙阵阳阶阴妇妈戏观欢买红纤级约纪驰寿麦进远违运抚坛坏扰坝贡抢坟坊护壳块声报苍严芦劳苏极杨两丽医辰励还歼来连坚时吴县园旷围吨邮员听呜岗帐财针钉乱体伶彻余邻肠龟犹条饭饮冻状亩况库疗应这弃冶闲间闷灶灿沃沟怀忧穷灾证启评补识诉诊词译灵层迟张际陆陈劲鸡驱纯纱纳纲驳纵纷纸纹纺驴纽环责现规拢拣担顶拥势拦拨择苹茎柜枪构杰丧画枣卖矿码厕奋态欧垄轰顷转斩轮软齿虏肾贤国畅鸣咏罗帜岭凯败贩购图钓侦侧凭侨货质径贪贫肤肿胀胁鱼备饰饱饲变庙剂废净闸闹郑单炉浅泪泻泼泽怜学宝审帘实试诗诚衬视话诞询该详肃录隶届陕限驾参艰线练组细驶织终驻驼绍经贯帮挂项挠赵挡垫挤挥荐带茧荡荣药标栋栏树咸砖砌牵残轻鸦战点临览竖削尝显哑贵虾蚁蚂虽骂哗响峡罚贱钞钟钢钥钩选适种复俩贷顺俭须剑胆胜脉狭狮独狱贸饶蚀饺饼弯将奖疮疯亲闻阀阁养类逆总炼烂洁洒浇浊测济浑浓恼举觉宪窃语袄误诱说诵垦昼险娇贺垒绑绒结绕骄绘给络骆绝绞统艳蚕顽捞载赶盐损捡换热恐壶莲获恶档桥础顾轿较顿毙虑监紧党晒晓晕唤罢圆贼贿钱钳钻铁铃铅牺敌积称笔笋债倾舰舱爱颂胳脏胶脑皱饿恋桨浆离资阅烦烧烛递涛涝润涨烫涌宽宾请诸读袜课谁调谅谈谊剥恳剧难预绢验继掠职萝营梦检聋袭辅辆虚悬崭铜铲银笼偿衔盘鸽领脸猎馅馆痒盖断兽渐渔渗惭惊惨惯窑谋谎祸谜弹隐婶颈绩绪续骑绳维绵绸绿趋搁搂搅联确暂辈辉赏喷践遗赌赔铸铺链销锁锄锅锈锋锐筐筑筛储惩释腊鲁馋蛮阔粪湿湾愤窜窝裤谢谣谦属屡缎缓编骗缘摄摆摊鹊蓝献楼赖雾输龄鉴错锡锣锤锦键锯矮辞筹签简腾触酱粮数满滤滥滚滨滩誉谨缝缠墙愿颗蜡蝇赚锹锻稳箩馒赛谱骡缩嘱镇颜额聪樱飘瞒题颠赠镜赞篮辩懒缴辫骤镰仑讥邓卢叽尔冯迂吁吆伦凫妆汛讳讶讹讼诀驮驯纫玛韧抠抡坞拟芜苇杈轩卤呕呛岖佃狈鸠庐闰兑沥沦汹沧沪诅诈坠纬坯枢枫矾殴昙咙账贬贮侠侥刽觅庞疟泞宠诡屉弥叁绅驹绊绎贰挟荚荞荠荤荧栈砚鸥轴勋哟钙钝钠钦钧钮氢胧饵峦飒闺闽娄烁炫洼诫诬诲逊陨骇挚捣聂荸莱莹莺栖桦桩贾砾唠鸯赃钾铆秫赁耸颁脐脓鸵鸳馁斋涡涣涤涧涩悯窍诺诽谆骏琐麸掷掸掺萤萧萨酝硕颅晤啰啸逻铐铛铝铡铣铭矫秸秽躯敛阎阐焕鸿渊谍谐裆袱祷谒谓谚颇绰绷综绽缀琼揽搀蒋韩颊雳翘凿喳晾畴鹃赋赎赐锉锌牍惫痪滞溃溅谤缅缆缔缕骚鹉榄辐辑频跷锚锥锨锭锰颓腻鹏雏馍馏禀痹誊寝褂裸谬缤赘蔫蔼碱辕辖蝉镀箫舆谭缨撵镊镐篓鲤瘪瘫澜谴鹤缭辙鹦篱鲸濒缰赡镣鳄嚣鳍癞攒鬓躏镶]/;

sub exhaust {
    my ($iter, $cb) = @_;
    my @list;
    while(defined(my $x = $iter->())) {
        push @list, $x;
        $cb->($x) if defined($cb);
    }
    return @list;
}

sub grep_iterator {
    my ($iter, $cb) = @_;
    return sub {
        local $_;
        do {
            $_ = $iter->();
            return undef unless defined($_);
        } while (! $cb->());
        return $_;
    }
}

sub phrase_iterator {
    my ($input_iter, $opts) = @_;
    my @phrases;
    return sub {
        while(! @phrases && defined(my $text = $input_iter->())) {
            @phrases = grep {
                (! /\A\s+\z/) && (! /\p{General_Category=Punctuation}/) && /\p{Han}/
            } split / ( \r?\n | \p{General_Category: Other_Punctuation} )+ /x, $text;
        }
        return shift @phrases;
    }
}

sub sentence_iterator {
    my ($input_iter, $opts) = @_;
    my @sentences;
    return sub {
        while(! @sentences && defined(my $text = $input_iter->())) {
            @sentences = grep { !/\A\s+\z/ } ($text =~
                          m/(
                               (?:
                                   [^\p{General_Category: Open_Punctuation}\p{General_Category: Close_Punctuation}]+?
                               | .*? \p{General_Category: Open_Punctuation} .*? \p{General_Category: Close_Punctuation} .*?
                               )
                               (?: \z | [\n\?\!。？！]+ )
                           )/gx);
        }
        return shift @sentences;
    }
}

sub presuf_iterator {
    my ($input_iter, $opts) = @_;

    my %stats;
    my $threshold = $opts->{threshold} || 9; # an arbitrary choice.
    my $lengths   = $opts->{lengths} || [2,3];

    my $phrase_iter = grep_iterator(
        phrase_iterator( $input_iter ),
        sub { /\A\p{Han}+\z/ }
    );

    my (%extracted, @extracted);
    return sub {
        if (@extracted) {
            return shift @extracted;
        }

        while (!@extracted && defined(my $phrase = $phrase_iter->())) {
            for my $len ( @$lengths ) {
                my $re = '\p{Han}{' . $len . '}';
                next unless length($phrase) >= $len * 2 && $phrase =~ /\A($re) .* ($re)\z/x;
                my ($prefix, $suffix) = ($1, $2);
                $stats{prefix}{$prefix}++ unless $extracted{$prefix};
                $stats{suffix}{$suffix}++ unless $extracted{$suffix};

                for my $x ($prefix, $suffix) {
                    if (! $extracted{$x}
                        && $stats{prefix}{$x}
                        && $stats{suffix}{$x}
                        && $stats{prefix}{$x} > $threshold
                        && $stats{suffix}{$x} > $threshold
                    ) {
                        $extracted{$x} = 1;
                        delete $stats{prefix}{$x};
                        delete $stats{suffix}{$x};

                        push @extracted, $x;
                    }
                }
            }
        }

        if (@extracted) {
            return shift @extracted;
        }

        return undef;
    };
}

sub extract_presuf {
    my ($input_iter, $opts) = @_;
    return [ exhaust(presuf_iterator($input_iter, $opts)) ];
}

sub word_iterator {
    my ($input_iter) = @_;

    my $threshold = 5;
    my (%lcontext, %rcontext, %word, @words);

    my $phrase_iter = grep_iterator(
        phrase_iterator( $input_iter ),
        sub { /\A\p{Han}+\z/ }
    );

    return sub {
        if (@words) {
            return shift @words;
        }

        while (!@words && defined( my $txt = $phrase_iter->() )) {
            my @c = split("", $txt);

            for my $i (0..$#c) {
                if ($i > 0) {
                    $lcontext{$c[$i]}{$c[$i-1]}++;
                    for my $n (2,3) {
                        if ($i >= $n) {
                            my $tok = join('', @c[ ($i-$n+1) .. $i] );
                            unless ($word{$tok}) {
                                if (length($tok) > 1) {
                                    $lcontext{ $tok }{$c[$i - $n]}++;
                                }

                                if ($threshold <= (keys %{$lcontext{$tok}}) && $threshold <= (keys %{$rcontext{$tok}})) {
                                    $word{$tok} = 1;
                                    push @words, $tok;
                                }
                            }
                        }
                    }
                }
                if ($i < $#c) {
                    $rcontext{$c[$i]}{$c[$i+1]}++;
                    for my $n (2,3) {
                        if ($i + $n <= $#c) {
                            my $tok = join('', @c[$i .. ($i+$n-1)]);
                            unless ($word{$tok}) {
                                if (length($tok) > 1) {
                                    $rcontext{ $tok }{ $c[$i+$n] }++;
                                }

                                if ($threshold <= (keys %{$lcontext{$tok}}) && $threshold <= (keys %{$rcontext{$tok}})) {
                                    $word{$tok} = 1;
                                    push @words, $tok;
                                }
                            }
                        }
                    }
                }
            }
        }
        return shift @words;
    }
}

sub extract_words {
    return [ exhaust(word_iterator(@_)) ];
}

sub tokenize_by_script {
    my ($str) = @_;
    my @tokens;
    my @chars = grep { defined($_) } split "", $str;
    return () unless @chars;

    my $t = shift(@chars);
    my $s = charscript(ord($t));
    while(my $char = shift @chars) {
        my $_s = charscript(ord($char));
        if ($_s eq $s) {
            $t .= $char;
        }
        else {
            push @tokens, $t;
            $s = $_s;
            $t = $char;
        }
    }
    push @tokens, $t;
    return grep { ! /\A\s*\z/u } @tokens;
}

sub looks_like_simplified_chinese {
    my ($txt) = @_;
    return $txt =~ /$RE_simplified_chinese_characters/o;
}

1;

__END__

=encoding utf8

=head1 NAME

Text::Util::Chinese - A collection of subroutines for processing Chinese Text

=head1 DESCRIPTIONS

The subroutines provided by this module are for processing Chinese text.
Conventionally, all input strings are assumed to be wide-characters.  No
`decode_utf8` or `utf8::decode` were done in this module. Users of this module
should deal with input-decoding first before passing values to these
subroutines.

Given the fact that corpus files are usually large, it may be a good idea to
avoid slurping the entire input stream. Conventionally, subroutines in this
modules accept "input iterator" as its way to receive a small piece of corpus
at a time. The "input iterator" is a CodeRef that returns a string every time
it is called, or undef if there are nothing more to be processed. Here's a
trivial example to open a file as an input iterator:

    sub open_as_iterator {
        my ($path) = @_
        open my $fh, '<', $path;
        return sub {
            my $line = <$fh>;
            return undef unless defined($line);
            return decode_utf8($line);
        }
    }

    my $input_iter = open_as_iterator("/data/corpus.txt");

This C<$input_iter> can be then passed as arguments to different subroutines.

Although in the rest of this document, `Iter` is used as a Type
notation for iterators. It is the same as a CODE reference.

=head1 EXPORTED SUBROUTINES

=over 4

=item word_iterator( $input_iter ) #=> Iter

This extracts words from Chinese text. A word in Chinese text is a token
with N charaters. These N characters is often used together in the input and
therefore should be a meaningful unit.

The input parameter is a iterator -- a subroutine that must return a string of
Chinese text each time it is invoked. Or, when the input is exhausted, it must
return undef. For example:

    open my $fh, '<', 'book.txt';
    my $word_iter = word_iterator(
        sub {
            my $x = <$fh>;
            return decode_utf8 $x;
        });

The type of return value is Iter (CODE ref).

=item extract_words( $input_iter ) #=> ArrayRef[Str]

This does the same thing as C<word_iterator>, but retruns the exhausted list instead of iterator.

For example:

    open my $fh, '<', 'book.txt';
    my $words = extract_words(
        sub {
            my $x = <$fh>;
            return decode_utf8 $x;
        });

The type of return value is ArrayRef[Str].

It is likely that this subroutine returns an empty ArrayRef with no contents.
It is only useful when the volume of input is a leats a few thousands of
characters. The more, the better.

=item presuf_iterator( $input_iter, $opts) #=> Iter

This subroutine extract meaningful tokens that are prefix or suffix of
input.

The 2nd argument C<$opts> is a HashRef with parameters C<threshold>
and C<lengths>. C<threshold> should be an Int, C<lengths> should be an
ArrayRef[Int] and that constraints the lengths of prefixes and
suffixes to be extracted.

The default value for C<threshold> is 9, while the default value for C<lengths> is C<[2,3]>

=item extract_presuf( $input_iter, $opts ) #=> ArrayRef[Str]

Similar to C<presuf_iterator>, but returns a ArrayRef[Str] instead.

=item sentence_iterator( $input_iter ) #=> Iter

This subroutine split input into sentences. It takes an text iterator,
and returns another one.

=item phrase_iterator( $input_iter ) #=> Iter

This subroutine split input into smallelr phrases. It takes an text iterator,
and returns another one.

=item tokenize_by_script( $text ) #=> Array[ Str ]

This subroutine split text into tokens, where each token is the same writing script.

=item looks_like_simplified_chinese( $text ) #=> Bool 

This subroutine does a naive test on the input C<$text> and returns true if C<$text> looks like it is written in Simplified Chinese.

=back

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 LICENSE

Unlicense L<https://unlicense.org/>
