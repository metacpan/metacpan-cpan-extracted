#!perl

use strict;
use warnings;
use Test::More;
use Try::Tiny qw(try catch);
use WWW::Shorten::IsGd;

my $url = q{http://maps.google.co.uk/maps?f=q&source=s_q&hl=en&geocode=&q=louth&sll=53.800651,-4.064941&sspn=33.219383,38.803711&ie=UTF8&hq=&hnear=Louth,+United+Kingdom&ll=53.370272,-0.004034&spn=0.064883,0.075788&z=14};

my $expected = 'https://is.gd/JPzsIR';
my $code = 'JPzsIR';
my $prefix = 'https://is.gd/';
{
    my $err = try { makeashorterlink(); } catch { $_ };
    ok($err, 'makeashorterlink: proper error response');
    $err = undef;

    $err = try { makealongerlink(); } catch { $_ };
    ok($err, 'makealongerlink: proper error response');
    $err = undef;
}

# shorter
my $res;
my $err;
try {
    $res = makeashorterlink($url);
}
catch {
    $err = $_;
};
is($err, undef, 'makeashorterlink: no error on URL');
ok($res, 'makeashorterlink: Got a response');
is($res, $expected, 'makeashorterlink: got the proper response');
if ($res && $res eq $expected) {
    my $res_code;
    if ($res =~ /(\w+)$/) {
        $res_code = $1;
    }
    is($res_code, $code, 'makeashorterlink: proper code');
    is($res, $prefix.$code, 'makeashorterlink: URL exactly as we expected');

    # longer
    my $longer;
    $err = undef;
    try {
        $longer = makealongerlink($prefix.$code);
    }
    catch {
        $err = $_;
    };
    is($err, undef, 'makealongerlink: full - no error on URL');
    is($longer, $url, 'makealongerlink: full - proper response');

    $longer = undef;
    $err = undef;
    try {
        $longer = makealongerlink($code);
    }
    catch {
        $err = $_;
    };
    is($err, undef, 'makealongerlink: code - no error on URL');
    is($longer, $url, 'makealongerlink: code - proper response');

}

done_testing();
