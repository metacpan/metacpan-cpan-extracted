#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use Web::Request;

my $req = Web::Request->new_from_env({ REMOTE_HOST => "foo.example.com" });
is $req->remote_host, "foo.example.com";

$req = Web::Request->new_from_env({ REMOTE_HOST => '', REMOTE_ADDR => '127.0.0.1' });
is $req->address, "127.0.0.1";

done_testing;
