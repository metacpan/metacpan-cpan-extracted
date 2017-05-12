use strict;
use warnings;
use Test::More tests => 2;
use WWW::Correios::PrecoPrazo;

package HTTPResponseMock;

sub new { bless {}, shift }

sub content {
    return <<'EOXML';
<?xml version="1.0" encoding="ISO-8859-1" ?>
<Servicos><cServico><Codigo>81019</Codigo><Valor>8,94</Valor><PrazoEntrega>1</PrazoEntrega><ValorSemAdicionais>8,94</ValorSemAdicionais><ValorMaoPropria>0,01</ValorMaoPropria><ValorAvisoRecebimento>0,02</ValorAvisoRecebimento><ValorValorDeclarado>0,03</ValorValorDeclarado><EntregaDomiciliar>S</EntregaDomiciliar><EntregaSabado>S</EntregaSabado><Erro>0</Erro><MsgErro></MsgErro></cServico><cServico><Codigo>41106</Codigo><Valor>15,50</Valor><PrazoEntrega>4</PrazoEntrega><ValorSemAdicionais>15,50</ValorSemAdicionais><ValorMaoPropria>0,04</ValorMaoPropria><ValorAvisoRecebimento>0,05</ValorAvisoRecebimento><ValorValorDeclarado>0,06</ValorValorDeclarado><EntregaDomiciliar>S</EntregaDomiciliar><EntregaSabado>N</EntregaSabado><Erro>0</Erro><MsgErro></MsgErro></cServico></Servicos>
EOXML
}

package main;

my $mock = HTTPResponseMock->new;

my $data = WWW::Correios::PrecoPrazo::_parse_response( $mock );

subtest 'primeira resposta' => sub {
    plan tests => 12;

    is_deeply(
        [ sort keys %{$data->[0]} ],
        [ qw( Codigo EntregaDomiciliar EntregaSabado Erro MsgErro PrazoEntrega
            Valor ValorAvisoRecebimento ValorMaoPropria ValorSemAdicionais
            ValorValorDeclarado )
        ],
        'resposta tem as chaves corretas'
    );

    is $data->[0]{Codigo}, 81019, 'codigo';
    is $data->[0]{EntregaDomiciliar}, 'S', 'entrega domiciliar';
    is $data->[0]{EntregaSabado}, 'S', 'entrega sabado';
    is $data->[0]{Erro}, 0, 'codigo de erro';
    is $data->[0]{MsgErro}, undef, 'mensagem de erro';
    is $data->[0]{PrazoEntrega}, 1, 'prazo de entrega';
    is $data->[0]{Valor}, '8,94', 'valor';
    is $data->[0]{ValorAvisoRecebimento}, '0,02', 'valor aviso recebimento';
    is $data->[0]{ValorMaoPropria}, '0,01', 'valor mao propria';
    is $data->[0]{ValorSemAdicionais}, '8,94', 'valor sem adicionais';
    is $data->[0]{ValorValorDeclarado}, '0,03', 'valor declarado';
};

subtest 'segunda resposta' => sub {
    plan tests => 12;

    is_deeply(
        [ sort keys %{$data->[1]} ],
        [ qw( Codigo EntregaDomiciliar EntregaSabado Erro MsgErro PrazoEntrega
            Valor ValorAvisoRecebimento ValorMaoPropria ValorSemAdicionais
            ValorValorDeclarado )
        ],
        'resposta tem as chaves corretas'
    );

    is $data->[1]{Codigo}, 41106, 'codigo';
    is $data->[1]{EntregaDomiciliar}, 'S', 'entrega domiciliar';
    is $data->[1]{EntregaSabado}, 'N', 'entrega sabado';
    is $data->[1]{Erro}, 0, 'codigo de erro';
    is $data->[1]{MsgErro}, undef, 'mensagem de erro';
    is $data->[1]{PrazoEntrega}, 4, 'prazo de entrega';
    is $data->[1]{Valor}, '15,50', 'valor';
    is $data->[1]{ValorAvisoRecebimento}, '0,05', 'valor aviso recebimento';
    is $data->[1]{ValorMaoPropria}, '0,04', 'valor mao propria';
    is $data->[1]{ValorSemAdicionais}, '15,50', 'valor sem adicionais';
    is $data->[1]{ValorValorDeclarado}, '0,06', 'valor declarado';
};


