use 5.012;
use warnings;
use lib 't';
use MyTest;

dcnt();

use Devel::Peek;

my $o = new_ok "MyTest::MyConst" => [123];
is $o->get_val, 123;
$o->set_val(321);
is $o->get_val, 321;

my $co = MyTest::MyConst->new_const(333);
isa_ok $co, "MyTest::MyConst";
is $co->get_val, 333, "const method";
undef $co;
cmp_deeply dcnt(), [1, 1], "obj deleted";

$co = MyTest::MyConst->new_const(333);
dies_ok { $co->set_val(444) } "non-const method";
is $co->get_val, 333;

$o->set_from($co);
is $o->get_val, 333, "as const arg";
$o->set_val(444);
dies_ok { $co->set_form($o) } "non-const method";
is $co->get_val, 333;

undef $co;
undef $o;
dcnt();

$o = new_ok "MyTest::MyConst2" => [888];
is $o->get_val, 555;
undef $o;
cmp_deeply dcnt(), [1, 1], "obj deleted";

$co = MyTest::MyConst2->new_const(777);
isa_ok $co, "MyTest::MyConst2";
is $co->get_val, 777;
undef $co;
cmp_deeply dcnt(), [1, 1], "obj deleted";

done_testing();
