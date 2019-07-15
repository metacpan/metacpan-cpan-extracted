use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use XS::Framework;

my $var = 10;
ok(!XS::Framework::sv_payload_exists($var));
XS::Framework::sv_payload_attach($var, 20);
ok(XS::Framework::sv_payload_exists($var));
is($var, 10);
is(XS::Framework::sv_payload($var), 20);

{
    my $payload = {a => 1};
    $var = "jopa";
    ok(XS::Framework::sv_payload_exists($var));
    XS::Framework::sv_payload_attach($var, $payload);
    cmp_deeply(XS::Framework::sv_payload($var), {a => 1});
}
ok(XS::Framework::sv_payload_exists($var));
cmp_deeply(XS::Framework::sv_payload($var), {a => 1});

XS::Framework::sv_payload_detach($var);
ok(!XS::Framework::sv_payload_exists($var));
# RV test
my $var_rv = bless {aaa => "aaa", bbb => "bbb"},"someclass";
my $some_class = bless {ccc => "ccc"}, "someclass2";
ok(!XS::Framework::rv_payload_exists($var_rv));
XS::Framework::rv_payload_attach($var_rv, $some_class);
ok(XS::Framework::rv_payload_exists($var_rv));

my $dTemp = $var_rv;
ok(XS::Framework::rv_payload($dTemp), "line ".__LINE__);
{
    my $payload = {a => 1};
    bless $var_rv,"numberclass";
    ok(XS::Framework::rv_payload_exists($var_rv));
    XS::Framework::rv_payload_attach($var_rv, $payload);
    cmp_deeply(XS::Framework::rv_payload($var_rv), {a => 1});
}
ok(XS::Framework::rv_payload_exists($var_rv));
cmp_deeply(XS::Framework::rv_payload($var_rv), {a => 1});

XS::Framework::rv_payload_detach($var_rv);
ok(!XS::Framework::rv_payload_exists($var_rv), "line ".__LINE__);
# ANY test
my $var_s = 10;
my $var_r = {};

ok (! XS::Framework::any_payload_exists($var_s), "line ".__LINE__);
ok (! XS::Framework::any_payload_exists($var_r), "line ".__LINE__);

XS::Framework::any_payload_attach($var_s,"test scalar");
XS::Framework::any_payload_attach($var_r,"test ref value");

ok ( XS::Framework::any_payload_exists($var_s));
ok ( XS::Framework::any_payload_exists($var_r), "line ".__LINE__);

my $rTemp = $var_r;
ok( XS::Framework::any_payload($rTemp));
{
    my $payload = {Test => 22};
    $var_r = [];
    $var_s = "not 10";
    ok(!XS::Framework::any_payload_exists($var_r));
    ok(XS::Framework::any_payload_exists($var_s));

    XS::Framework::any_payload_attach($var_r, $payload);
    XS::Framework::any_payload_attach($var_s, $payload);

    cmp_deeply( XS::Framework::any_payload($var_r), { Test => 22 } );
    cmp_deeply( XS::Framework::any_payload($var_s), { Test => 22 } );
}

ok ( XS::Framework::any_payload_exists($var_s));
ok ( XS::Framework::any_payload_exists($var_r));

XS::Framework::any_payload_detach($var_r);
XS::Framework::any_payload_detach($var_s);

ok (! XS::Framework::any_payload_exists($var_s));
ok (! XS::Framework::any_payload_exists($var_r));

done_testing();