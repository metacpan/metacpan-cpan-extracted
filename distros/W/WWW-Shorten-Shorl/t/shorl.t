use strict;
use warnings;

use Test::More skip_all => 'Cannot accurately test due to changes at shorl.com';;
use Try::Tiny qw(try catch);
use WWW::Shorten::Shorl;

can_ok('WWW::Shorten::Shorl', qw(makeashorterlink makealongerlink));
can_ok('main', qw(makeashorterlink makealongerlink));

SKIP: {
    my $code;
    my $url = 'https://metacpan.org/pod/WWW::Shorten::Shorl?'.time;

    my $shorl;
    my $err;
    try { $shorl = makeashorterlink( $url ); } catch { $err = $_; };
    ok($shorl, "makeashorterlink: got a shortened url");
    is($err, undef, "makeashorterlink: no errors");

    skip("can't shorten",4) unless $shorl;

    my $long;
    $err = undef;
    try { $long = makealongerlink($shorl); } catch { $err = $_; };
    is($long, $url, 'makealongerlink: URL piece - correct link');
    is($err, undef, 'makealongerlink: URL piece - no errors');

    if ($shorl =~ m{^http://shorl.com/(.*)$}) {
        $code = $1;
    }
    ok($code, "got a code");
    skip("no code",2) unless $url;

    $long = undef;
    $err = undef;
    try { $long = makealongerlink($code); } catch { $err = $_; };
    is ($long, $url, 'makealongerlink: code - correct link');
    is($err, undef, 'makealongerlink: code - no errors');
}


{
    sleep(2);
    my $url = 'https://metacpan.org/pod/WWW::Shorten::Shorl?'.time;
    my ($shorl, $password, $err);
    try { ($shorl, $password) = makeashorterlink($url); } catch { $err = $_; };

    ok($shorl, "makeashorterlink: got a link");
    ok($password, "makeashorterlink: got a password");
    is($err, undef, "makeashorterlink: no error");

    like($shorl, qr{^http://shorl.com/.*$}, 'makeashorterlink: correct link');
    like($password, qr{^[a-z]+$}, 'makeashorterlink: correct password');
}

my $err;
$err = try { makeashorterlink(); } catch { $_ };
ok($err, 'makeashorterlink: proper error response');
$err = undef;
$err = try { makealongerlink(); } catch { $_ };
ok($err, 'makealongerlink: proper error response');

done_testing();
