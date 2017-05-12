use strict;
use warnings;
use Test::More;

use Test::Mock::Furl;

use Furl;
use Furl::Request;

$Mock_furl->mock(request => sub { Furl::Response->new } );
$Mock_furl_res->mock(message => sub { 'ok ok ok' } );

my $req  = Furl::Request->new('GET' => 'http://example.com/');
my $furl = Furl->new;
my $res  = $furl->request($req);

isa_ok $req, 'Test::MockObject';
isa_ok $furl, 'Test::MockObject';

ok $res->is_success;
is $res->code, 200;
is $res->content, '';
is $res->message, 'ok ok ok';

done_testing;
