use strict;
use warnings;
use Test::More;
use WebService::Heartrails::Express;
use utf8;

my $express = new WebService::Heartrails::Express();

subtest 'area' => sub{
 my $content = $express->areas;
 is($content->[2],'関東');
 is($content->[5],'中国');
};

subtest 'pref' => sub{
 my $content = $express->prefs;
 is($content->[0],'北海道');
 is($content->[5],'山形県');
};

subtest 'line' => sub{
 my $area_only = $express->line({area => '関東'});
 is($area_only->[2],'JR中央線');
 my $pref_only = $express->line({prefecture => '神奈川県'});
 is($pref_only->[1],'JR京浜東北線');
 my $pref_and_area = $express->line({area => '関東',prefecture => '千葉県'});
 is($pref_and_area->[3],'JR外房線');
};

subtest 'station' => sub{
 my $lineonly = $express->station({line => 'JR山手線'});
 is($lineonly->[1]->{name},'大崎');
 my $nameonly = $express->station({name => '新宿'});
 is($nameonly->[1]->{prefecture},'東京都');
 is($nameonly->[1]->{line},'JR埼京線');
 my $name_and_line = $express->station({line => 'JR山手線',name => '新宿'});
 is($name_and_line->[0]->{prev},'代々木');
};

subtest 'near' => sub{
 my $near = $express->near({x => '135.0',y => '35.0'});
 is($near->[0]->{next},'黒田庄');
 is($near->[0]->{distance},'310m');
 is($near->[0]->{x},'134.997666');
};

done_testing;




