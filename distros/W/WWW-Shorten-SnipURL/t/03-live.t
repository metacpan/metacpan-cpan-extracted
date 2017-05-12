use strict;
use warnings;
use Test::More;
use Try::Tiny qw(try catch);
use WWW::Shorten::SnipURL;

my $url = 'http://code.mag-sol.com/WWW-Shorten/WWW-Shorten.1.95.tar.gz';
my $prefix = 'http://snipurl.com/';

{ # blank call errors
    my $err = try { makeashorterlink() } catch { "no dice: $_" };
    like($err, qr/^no dice/, 'makeashorterlink: error on empty call');
    $err = undef;

    $err = try { makeashorterlink() } catch { "no dice: $_" };
    like($err, qr/^no dice/, 'makealongerlink: error on empty call');
}

SKIP: {
    skip "Can't run live tests", 10;
    my $err;
    my $shortened = try { makeashorterlink($url) } catch { $err=$_; undef };
    is($err,undef, "makeashorterlink: no errors");
    skip "Got an error trying to shorten", 9 if $err;
    ok($shortened, "makeashorterlink: got a response");
    skip "Got no shortened response", 8 unless $shortened;
    like($shortened, qr{^http://sn(?:ip)?url\.com/\w+$}, 'makeashorterlink: good url');

    my $code;
    if ($shortened =~ m{^http://sn(?:ip)?url\.com/(\w+)$}) {
        $code = $1;
    }
    ok($code, "makeashorterlink: got a short code");

    $err = undef;
    my $longer = try { makealongerlink($prefix.$code) } catch { $err=$_; undef };
    is($err, undef, "makealongerlink: whole - no errors");
    is($longer,$url, "makealongerlink: whole - got back the URL");

    $err = undef; $longer = undef;
    $longer = try { makealongerlink($code) } catch { $err=$_; undef };
    is($err, undef, "makealongerlink: code - no errors");
    is($longer,$url, "makealongerlink: code - got back the URL");

    $err = undef; $longer = undef;
    $longer = try { makealongerlink($shortened) } catch { $err=$_; undef };
    is($err, undef, "makealongerlink: shortened - no errors");
    is($longer,$url, "makealongerlink: shortened - got back the URL");
}

done_testing();
