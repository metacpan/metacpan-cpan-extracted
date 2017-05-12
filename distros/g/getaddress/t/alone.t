use Test::More tests => 2;
BEGIN { use_ok('getaddress') };

use Encode qw(from_to);

my $datafile = './data/QQWry.Dat';

my $str = &ipwhere('221.203.140.26', $datafile);
from_to($str, "GBK", "UTF8");
is($str, "辽宁省辽阳市灯塔市 e凯跃网吧(建设大街苑南路与建设街交汇处西30米灯塔供电分局东)", "a ip address test");
