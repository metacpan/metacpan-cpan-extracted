use strict;
use warnings;
use Test::More;

use Test::Mock::Furl;

use Furl;

for my $method (qw/get head post put delete/) {
    $Mock_furl->mock($method => sub { "$method!" });
}

my $furl = Furl->new;
isa_ok $furl, 'Test::MockObject';

my $url = 'http://example.com/'; # dummy

is $furl->get($url),  'get!';
is $furl->head($url), 'head!';
is $furl->post($url), 'post!';
is $furl->put($url), 'put!';
is $furl->delete($url), 'delete!';

done_testing;
