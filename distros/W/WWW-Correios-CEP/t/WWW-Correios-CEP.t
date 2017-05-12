use utf8;

use Test::More tests => 3;
BEGIN { use_ok('WWW::Correios::CEP') }

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
