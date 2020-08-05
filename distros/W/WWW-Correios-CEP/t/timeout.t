use utf8;

use Test::More tests => 3;
BEGIN { use_ok('WWW::Correios::CEP') }
use Test::RequiresInternet ( 'www.buscacep.correios.com.br' => 80 );

my $cepper = WWW::Correios::CEP->new(
    { timeout => 1, post_url => 'http://192.168.0.184/', require_tests => 0 } );

is( ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok' );

my $got = $cepper->find('03640-000');

like( $got->{status}, qr/(can't connect|timeout)/i, 'timeout in 1 sec is ok!' )
  || diag explain $got;
