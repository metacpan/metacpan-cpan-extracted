package WWW::Correios::SIGEP;
use strict;
use warnings;
use WWW::Correios::SIGEP::LogisticaReversa;

our $VERSION = 0.01;

sub new {
    my ($class, $params) = @_;
    $params = {} unless $params && ref $params eq 'HASH';

    if ($params->{sandbox}) {
        $params->{target} = 'https://apphom.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl';
        $params->{wsdl_local_file} = 'sandbox/atende_cliente.wsdl';
    }
    else {
        $params->{target} = 'https://apps.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl';
        $params->{wsdl_local_file} = 'live/atende_cliente.wsdl';
    }

    WWW::Correios::SIGEP::Common::build_transport($params);
    return bless $params, $class;
}

sub logistica_reversa {
    my ($self, $params) = @_;
    $params = {} unless $params && ref $params eq 'HASH';

    if (!$self->{scol_obj} || keys %$params) {
        $self->{scol_obj} = WWW::Correios::SIGEP::LogisticaReversa->new(+{
            debug   => $self->{debug},
            sandbox => $self->{sandbox},
            usuario => $self->{usuario},
            senha   => $self->{senha},
            %$params,
        });
    }
    return $self->{scol_obj};
}

sub busca_cliente {
    my ($self, $params) = @_;
    $params = {} unless $params && ref $params eq 'HASH';

    return WWW::Correios::SIGEP::Common::call($self, 'buscaCliente', {
        idContrato       => $self->{contrato} || $params->{idContrato},
        idCartaoPostagem => $self->{cartao}   || $params->{idCartaoPostagem},
        usuario          => $self->{usuario}  || $params->{usuario},
        senha            => $self->{senha}    || $params->{senha},
    });
}

sub consulta_cep {
    my ($self, $cep) = @_;
    $cep =~ s/\D//g;

    return WWW::Correios::SIGEP::Common::call($self, 'consultaCEP', {
        cep => $cep
    });
}

sub cartao_valido {
    my ($self, $params) = @_;
    $params = {} unless $params && ref $params eq 'HASH';

    my $return = WWW::Correios::SIGEP::Common::call(
        $self,
        'getStatusCartaoPostagem',
        {
            numeroCartaoPostagem => $self->{cartao}  || $params->{numeroCartaoPostagem},
            usuario              => $self->{usuario} || $params->{usuario},
            senha                => $self->{senha}   || $params->{senha},
        }
    );
    return $return eq 'Normal';
}

sub servico_disponivel {
    my ($self, $params) = @_;

    $params->{cep_origem}  =~ s/\D+//g;
    $params->{cep_destino} =~ s/\D+//g;

    return WWW::Correios::SIGEP::Common::call(
        $self,
        'verificaDisponibilidadeServico',
        {
            usuario           => $self->{usuario} || $params->{usuario},
            senha             => $self->{senha}   || $params->{senha},
            codAdministrativo => $self->{codigo}  || $params->{codigo},
            numeroServico     => $params->{codigo_servico},
            cepOrigem         => $params->{cep_origem},
            cepDestino        => $params->{cep_destino},
        }
    );
}

sub solicita_etiquetas {
    my ($self, $cnpj, $id, $n) = @_;

    my $return = WWW::Correios::SIGEP::Common::call($self, 'solicitaEtiquetas', {
        tipoDestinatario => 'C',
        identificador    => $cnpj,
        idServico        => $id,
        qtdEtiquetas     => $n,
        usuario          => $self->{usuario},
        senha            => $self->{senha}
    });

    my ($i, $f) = map { s/\D+//g; $_ } split /\s*,\s*/ => $return;
    my $prefixo = substr $return, 0, 2;

    my @etiquetas;
    foreach my $codigo ($i .. $f) {
        push @etiquetas, $prefixo . $codigo . digito_verificador($codigo) . 'BR';
    }
    return @etiquetas;
}

sub digito_verificador {
    my ($codigo) = @_;
    my @numeros = split // => $codigo;
    my @magica  = ( 8, 6, 4, 2, 3, 5, 9, 7 );

    my $soma = 0;
    foreach ( 0 .. 7 ) {
      $soma += ( $numeros[$_] * $magica[$_] );
    }

    my $resto = $soma % 11;
    my $dv = $resto == 0 ? 5
           : $resto == 1 ? 0
           : 11 - $resto
           ;

    return $dv;
}

1;
__END__
=encoding utf-8

=head1 NAME

WWW::Correios::SIGEP - API para o Gerenciador de Postagem dos Correios (SIGEP WEB)

=head1 SYNOPSIS

    use WWW::Correios::SIGEP;

    my $correios = WWW::Correios::SIGEP->new(
        codigo        => ..., # codigo administrativo
        identificador => ..., # CNPJ da empresa
        usuario       => ...,
        senha         => ...,
    );

    # consulta detalhes do cliente (serviços disponíveis, etc)
    my $cliente = $correios->busca_cliente(
        contrato        => ...,
        cartao_postagem => ...,
    );

    # consulta endereços por CEP
    my $cep = $correios->consulta_cep( '70002900' );
    say $cep->{cidade};
    say $cep->{endereco};

    # descobre se determinado serviço está disponível (e-SEDEX, etc)
    my $servico_disponivel = $correios->servico_disponivel(
        codigo_servico => '40215,81019',
        cep_origem     => '70002900',
        cep_destino    => '22241000',
    );

    # seu cartão de postagem ainda é válido?
    my $valido = $correios->cartao_valido( '1234567890' );

    # solicita uma ou mais etiquetas para postagem futura
    my @etiquetas = $correios->etiquetas(10);


=head1 DESCRIPTION

This module provides a way to query the Brazilian Postal Office (Correios)
SIGEP WEB Interface, an API to manage postal packages. Since the main target
for this module is Brazilian developers, the documentation is provided in
portuguese only. If you need help with this module please contact the author.

=head1 DESCRIÇÃO

Os Correios disponibilizam gratuitamente para todos os clientes com contrato
uma API para o sistema gerenciador de postagens SIGEP WEB, que permite a
automatização de serviços como Pré-lista de Postagem (PLP), rastreamento
de objetos, disponibilidade de serviços, SEDEX, logística reversa, entre
muitos outros.

Este módulo permite uma integação fácil e rápida entre seu produto e a 
L<API do SIGEP WEB|http://www.corporativo.correios.com.br/encomendas/sigepweb/doc/Manual_de_Implementacao_do_Web_Service_SIGEPWEB_Logistica_Reversa.pdf>.

Vale notar que apenas os métodos listados abaixo estão implementados. Se você
deseja acesso a qualquer outro método descrito na API do SIGEP acima, favor
entrar em contato com o autor ou criar uma issue/pull request no GitHub.

=head1 IMPORTANTE: NECESSITA DE CONTRATO COM OS CORREIOS

Este módulo funciona como interface para o Web Service do Sistema Gerenciador
de Postagens (SIGEP) dos Correios, para organização de postagens contratadas.
Por isso, a maioria dos métodos desta API exige contrato de prestação de
serviços firmado entre a sua empresa e os Correios.

Caso não tenha, entre em contato com os Correios para obter seu cartão de
parceria empresarial B<ANTES> de tentar usar esse módulo.

=head1 MÉTODOS

=head2 new( \%opcoes )

    my $sigep = WWW::Correios::SIGEP->new({
        usuario  => 'sigep',
        senha    => 'n5f9t8',
        codigo   => '08082650',
        contrato => '9912208555',
        cartao   => '0057018901',
    });

Cria o objeto cliente das requisições para o SIGEP WEB.
Aceita os seguintes parâmetros (parâmetros obrigatórios estão demarcados):

=over 4

=item * C<usuario> B<[OBRIGATÓRIO]>
Seu nome de usuário para o Web Service, conforme contrato com os Correios.
Se você não passar esse campo durante a inicialização do objeto, precisará
passar como valor em cada requisição que exija esse campo (pode ser útil
para gerir chamadas com vários contratos diferentes a partir do mesmo objeto).

=item * C<senha> B<[OBRIGATÓRIO]>
Sua senha para o Web Service, conforme contrato com os Correios.
Se você não passar esse campo durante a inicialização do objeto, precisará
passar como valor em cada requisição que exija esse campo (pode ser útil para
gerir chamadas com vários contratos diferentes a partir do mesmo objeto).

=item * C<contrato> B<OBRIGATÓRIO>
Número do seu contrato com os Correios. Se você não passar esse campo durante
a inicialização do objeto, precisará passar como valor da chave C<idContrato>
em todas as operações que exijam esse campo.

=item * C<cartao> B<OBRIGATÓRIO>
Número do seu cartão com os Correios. Se você não passar esse campo durante
a inicialização do objeto, precisará passar como valor da chave
C<idCartaoPostagem> em todas as operações que exigam esse campo.

=item * C<sandbox>
Se verdadeiro, utiliza os endpoints de sandbox dos Correios para todas as
chamadas. Utilize esse modo para testar chamadas e valores de resposta da API
sem gastar dinheiro ou consumir códigos reais. Note que você ainda precisará
passar todos os parâmetros (e eles serão validados da mesma forma). Em teoria,
após concluir sua homologação, basta remover essa flag e todas as chamadas
continuarão rigorosamente iguais - só que agora custando/valendo de verdade.

=item * C<debug>
Se verdadeiro, imprime no terminal detalhes do request, response e eventuais
erros associados ao envio/recebimento do envelope SOAP. Utilize essa flag para
depurar suas chamadas caso acredite que há algum problema na composição do
request ou na interpretação da resposta.

=item * C<timeout>
Timeout em segundos para as requisições à API dos Correios. Padrão 180
segundos (2 minutos).

=item * C<precompile>
por padrão, as chamadas a este módulo são todas preguiçosas, ou seja, cada
operação é compilada na primeira vez em que é utilizada. Escolhemos essa
abordagem para evitar um tempo alto de inicialização (e maior quantidade de
memória utilizada) caso apenas uma ou outra operação seja de fato utilizada.
Se preferir, pode passar uma lista de operações nesse parâmetro para
pré-compilar. Assim, a inicialização do objeto demora um pouco mais, mas não
há penalidade durante a primeira execução da operação. Note que você precisará
utilizar o nome da operação em I<camelCase> conforme a documentação dos
Correios:

   precompile => [ 'solicitaEtiquetas' ]

=back


=head2 busca_cliente()

=head2 busca_cliente( \%opcoes )

Retorna os serviços disponíveis para o cartão de postagem associado.

    my $cliente = $sigep->busca_cliente;

    say $cliente->{cnpj};

    # salvo casos raros, o importante desse método está aqui:
    my $servicos = $cliente->{contratos}[0]{cartoesPostagem}[0]{servicos};

    foreach my $servico ( @$servicos ) {
        my $id     = $servico->{id};
        my $codigo = $servico->{codigo};
        my $nome   = $servico->{descricao};
        my $jpeg   = $servico->{servicoSigep}{chancela}{chancela};
    }

O conteúdo da variável retornada possui a seguinte estrutura:

   $cliente = {
        dataAtualizacao        => '2014-12-18T14:01:09-02:00',
        datajAtualizacao       => 114352,
        descricaoStatusCliente => 'Ativo',
        horajAtualizacao       => 14109,
        id                     => 279311,
        inscricaoEstadual      => 'ISENTO',         # <-- ATENÇÃO! PODE CONTER ESPAÇOS!
        nome                   => 'ECT',            # <-- ATENÇÃO! PODE CONTER ESPAÇOS!
        cnpj                   => '34028316000103', # <-- ATENÇÃO! PODE CONTER ESPAÇOS!
        statusCodigo           => 1,

        contratos => [
            {
                codigoCliente              => 279311,
                codigoDiretoria            => 10,
                dataAtualizacao            => '2014-11-19T09:50:29-02:00',
                dataAtualizacaoDDMMYYYY    => '',
                datajAtualizacao           => 114323,
                datajVigenciaFim           => 118136,
                datajVigenciaInicio        => 108137,
                dataVigenciaFim            => '2018-05-16T00:00:00-03:00',
                dataVigenciaFimDDMMYYYY    => '',
                dataVigenciaInicio         => '2008-05-16T00:00:00-03:00',
                dataVigenciaInicioDDMMYYYY => '',
                descricaoDiretoriaRegional => 'DR - BRASÍLIA', # <-- ATENÇÃO! ESPAÇOS!
                horajAtualizacao           => 95029,
                statusCodigo               => 'A',

                contratoPK => {
                    diretoria => 10,
                    numero    => 9912208555,
                },

                cartoesPostagem => [
                    {
                        codigoAdministrativo => 08082650,
                        dataAtualizacao      => '2014-12-19T14:46:33-02:00',
                        datajAtualizacao     => 114353,
                        datajVigenciaFim     => 118136,
                        datajVigenciaInicio  => 114129,
                        dataVigenciaFim      => '2018-05-16T00:00:00-03:00',
                        dataVigenciaInicio   => '2014-05-09T00:00:00-03:00',
                        horajAtualizacao     => 144633,
                        numero               => 0057018901,
                        statusCartaoPostagem => 01,
                        statusCodigo         => 'A',
                        unidadeGenerica      => 08,

                        # esse parece ser o único array de verdade
                        servicos => [
                            {
                                codigo             => 40215,
                                dataAtualizacao    => '2014-05-05T13:47:35-03:00',
                                datajAtualizacao   => 114125,
                                descricao          => "SEDEX 10", <-- ATENÇAO! ESPAÇOS!
                                horajAtualizacao   => 134735,
                                id                 => 104707,
                                servicosAdicionais => [ {} ],
                                tipo1Codigo          "CNV",
                                tipo2Codigo          "A",

                                vigencia => {
                                    dataFinal   => '2040-12-31T00:00:00-02:00',
                                    dataInicial => '2001-06-10T00:00:00-03:00',
                                    datajFim    => 140366,
                                    datajIni    => 101161,
                                    id          => 104707
                                }

                                servicoSigep => {
                                    categoriaServico  => 'SERVICO_COM_RESTRICAO',
                                    exigeDimensoes    => 0,
                                    exigeValorCobrar  => 0,
                                    imitm             => 104707,
                                    servico           => 104707,
                                    ssiCoCodigoPostal => 275,

                                    chancela => {
                                        chancela        => (imagem JPEG em binário),
                                        dataAtualizacao => '2013-05-03T00:00:00-03:00',
                                        descricao       => '(104707) SEDEX 10-D',
                                        id              => 20
                                    },
                                },
                            },
                        ],
                    },
                ],
            },
        ],
   };

B<Nota do autor:> Não encontramos documentação a respeito dos parâmetros acima.
Os Correios sugerem que apenas os campos C<id> e C<codigo> são relevantes.

Note também que muitos campos vêm com espaços extras no final.
Certifique-se de remover espaços se for utilizá-los em seu código.

=head1 consulta_cep( $cep )

Retorna o endereço atualizado da base dos Correios.
B<Este método não exige contrato e pode ser acessado sem usuário/senha>.

    my $dados = $sigep->consulta_cep( '70002900' );  # com ou sem traço

    say $dados->{bairro}

O conteúdo da variável retornada possui a seguinte estrutura:

    $dados = {
        bairro       => "Asa Norte",
        cep          => 70002900,
        cidade       => "Brasília",
        complemento  => "",
        complemento2 => "",
        end          => "SBN Quadra 1 Bloco A",
        id           => 0,
        uf           => "DF"
    };

=head1 cartao_valido()

=head1 cartao_valido( \%opcoes )

Consulta a API e retorna verdadeiro se o cartão ainda está válido, ou falso
caso contrário.

    if ( $sigep->cartao_valido ) {
        ...
    }

=head1 solicita_etiquetas( $cnpj, $id, $n_etiquetas )

    my $cnpj = '00000000000000';

    # 5 etiquetas para SEDEX com contrato (109811)
    my @etiquetas = $sigep->solicita_etiquetas( $cnpj, 109811, 5 );

Reserva e retorna uma lista de C<N> códigos de rastreamento (etiquetas)
para sua empresa. Ao contrário de uma chamada pura à API do SIGEP WEB,
os códigos são retornados já prontos para uso, B<com dígito verificador>.

I<< De nada. :) >>

=head1 servico_disponivel( \%opcoes )

Recebe um hashref com o codigo do serviço e os CEPs de origem e destino.

Retorna verdadeiro se o serviço solicitado está disponível para essa origem
e destino, ou falso caso contrário.

    my $opcoes = {
        codigo_servico => '40290',    # "SEDEX HOJE"
        cep_origem     => '22241000',
        cep_destino    => '70002900',

        # caso não tenha passado durante a inicializacao do objeto:
        # usuario => ...
        # senha   => ...
        # codigo  => ...
    };

    if ( $sigep->servico_disponivel($opcoes) ) {
        ...
    }

Nota: o código do serviço pode ser um código único ou mais de um, em uma
string separada por vírgulas (ex: C<"40290,41068">). Nesse caso, o valor
retornado pelos Correios será verdadeiro se I<pelo menos um> dos serviços
estiver disponível, sem dizer qual.

=head2 logistica_reversa

=head2 logistica_reversa( \%opcoes )

Este método auxiliar retorna o objeto L<WWW::Correios::SIGEP::LogisticaReversa>
criado automaticamente a partir das informações de usuario/senha/debug/sandbox
do objeto que o invocou. Note que esse objeto só será criado no momento em que
o método for invocado pela primeira vez, B<OU> em chamadas futuras que incluam
opções de inicialização (que, obviamente, sobrescreverão qualquer opção padrão)
do módulo pai.

=head1 CONFIGURAÇÃO E VARIÁVEIS DE AMBIENTE

WWW::Correios::SIGEP não precisa de qualquer arquivo de configuraçào
ou variável de ambiente.

=head1 BUGS E LIMITAÇÕES

Por favor entre em contato sobre qualquer bug ou pedido de feature em:
L<https://github.com/garu/WWW-Correios-SIGEP/issues>.

=head1 VEJA TAMBÉM

=over 4

=item L<WWW::Correios::SRO>
Interface para o Serviço de Rastreamento de Objetos (SRO).

=item L<WWW::Correios::CEP>
Interface para consulta de CEP.

=item L<WWW::Correios::PrecoPrazo>
Interface para consulta de preços de prazos (frete).

=item L<Business::BR::CEP>
Interface para validação de números de CEP.

=item L<Geo::CEP>
Interface para geolocalização de números de CEP.

=back

=head1 AGRADECIMENTOS

Este módulo não existiria sem a interface SIGEP WEB disponibilizada pelos Correios.

=head1 AUTOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>

=head1 LICENÇA E COPYRIGHT

Copyright (c) 2016, Breno G. de Oliveira. Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou
modificá-lo sob os mesmos termos que o Perl. Veja L<perlartistic>.

B<< Este módulo não vem com nenhuma garantia. Use sob sua própria conta e risco. >>

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
