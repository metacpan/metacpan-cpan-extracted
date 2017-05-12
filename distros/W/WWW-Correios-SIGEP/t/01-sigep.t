use strict;
use warnings;
use Test::More tests => 39;

use WWW::Correios::SIGEP;

can_ok 'WWW::Correios::SIGEP', qw(new digito_verificador);

is WWW::Correios::SIGEP::digito_verificador('74668653'), 6, '6 verifica 74668653';
is WWW::Correios::SIGEP::digito_verificador('76023727'), 2, '2 verifica 76023727';

ok my $sandbox = WWW::Correios::SIGEP->new({
    sandbox => 1,
    debug   => 1,
}), 'new object instantiated (sandbox)';

isa_ok $sandbox, 'WWW::Correios::SIGEP';
is ref $sandbox->{transport}, 'CODE', 'transport created for sandbox';
isa_ok $sandbox->{wsdl}, 'XML::Compile::WSDL11';

ok $sandbox->{sandbox}, 'we are in sandbox mode';
ok $sandbox->{debug}, 'we are in debug mode';
is $sandbox->{target}, 'https://apphom.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl', 'proper target for sandbox';
is $sandbox->{wsdl_local_file}, 'sandbox/atende_cliente.wsdl', 'proper sandbox local file';

ok my $live = WWW::Correios::SIGEP->new, 'new object instantiated';

isa_ok $live, 'WWW::Correios::SIGEP';
is ref $live->{transport}, 'CODE', 'transport created for live';
isa_ok $live->{wsdl}, 'XML::Compile::WSDL11';

ok !$live->{sandbox}, 'we are NOT in sandbox mode';
ok !$live->{debug}, 'we are NOT in debug mode';
is $live->{target}, 'https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl', 'proper target for live';
is $live->{wsdl_local_file}, 'live/atende_cliente.wsdl', 'proper live local file';

can_ok $live, qw(
    logistica_reversa
    busca_cliente
    consulta_cep
    cartao_valido
    servico_disponivel
    solicita_etiquetas
    digito_verificador
);

## WWW::Correios::SIGEP::LogisticaReversa
ok my $scol_sandbox = $sandbox->logistica_reversa, 'got scol object for sandbox';
isa_ok $scol_sandbox, 'WWW::Correios::SIGEP::LogisticaReversa';
ok $scol_sandbox->{sandbox}, 'scol: we are in sandbox mode';
ok $scol_sandbox->{debug}, 'scol: we are in debug mode';
is $scol_sandbox->{target}, 'http://webservicescolhomologacao.correios.com.br/ScolWeb/WebServiceScol?wsdl', 'scol target for sandbox';
is $scol_sandbox->{wsdl_local_file}, 'sandbox/scol.wsdl', 'sandbox scol local file';

ok my $scol_live = $live->logistica_reversa, 'got scol object for live';
isa_ok $scol_live, 'WWW::Correios::SIGEP::LogisticaReversa';
ok !$scol_live->{sandbox}, 'scol: we are NOT in sandbox mode';
ok !$scol_live->{debug}, 'scol: we are NOT in debug mode';
is $scol_live->{target}, 'http://webservicescol.correios.com.br/ScolWeb/WebServiceScol?wsdl', 'proper scol target for live';
is $scol_live->{wsdl_local_file}, 'live/scol.wsdl', 'proper live scol local file';

can_ok $scol_live, qw(
    solicitar_postagem_reversa
    cancelar_pedido
    acompanhar_pedido
);

ok my $scol_live_override = $live->logistica_reversa({ sandbox => 1 }), 'got scol object for override';
isa_ok $scol_live_override, 'WWW::Correios::SIGEP::LogisticaReversa';
ok $scol_live_override->{sandbox}, 'scol: override to sandbox mode';
ok !$scol_live_override->{debug}, 'scol: we are still NOT in debug mode';
is $scol_live_override->{target}, 'http://webservicescolhomologacao.correios.com.br/ScolWeb/WebServiceScol?wsdl', 'overriden scol target for live is now sandbox';
is $scol_live_override->{wsdl_local_file}, 'sandbox/scol.wsdl', 'overriden live scol local file';


