#!perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::Mock::LWP::Dispatch;

$mock_ua->map('http://zzz.ru', HTTP::Response->new(400));

# imitation of real life :-)
my $f = sub {
    my $ua = LWP::UserAgent->new;
    my $resp = $ua->get('http://zzz.ru');
    return $resp;
};
my $resp = $f->();
is($resp->code, 400, 'check only global mapping');

my $ua = LWP::UserAgent->new;
$ua->map('http://abc.ru', HTTP::Response->new(401));
$resp = $ua->get('http://abc.ru');
is($resp->code, 401, 'check local mapping works with global');

$resp = $ua->get('http://zzz.ru');
is($resp->code, 400, 'check global mapping works with local');

my $index = $ua->map('http://zzz.ru', HTTP::Response->new(403));
$resp = $ua->get('http://zzz.ru');
is($resp->code, 403, 'check local mapping overrides global');

$ua->unmap($index);
$resp = $ua->get('http://zzz.ru');
is($resp->code, 400, 'local unmap in existence of global');

$mock_ua->unmap_all;
$resp = $ua->get('http://zzz.ru');
is($resp->code, 404, 'global unmap_all');

