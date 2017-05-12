use utf8;

use Test::More tests => 3;
BEGIN { use_ok('WWW::Correios::CEP') }

my $cepper = WWW::Correios::CEP->new(
    { timeout => 1, post_url => 'http://192.168.0.184/', require_tests => 0 } );

is( ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok' );

my $got = $cepper->find('03640-000');

my $expt = { 'status' => 'Error: 500 Can\'t connect to 192.168.0.184:80' };

like( $got->{status}, qr{Can't connect}, 'timeout in 1 sec is ok!' )
  || diag explain $got;
