use strict;
use warnings;
use Test::More;

use Test::Mock::Furl;

use Furl::HTTP;

$Mock_furl_http->mock(
    request => sub {
        ( 1, 200, 'OK', ['content-type' => 'text/plain'], 'mock me baby!' );
    },
);

my $furl = Furl::HTTP->new;
my @res  = $furl->request(
    method => 'GET',
    host   => 'example.com',
    port   => 80,
    path   => '/',
);

isa_ok $furl, 'Test::MockObject';

is scalar(@res), 5;
is $res[1], 200;
is $res[4], 'mock me baby!';

done_testing;
