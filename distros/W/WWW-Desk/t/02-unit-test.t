#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';

use WWW::Desk::Browser;

use Test::More;
use Test::FailWarnings;
use Test::Exception;
use Data::Dumper;

plan tests => 2;

subtest "WWW::Desk::Browser object attribute require test" => sub {
    plan tests => 2;
    throws_ok { WWW::Desk::Browser->new() } qr/Attribute \(base_url\) is required/, "missing base_url argument";

    lives_ok {
        WWW::Desk::Browser->new(base_url => 'https://test.desk.com');
    }
    "object constructed";
};

subtest "WWW::Desk validate authentication module" => sub {
    plan tests => 2;

    my $browser = WWW::Desk::Browser->new(base_url => 'https://test.desk.com');
    is($browser->prepare_url('/hello'), 'https://test.desk.com/api/v2/hello', "URL path correct");

    $browser = WWW::Desk::Browser->new(base_url => 'https://test.desk.com/');
    is($browser->prepare_url('/hello'), 'https://test.desk.com/api/v2/hello', "Again URL path correct");
};

done_testing();

