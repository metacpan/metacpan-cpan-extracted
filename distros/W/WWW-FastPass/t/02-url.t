#!perl

use warnings;
use strict;

use Test::More tests => 10;

use WWW::FastPass;
use URI;

my $url = eval { WWW::FastPass::url() };
ok($@, 'Died where no arguments provided');

my $current_time = time();
$url = eval { WWW::FastPass::url('key', 'secret', 'test@example.com',
                                 'testname', 'testuid') };
ok((not $@), 'Called url successfully');
ok($url, 'Got a result from the url function');
like($url, qr/^http:/, 'URL points to http when is_secure is false');

my $uri = URI->new($url);
my %query_form = $uri->query_form();
is($query_form{'email'}, 'test@example.com',
    'Email address set in URL');
is($query_form{'name'}, 'testname',
    'User name set in URL');
is($query_form{'uid'}, 'testuid',
    'User unique identifier set in URL');
my $timestamp = $query_form{'oauth_timestamp'};
ok(($timestamp - $current_time <= 5),
    'Timestamp set correctly in URL');

$url = eval { WWW::FastPass::url('key', 'secret', 'test@example.com',
                                 'testname', 'testuid', 1, { a => 'b' }) };
like($url, qr/^https/, 'URL points to https when is_secure is true');
$uri = URI->new($url);
%query_form = $uri->query_form();
is($query_form{'a'}, 'b',
    'The contents of extra_fields were added to the URL');

1;
