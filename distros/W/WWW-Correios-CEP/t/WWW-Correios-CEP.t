use utf8;

use Test::More tests => 4;
BEGIN { use_ok('WWW::Correios::CEP') }
use Test::RequiresInternet ( 'www.buscacep.correios.com.br' => 80 );

my $cepper = WWW::Correios::CEP->new;

is( ref $cepper, 'WWW::Correios::CEP', 'WWW::Correios::CEP class ok' );
diag("downloading...");

my $got  = $cepper->find('03640-000');
my $expt = {
    street        => 'Rua Cupá',
    neighborhood  => 'Vila Carlos de Campos',
    location      => 'São Paulo',
    uf            => 'SP',
    cep           => '03640-000',
    status        => '',
    address_count => 1
};
is_deeply( $got, $expt, 'testing address for 03640-000' ) || diag explain $got;

my $got2 = $cepper->find( '03640-000', 1 );
is( ref $got2, 'HTML::Element' );

