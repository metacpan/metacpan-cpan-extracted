# -*- perl -*-

use Test::SMTP;
use Test::More;
use Test::Builder::Tester tests => 1;

test_out("ok 1 - Passes because can't connect to SMTP on 25000",
"ok 2 - undef was returned on can't connect",
"not ok 3 - Fails because can't connect to SMTP on 25000",
"ok 4 - undef was returned on can't connect");

my $c1 = Test::SMTP->connect_ko('Passes because can\'t connect to SMTP on 25000', Host => 127.0.0.1, Port => 2500, AutoHello => 1);

ok(not(defined $c1), 'undef was returned on can\'t connect');

test_fail(+1);
my $c2 = Test::SMTP->connect_ok('Fails because can\'t connect to SMTP on 25000', Host => 127.0.0.1, Port => 2500, AutoHello => 1); 

ok(not(defined $c2), 'undef was returned on can\'t connect');

test_test("everything works");
