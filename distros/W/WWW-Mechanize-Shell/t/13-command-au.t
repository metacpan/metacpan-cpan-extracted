#!/usr/bin/perl -w
use strict;
use FindBin;

use lib './inc';
use IO::Catch;
our ( $_STDOUT_, $_STDERR_ );
use URI;
use Test::HTTP::LocalServer;

# pre-5.8.0's warns aren't caught by a tied STDERR.
tie *STDOUT, 'IO::Catch', '_STDOUT_' or die $!;

# Disable all ReadLine functionality
$ENV{PERL_RL} = 0;

use Test::More tests => 4;

use WWW::Mechanize::Shell;

delete @ENV{qw(HTTP_PROXY http_proxy CGI_HTTP_PROXY)};

my $server = Test::HTTP::LocalServer->spawn();

my $user = 'foo';
my $pass = 'bar';

my $url = URI->new( $server->basic_auth($user => $pass));
my $host = $url->host;

my $s = WWW::Mechanize::Shell->new( 'test', rcfile => undef, warnings => undef );

# Try without credentials:
my $bare_url = $url;
diag "get $bare_url";
$s->cmd( "get $bare_url" );

my $code = $s->agent->response->code;
my $got_url = $s->agent->uri;

if (! is $code, 401, "Request without credentials gives 401") {
    diag "Page location : " . $s->agent->uri;
};

# Now try the shell command for authentication with bad credentials
$s->cmd( "auth x$user x$pass" );
$bare_url = $url;
diag "get $bare_url";
eval {
    $s->cmd( "get $bare_url" );
};
is $s->agent->res->code, 401, "Wrong password still results in a 401";
like $@, qr/Auth Required/, "We die because of that";

# Now try the shell command for authentication with correct credentials
$s->cmd( "auth $user $pass" );
$s->cmd( "get $bare_url" );
is $s->agent->res->code, 200, "Right password results in 200";

#diag "Shutting down test server at $url";
$server->stop;

