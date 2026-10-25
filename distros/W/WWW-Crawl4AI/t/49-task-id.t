#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use WWW::Crawl4AI::Client;

# The task id is one path segment: unencoded it could address another endpoint
# ("../../health") or split path and query ("abc?x=1").

my $client = WWW::Crawl4AI::Client->new( base_url => 'http://localhost:11235' );

my $traversal = $client->job_status_request('../../health');
is $traversal->uri->path, '/crawl/job/..%2F..%2Fhealth', 'a traversal stays inside the segment';
unlike $traversal->uri->path, qr{/\.\./}, 'no raw dot segment is left in the path';

my $split = $client->job_status_request('abc?x=1#frag');
is $split->uri->path, '/crawl/job/abc%3Fx%3D1%23frag', 'a question mark and a hash stay in the segment';
is $split->uri->query,    undef, 'no query is split off';
is $split->uri->fragment, undef, 'no fragment is split off';

my $umlaut = $client->job_status_request('aufgabe-ä');
is $umlaut->uri->path, '/crawl/job/aufgabe-%C3%A4', 'the task id is percent encoded as UTF-8';

done_testing;
