use strict;
use utf8;
use FindBin '$Bin';

use Text::Util::Chinese qw(sentence_iterator);
use Test2::V0;

subtest 'test with rand0m.txt' => sub {
    open my $fh, '<:utf8', "$Bin/data/rand0m.txt";

    my $iter = sentence_iterator(sub { <$fh> });

    my $sentences = 0;
    my $s = 0;
    while (defined(my $s = $iter->())) {
        ok $s =~ /\p{Han}/, $s;
        $sentences++;
    }

    ok $sentences >= 685, 'the number of sentences muts be more than the number of lines in t/data/rand0m.txt';
};

subtest 'test with specific cases' => sub {
    # Each of these strings are considered to be 1 sentence.
    my @atoms = (
        '「一個是開放食庫目前的食譜資料 (中式，西式，日式食譜各約 500 份)，另外一份是近當代華文作家資料 (作家 643 人，書籍 20,070 本，出版社 2,525 間)，兩份資料都是用  來標示，並且採取 json-ld 格式」',
        '德國男女薪資差距高達 21％，於是同工同酬日，柏林地鐵宣布開賣女人票，女性能少付 21％ 車資。',
        '柏林運輸公司發言人則回應：「一年只有一天，我們用價差，讓人對薪資不平等有感。但這個鴻溝，才是女性每天面對的現實。」',
        '好牧人協會遵循上述流程，已獲得許可函，設立「愛蔓延社會企業公司」。',
        '首先，社團法人必須召開會員大會修改章程，增加「可允許設立符合公益使命之公司」的條文，再將新的章程，報請內政部核備。',
        '我覺得慈濟　到處買地蓋「豪華屋子」　位在　浮洲橋　這個最神奇　蓋完屋子還要多蓋一個屋頂保護它',
    );
    my $i = 0;
    my $iter = sentence_iterator(sub { $atoms[$i++] });

    my @sentences;
    my $sentences = 0;
    while (defined(my $s = $iter->())) {
        push @sentences, $s;
    }
    is \@sentences, \@atoms;
};

subtest 'test with specific cases' => sub {
    # Each of these strings are considered to be 2 sentences.
    my $text = join('',
                    '德國男女薪資差距高達 21％，於是同工同酬日。柏林地鐵宣布開賣女人票，女性能少付 21％ 車資。',
                    '好牧人協會遵循上述流程。已獲得許可函，設立「愛蔓延社會企業公司」。',
                    '首先，社團法人必須召開會員大會修改章程。增加「可允許設立符合公益使命之公司」的條文，再將新的章程，報請內政部核備。');
    my @expected = (
        '德國男女薪資差距高達 21％，於是同工同酬日。',
        '柏林地鐵宣布開賣女人票，女性能少付 21％ 車資。',
        '好牧人協會遵循上述流程。',
        '已獲得許可函，設立「愛蔓延社會企業公司」。',
        '首先，社團法人必須召開會員大會修改章程。',
        '增加「可允許設立符合公益使命之公司」的條文，再將新的章程，報請內政部核備。'
    );

    my @text = ($text);
    my $iter = sentence_iterator(sub { shift @text });
    my @sentences;
    my $sentences = 0;
    while (defined(my $s = $iter->())) {
        push @sentences, $s;
    }
    is \@sentences, \@expected;
};

done_testing;
