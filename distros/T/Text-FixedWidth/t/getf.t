use Test::More(tests => 10);
use Test::Warn;
use Text::FixedWidth;
use warnings;

ok(my $fw = new Text::FixedWidth, "new()");
ok($fw->set_attributes(qw(
      fname           Jay    %10s
      points1         12     %4d
      points2         19     %04d
      money           34.6   %07.2f
   )),                                         "set_attributes()");
is($fw->get_fname,    'Jay',                   "get_fname()");
is($fw->getf_fname,   '       Jay',            "getf_fname()");
is($fw->get_points1,  12,                      "get_points1()");
is($fw->getf_points1, '  12',                  "getf_points1()");
is($fw->get_points2,  19,                      "get_points2()");
is($fw->getf_points2, '0019',                  "getf_points2()");
is($fw->get_money,    34.6,                    "get_money()");
is($fw->getf_money,   '0034.60',               "getf_money()");


