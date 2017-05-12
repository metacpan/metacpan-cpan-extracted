#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;

use HTTP::Request;
use Web::Request;

my $path = "/Платежи";

my $hreq = HTTP::Request->new(GET => "http://localhost" . $path);
my $req = Web::Request->new_from_request($hreq);

is $req->uri->path, '/%D0%9F%D0%BB%D0%B0%D1%82%D0%B5%D0%B6%D0%B8';

done_testing;
