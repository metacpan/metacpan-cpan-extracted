#!perl
use strict;
use warnings;
use Test::More tests => 16;
use Test::Mock::LWP::Dispatch ();

my $treq = HTTP::Request->new('GET', 'http://a.ru');
my $tresp = HTTP::Response->new(201);
my $tresp_sub = sub {
    my $req = shift;
    my ($n) = $req->uri =~ /(\d+)$/;
    $n = "0" unless defined($n);
    return HTTP::Response->new("20" . $n);
};

my @tests = (
    [ 'http://a.ru', $tresp, 201, 'http://a.ru', 'http://b.ru',
      'check string $req and HTTP::Response $resp' ],
    [ qr/asdf/, $tresp, 201, 'http://asdf.ru', 'http://a.ru',
      'check regexp $req and HTTP::Response $resp' ],
    [ $treq, $tresp, 201, 'http://a.ru', 'http://b.ru',
      'check HTTP::Request $req and HTTP::Response $resp' ],
    [ sub { shift->uri =~ /a/ }, $tresp, 201, 'http://a.ru', 'http://b.ru',
      'check sub $req and HTTP::Response $resp' ],

    [ 'http://a.ru/1', $tresp_sub, 201, 'http://a.ru/1', 'http://b.ru',
      'check string $req and sub $resp' ],
    [ qr/asdf/, $tresp_sub, 202, 'http://asdf.ru/2', 'http://a.ru',
      'check regexp $req and sub $resp' ],
    [ $treq, $tresp_sub, 200, 'http://a.ru', 'http://b.ru',
      'check HTTP::Request $req and sub $resp' ],
    [ sub { shift->uri =~ /a/ }, $tresp_sub, 200, 'http://a.ru/0', 'http://b.ru',
      'check sub $req and sub $resp' ],
);
foreach my $test (@tests) {
    my ($req, $resp, $status, $get_url, $bad_url, $test_name) = @{$test};

    my $ua = LWP::UserAgent->new;
    $ua->map($req, $resp);

    my $good_resp = $ua->get($get_url);
    is($good_resp->code, $status, "$test_name, good");

    my $bad_resp = $ua->get($bad_url);
    is($bad_resp->code, '404', "$test_name, bad");
}

