use strict;
use warnings;
use Test::More;
use utf8;
use WWW::Jugem::API;

my $jugem = WWW::Jugem::API->new(date => '2014/09/09');

my $response = $jugem->fetch('双子座');

subtest '双子座' => sub{
 isa_ok $response,'HASH';
 is_deeply $response,{
          'item' => '柑橘系の香水',
          'content' => '不利な状況でも、強気な姿勢を崩さないことがポイント。今日の仕事では、あなたらしく素晴らしい結果が出せそうです。',
          'money' => 3,
          'total' => 3,
          'job' => 3,
          'color' => 'ホワイト',
          'day' => '',
          'love' => 4,
          'rank' => 7,
          'sign' => '双子座'
        };
};

done_testing;