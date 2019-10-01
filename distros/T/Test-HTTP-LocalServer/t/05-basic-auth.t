#!perl -w
use strict;
use warnings;
use Test::HTTP::LocalServer;
use HTTP::Tiny;

use Test::More tests => 5;

my $server = Test::HTTP::LocalServer->spawn(
#    debug => 1,
);

local @ENV{ qw[
    HTTP_PROXY
    http_proxy
    HTTP_PROXY_ALL
    http_proxy_all
    HTTPS_PROXY
    https_proxy
    CGI_HTTP_PROXY
    ALL_PROXY
    all_proxy
] };

my $pid = $server->{_pid};
my $res = kill 0, $pid;
is $res, 1, "PID $pid is an existing process";

my $challenge_url = $server->basic_auth('foo','secret');

$res = HTTP::Tiny->new->get($challenge_url);
is $res->{status}, 401, "We can get a basic auth challenge";

my $wrong_pw = URI->new( $challenge_url );
$wrong_pw->userinfo('foo:hunter2');
$res = HTTP::Tiny->new->get($wrong_pw);
is $res->{status}, 401, "We get the challenge with a wrong user/password as well";

my $basic_url = URI->new( $challenge_url );
$basic_url->userinfo('foo:secret');
$res = HTTP::Tiny->new->get($basic_url);
is $res->{status}, 200, "We pass once we supply the correct credentials";

$server->stop;

my $timeout = time + 5;

# just give it more time to be really sure
while ( time < $timeout ) {
    sleep 0.1;
    $res = kill 0, $pid;
    last if defined $res and $res == 0;
};

is $res, 0, "PID $pid doesn't exist anymore";
