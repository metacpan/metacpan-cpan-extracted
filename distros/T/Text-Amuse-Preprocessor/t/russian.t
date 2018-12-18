# -*- mode: cperl -*-
use strict;
use warnings;
use utf8;

binmode STDOUT, ":encoding(utf-8)";
binmode STDIN, ":encoding(utf-8)";

use Test::More tests => 39;
use Data::Dumper;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Text::Amuse::Preprocessor::Typography qw/typography_filter/;
use Text::Amuse::Preprocessor;

my $test =<< 'EOF';
Я еду домой по~дороге в~школу. Если~бы всё зависело от~меня, но~это
не~так. Что~же с~этим поделаешь, раз такие у~нас плохие и~мусора,
и~грабители. Я~— человек хороший, а~они~— плохие. К~моему сожалению,
с~умом о~ней говорить не~получилось. Еду я значит к~другу, у~которого
ни~кола, ни~двора. О~нём я тебе рассказывал. Ну~я ему и~говорю:
ну,~отвечай. От~него, от~неё и~пошло всё. Об~этом~же я писал 12~см
назад. И~25~м и~65~л и~даже 809~В. Всё что душе пожелаешь. То~самое
89~кг превращаются в~90~г, при желании. Если~бы ты пошёл, да~вот
не~вылез. Да,~красиво тут. Но~могло быть и~лучше. По~сему заключаю
не~воровать, что~б ты сдох. В~т.ч.~тебя. Ну~тебя то~и~т.п.~свору.
Со~двора надо гнать. До~коле можно терпеть. Ко~мне приходят. Ту~девушку.
Во~второй половине. Та~подруга ко~мне пошла во~втором часу.
12~января, 12~мая, 12~апреля, 12~февраля, 12~марта, 12~июня, 12~июля,
12~августа, 12~сентября, 12~октября, 12~ноября, 12~декабря. Те~кто пошли
домой, на~горку не~пойдут. За~домой стоит из~него выходит.
Да,~причудилось. Об~этом надо ну~может и~не~надо. По~тебе, но~не~по~мне.
За~дом спрятался. Ни~кола, ни~двора. На~юг полетели, но,~казалось~бы,
не~долетели. То~что надо. См.~тут. до~дома. во~вторник. со~кооператив.
та~неделя. ту~подругу. то~село. те~люди. эй, см.~примечание. Не~поеду.
На~гору. Ну~и~ладно. Ну,~понеслась! Об~этом говорили. Из~избы
выбежали~же. Да~поехал он. Но~пошло поехало. Им.~Ивана Лимбаха. Об~этом
говорится~ж. Не~это~ль. Он~же, кажется. 25~мм, превращаются в~35~дм,
а~они 1~км. 13~А~равны 45~ВТ, но~если 89~W, то~и~12~°C. Курица~−
не~человек.Ты а,~кажется. Ты и,~кажется. Ты с.~50. Ты т.~287.
31~марта
По~двору идёт в~дом коза, хочет залезть на~крышу
Едет и~идёт, но~плывёт
если~бы, да~не~получается~же
Ни~рыба, ни~мясо
если~бы, да~не~получается~же
Ну,~поехали
ну~он и~пошёл
35~мм
pogledaj ч.~3, см.~«Анархия работает»
т.~test п.~test См.~test
Школа им.~Махно
EOF

my @in = split(/\n/, $test);

my $count = 0;
foreach my $line (@in) {
    $count++;
    my $expected = $line;
    $expected =~ s/~/\x{a0}/g;
    my $input = $line;
    $input =~ s/~/ /g;
    my $got = typography_filter(ru => $input);
    my $show = $got;
    $show =~ s/\x{a0}/~/g;
    is $got, $expected, $line or diag "GOT: $count - " . $show;
}

$test = "#lang ru\n\n" . $test;
my $exp = my $in = $test;

$exp =~ s/~/\x{a0}/g;
$in  =~ s/~/ /g;
my $out = '';

my $pp = Text::Amuse::Preprocessor->new(input => \$in,
                                        output => \$out,
                                        debug => 0,
                                        remove_nbsp => 1,
                                        fix_nbsp => 1,
                                        fix_typography => 1);
$pp->process;
is_deeply ([ split /\n/, $out],
           [ split /\n/, $exp]);

my $stripped = '';

$pp = Text::Amuse::Preprocessor->new(input => \$out,
                                     output => \$stripped,
                                     debug => 0,
                                     fix_nbsp => 0,
                                     remove_nbsp => 1,
                                     fix_typography => 0);

$pp->process;
is_deeply ([ split /\n/, $stripped],
           [ split /\n/, $in]);

my $out2 = '';
my $exp2 = $test;
$exp2 =~ s/~/~~/g;
$pp = Text::Amuse::Preprocessor->new(input => \$in,
                                     output => \$out2,
                                     debug => 0,
                                     remove_nbsp => 1,
                                     fix_nbsp => 1,
                                     show_nbsp => 1,
                                     fix_typography => 0);
$pp->process;
is_deeply ([ split /\n/, $out2],
           [ split /\n/, $exp2]);
