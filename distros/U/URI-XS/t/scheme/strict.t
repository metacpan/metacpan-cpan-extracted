use strict;
use warnings;
use Test::More;
use Test::Exception;
use URI::XS qw/uri :const/;

my $wrong_scheme = qr/panda::uri::WrongScheme/;

subtest 'no class' => sub {
    my $uri = uri('lalala');
    is ref($uri), 'URI::XS';

    $uri = uri('//crazypanda.ru/abc');
    is ref($uri), 'URI::XS';
};

subtest 'same scheme assignable' => sub {
    my $uri = uri("http://a.b");
    is ref($uri), 'URI::XS::http';
    $uri->assign("http://b.c/d");
    is($uri->host, 'b.c');
    is($uri->path, '/d');
    $uri->scheme("http");
};

subtest 'wrong scheme' => sub {
    my $uri = uri("http://ru.ru");
    throws_ok { $uri->assign("ftp://ru.ru") } $wrong_scheme;
    throws_ok { $uri->scheme("ftp") } $wrong_scheme;
};

subtest 'copy assign (set)' => sub {
    my $uri = uri("http://a.b");
    $uri->set(uri("http://c.d"));
    is($uri->host, 'c.d');
    $uri->set(URI::XS->new("https://e.f"));
    is($uri->host, 'e.f');
    throws_ok { $uri->set(URI::XS->new("ftp://e.f")) } $wrong_scheme;
};

subtest 'create strict class' => sub {
    my $uri = URI::XS::http->new("http://ya.ru");
    is ref($uri), 'URI::XS::http';
    throws_ok { URI::XS::http->new('ftp://syber.ru') } $wrong_scheme;
};

subtest 'apply strict scheme to proto-relative urls' => sub {
    my $uri = URI::XS::http->new("//syber.ru");
    is($uri, 'http://syber.ru');
    
    $uri = URI::XS::https->new("//syber.ru");
    is($uri, 'https://syber.ru');
    
    $uri = URI::XS::ftp->new("syber.ru/abc", ALLOW_SUFFIX_REFERENCE);
    is($uri, 'ftp://syber.ru/abc');
};

done_testing();
