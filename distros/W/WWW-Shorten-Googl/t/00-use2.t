use strict;
use warnings;
use Test::More;
use Try::Tiny qw(try catch);

BEGIN {
    use_ok('WWW::Shorten', 'Googl') or BAIL_OUT("Can't use module");
    # These tests only work if we don't auth
    $ENV{GOOGLE_API_KEY} = undef;
}

can_ok('main', qw(makealongerlink makeashorterlink getlinkstats));

my ($err, $res);

# stereotypical errors
{
    $err = undef; $res = undef;
    try {
        $res = makeashorterlink();
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'makeashorterlink: empty call, no response');
    ok($err,'makeashorterlink: empty call, errored out');

    $err = undef; $res = undef;
    try {
        $res = makeashorterlink(undef);
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'makeashorterlink: undef passed, no response');
    ok($err,'makeashorterlink: undef passed, errored out');

    $err = undef; $res = undef;
    try {
        $res = makeashorterlink('');
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'makeashorterlink: empty string, no response');
    ok($err,'makeashorterlink: empty string, errored out');

    $err = undef; $res = undef;
    try {
        $res = makealongerlink();
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'makealongerlink: empty call, no response');
    ok($err,'makealongerlink: empty call, errored out');

    $err = undef; $res = undef;
    try {
        $res = makealongerlink(undef);
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'makealongerlink: undef passed, no response');
    ok($err,'makealongerlink: undef passed, errored out');

    $err = undef; $res = undef;
    try {
        $res = makealongerlink('');
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'makealongerlink: empty string, no response');
    ok($err,'makealongerlink: empty string, errored out');

    $err = undef; $res = undef;
    try {
        $res = getlinkstats();
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'getlinkstats: empty call, no response');
    ok($err,'getlinkstats: empty call, errored out');

    $err = undef; $res = undef;
    try {
        $res = getlinkstats(undef);
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'getlinkstats: undef passed, no response');
    ok($err,'getlinkstats: undef passed, errored out');

    $err = undef; $res = undef;
    try {
        $res = getlinkstats('');
    }
    catch {
        $err = $_;
    };
    is($res, undef, 'getlinkstats: empty string, no response');
    ok($err,'getlinkstats: empty string, errored out');
}

done_testing();
