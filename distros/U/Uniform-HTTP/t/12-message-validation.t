use strict;
use warnings;
use Test::More;
use lib 'lib';

use Uniform::HTTP::Message;
use Uniform::HTTP::Request;
use Uniform::HTTP::Response;

sub throws_like {
    my ($code, $pattern, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok !$ok, $name;
    like $@, $pattern, "$name reports the reason";
}

throws_like(
    sub { Uniform::HTTP::Message->new(unknown => 1) },
    qr/unknown constructor option/,
    'unknown message constructor option is rejected',
);
throws_like(
    sub { Uniform::HTTP::Message->new(headers => {}) },
    qr/headers must be an array reference/,
    'unordered header container is rejected',
);
throws_like(
    sub { Uniform::HTTP::Message->new(headers => [ ['Bad Name', 'x'] ]) },
    qr/header name must be an HTTP token/,
    'invalid header name is rejected',
);
throws_like(
    sub { Uniform::HTTP::Message->new(headers => [ ['Good', "bad\rvalue"] ]) },
    qr/prohibited control byte/,
    'newline in header value is rejected',
);
throws_like(
    sub { Uniform::HTTP::Message->new(body => chr(0x100)) },
    qr/body must be a byte string/,
    'wide-character body is rejected',
);
throws_like(
    sub { Uniform::HTTP::Message->new(version => 'HTTP/1.1') },
    qr/version must contain digits/,
    'version prefix is rejected',
);
throws_like(
    sub { Uniform::HTTP::Message->new->header_name(-1) },
    qr/non-negative integer/,
    'negative header index is rejected',
);
throws_like(
    sub { Uniform::HTTP::Request->new(target => '/') },
    qr/method is required/,
    'request requires method',
);
throws_like(
    sub { Uniform::HTTP::Request->new(method => 'GET') },
    qr/target is required/,
    'request requires target',
);
throws_like(
    sub { Uniform::HTTP::Request->new(method => 'BAD METHOD', target => '/') },
    qr/method must be an HTTP token/,
    'invalid method is rejected',
);
throws_like(
    sub { Uniform::HTTP::Request->new(method => 'GET', target => '/bad target') },
    qr/target must not contain spaces/,
    'space in target is rejected',
);
throws_like(
    sub { Uniform::HTTP::Response->new },
    qr/status is required/,
    'response requires status',
);
throws_like(
    sub { Uniform::HTTP::Response->new(status => 99) },
    qr/status must be an integer/,
    'status below range is rejected',
);
throws_like(
    sub { Uniform::HTTP::Response->new(status => 600) },
    qr/status must be an integer/,
    'status above range is rejected',
);
throws_like(
    sub { Uniform::HTTP::Response->new(status => 200, reason => "bad\nreason") },
    qr/reason contains a prohibited control byte/,
    'newline in reason is rejected',
);

done_testing;
