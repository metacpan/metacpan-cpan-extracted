use strict;
use warnings;
use Test::More tests => 12;
use WWW::Correios::PrecoPrazo;

package HTTPResponseMock;

sub new { bless {}, shift }

sub content {
    return <<'EOXML';
<?xml version="1.0" encoding="ISO-8859-1" ?>
<Servicos><cServico><Codigo>41106</Codigo><Valor>3,00</Valor><PrazoEntrega>1</PrazoEntrega><ValorSemAdicionais>0,03</ValorSemAdicionais><ValorMaoPropria>0,20</ValorMaoPropria><ValorAvisoRecebimento>5,43</ValorAvisoRecebimento><ValorValorDeclarado>1,00</ValorValorDeclarado><EntregaDomiciliar></EntregaDomiciliar><EntregaSabado></EntregaSabado><Erro>-22</Erro><MsgErro><![CDATA[O comprimento nao pode ser inferior a 16 cm.]]></MsgErro></cServico></Servicos>
EOXML
}

package main;

my $mock = HTTPResponseMock->new;

my $data = WWW::Correios::PrecoPrazo::_parse_response( $mock );

$data = $data->[0];

is_deeply(
    [ sort keys %$data ],
    [ qw( Codigo EntregaDomiciliar EntregaSabado Erro MsgErro PrazoEntrega
          Valor ValorAvisoRecebimento ValorMaoPropria ValorSemAdicionais
          ValorValorDeclarado )
    ],
    'resposta tem as chaves corretas'
);

is $data->{Codigo}, 41106, 'codigo';
is $data->{EntregaDomiciliar}, '', 'entrega domiciliar';
is $data->{EntregaSabado}, '', 'entrega sabado';
is $data->{Erro}, -22, 'codigo de erro';
is(
    $data->{MsgErro},
    'O comprimento nao pode ser inferior a 16 cm.',
    'mensagem de erro'
);
is $data->{PrazoEntrega}, 1, 'prazo de entrega';
is $data->{Valor}, '3,00', 'valor';
is $data->{ValorAvisoRecebimento}, '5,43', 'valor aviso recebimento';
is $data->{ValorMaoPropria}, '0,20', 'valor mao propria';
is $data->{ValorSemAdicionais}, '0,03', 'valor sem adicionais';
is $data->{ValorValorDeclarado}, '1,00', 'valor declarado';


