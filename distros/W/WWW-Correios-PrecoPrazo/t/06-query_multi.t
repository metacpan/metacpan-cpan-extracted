#!perl

use Test::More tests => 13;
use strict;
use warnings;

package HTTP::Response::Mock;
sub new     { bless {}, 'HTTP::Response::Mock' }

sub content {
    return <<'EOXML';
<?xml version="1.0" encoding="ISO-8859-1" ?>
<Servicos><cServico><Codigo>81019</Codigo><Valor>8,94</Valor><PrazoEntrega>1</PrazoEntrega><ValorSemAdicionais>8,94</ValorSemAdicionais><ValorMaoPropria>0,01</ValorMaoPropria><ValorAvisoRecebimento>0,02</ValorAvisoRecebimento><ValorValorDeclarado>0,03</ValorValorDeclarado><EntregaDomiciliar>S</EntregaDomiciliar><EntregaSabado>S</EntregaSabado><Erro>0</Erro><MsgErro></MsgErro></cServico><cServico><Codigo>41106</Codigo><Valor>15,50</Valor><PrazoEntrega>4</PrazoEntrega><ValorSemAdicionais>15,50</ValorSemAdicionais><ValorMaoPropria>0,04</ValorMaoPropria><ValorAvisoRecebimento>0,05</ValorAvisoRecebimento><ValorValorDeclarado>0,06</ValorValorDeclarado><EntregaDomiciliar>S</EntregaDomiciliar><EntregaSabado>N</EntregaSabado><Erro>0</Erro><MsgErro></MsgErro></cServico></Servicos>
EOXML
}


package LWP::Mock;
sub new { bless {}, 'LWP::Mock' }
sub get { return HTTP::Response::Mock->new }

package main;

use WWW::Correios::PrecoPrazo;

ok my $cpp = WWW::Correios::PrecoPrazo->new( { user_agent => LWP::Mock->new } ),
    'modulo carregado';

is_deeply(
    $cpp->query_multi,
    [{}],
    'Query multi vazia'
);

is_deeply(
    $cpp->query_multi( formato => 'caixa' ),
    [{}],
    'Query multi recebendo Hash'
);

is_deeply(
    $cpp->query_multi( { formato => 'caixa' } ),
    [{}],
    'Query multi recebendo HashRef'
);

is_deeply(
    $cpp->query_multi( { formato => 'Batata Baroa' } ),
    [{}],
    'Formato inválido para query multi'
);

my %query = (
    cep_origem     => '22222-222',
    cep_destino    => '11111-111',
    codigo_servico => 1,
);

ok my $res = $cpp->query_multi( %query ), 'query multi retornou';
is ref $res, 'ARRAY', 'query multi retornou arrayref';
is $res->[0]{Codigo}, '81019', 'query multi parser (0)';
is $res->[1]{Codigo}, '41106', 'query multi parser (1)';

ok $res = $cpp->query_multi( \%query ), 'query multi retornou (hashref)';
is ref $res, 'ARRAY', 'query multi retornou arrayref (hashref)';
is $res->[0]{Codigo}, '81019', 'query multi parser (0) (hashref)';
is $res->[1]{Codigo}, '41106', 'query multi parser (1) (hashref)';



