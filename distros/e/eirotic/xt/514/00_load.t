#! /usr/bin/perl
use Eirotic::514;
use Test::More;

ok 1, "Eirotic loaded";

func test_signature ( $int ) {
    ok "int passed: $int";
}


eval '$x';
ok $@,"strictures are working: $@";

my $take = take 5, sub {"yes"};
ok
( (ref $take)
,  "Perlude loaded" );

done_testing;
