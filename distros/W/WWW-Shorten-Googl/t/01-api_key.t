use strict;
use warnings;
use Test::More;
use Try::Tiny qw(try catch);
use WWW::Shorten::Googl;

unless ($ENV{GOOGLE_API_KEY}) {
    plan skip_all => 'no GOOGLE_API_KEY set in the environment';
    done_testing;
    exit;
}

my $url = 'http://metacpan.org/pod/WWW::Shorten::Googl';

my ($err, $res);

# successes
{
    $err = undef; $res = undef;
    try {
        $res = makeashorterlink($url);
    }
    catch {
        $err = $_;
    };
    is($err,undef,'makeashorterlink: no errors');
    like($res, qr{^http://goo.gl/\w+$}, 'makeashorterlink: proper URL response');

    my ($code, $short_url);
    if ($res && $res =~ m{^http://goo.gl/(\w+)$}) {
        $code = $1;
        $short_url = $res;
    }

    $err = undef; $res = undef;
    try {
        $res = makealongerlink($short_url);
    }
    catch {
        $err = $_;
    };
    is($err,undef,'makealongerlink: full URL: no errors');
    is($res, $url, 'makealongerlink: full URL: proper URL response');

    $err = undef; $res = undef;
    try {
        $res = makealongerlink($code);
    }
    catch {
        $err = $_;
    };
    is($err,undef,'makealongerlink: short code: no errors');
    is($res, $url, 'makealongerlink: short code: proper URL response');

    $err = undef; $res = undef;
    try {
        $res = getlinkstats($short_url);
    }
    catch {
        $err = $_;
    };
    is($err,undef,'getlinkstats: full URL: no errors');
    isa_ok($res, 'HASH', 'getlinkstats: full URL: proper URL response');

    $err = undef; $res = undef;
    try {
        $res = getlinkstats($code);
    }
    catch {
        $err = $_;
    };
    is($err,undef,'getlinkstats: short code: no errors');
    isa_ok($res, 'HASH', 'getlinkstats: short code: proper URL response');
}

done_testing();
