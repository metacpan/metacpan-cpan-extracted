use strict;
use warnings;
use Test::More;
use utf8;
use WWW::Kosoku::API;

my $kosoku = WWW::Kosoku::API->new(f => '渋谷',t => '浜松',c => '普通車');

use Data::Dumper;
{
 package Data::Dumper;
 sub qquote {return shift;}
}
$Data::Dumper::Useperl = 1;

subtest 'Result' => sub{
  is($kosoku->{c},'普通車');
  is($kosoku->{sortBy},'距離');
  is($kosoku->{f},'渋谷');
  is($kosoku->{t},'浜松');
};

subtest 'RouteNo' => sub{
  is($kosoku->get_route_count,20);
};

subtest 'Summary' => sub{
  my $route1_summary = $kosoku->get_summary_by_routenumber(1);
  is($route1_summary->{TotalLength},279.2);
  is($route1_summary->{TotalToll},6000);
  is($route1_summary->{TotalTime},200);
};

subtest 'Details' => sub{
 is($kosoku->get_section_no_by_routenumber(1),3);
};

subtest 'Section' => sub{
  my $section = $kosoku->get_section_by_routenumber(1);
  is($section->[0]->{From},'渋谷');
  is($section->[0]->{To},'狩場');
  is($section->[0]->{Length},'53.2');
  is($section->[0]->{Order},'3');
  is($section->[0]->{Time},'52');
  is($section->[0]->{Tolls}->{No},2);
  is($section->[0]->{Tolls}->{Toll}->[0],'930円 通常料金');
  is($section->[0]->{Tolls}->{Toll}->[1],'930円 ETC料金');
};

subtest 'SubSections' => sub{
  my $first_subsection =  $kosoku->get_subsection_by_routenumber_and_sectionnumber(1,0);
  isa_ok $first_subsection,'ARRAY';
  is_deeply $first_subsection,[
          {
            'Length' => '3.8',
            'Time' => 4,
            'Road' => '首都高速３号渋谷線',
            'To' => '谷町ＪＣＴ',
            'From' => '渋谷'
          },
          {
            'Length' => '3.6',
            'Time' => 5,
            'Road' => '首都高速都心環状線',
            'To' => '浜崎橋ＪＣＴ',
            'From' => '谷町ＪＣＴ'
          },
          {
            'Length' => '0.6',
            'Time' => 1,
            'Road' => '首都高速１号羽田線',
            'To' => '芝浦ＪＣＴ',
            'From' => '浜崎橋ＪＣＴ'
          },
          {
            'Length' => 5,
            'Time' => 6,
            'Road' => '首都高速１１号台場線',
            'To' => '有明ＪＣＴ',
            'From' => '芝浦ＪＣＴ'
          },
          {
            'Length' => '30.3',
            'Time' => 24,
            'Road' => '首都高速湾岸線',
            'To' => '本牧ＪＣＴ',
            'From' => '有明ＪＣＴ'
          },
          {
            'Length' => '9.9',
            'Time' => 12,
            'Road' => '首都高速神奈川３号狩場線',
            'To' => '狩場',
            'From' => '本牧ＪＣＴ'
          }
        ];
};


done_testing;