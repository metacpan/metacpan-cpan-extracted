package WWW::Correios::SIGEP::LogisticaReversa;
use strict;
use warnings;
use WWW::Correios::SIGEP::Common;

sub new {
    my ($class, $params) = @_;
    $params = {} unless $params && ref $params eq 'HASH';

    if ($params->{sandbox}) {
        $params->{target} = 'http://webservicescolhomologacao.correios.com.br/ScolWeb/WebServiceScol?wsdl';
        $params->{wsdl_local_file} = 'sandbox/scol.wsdl';
    }
    else {
        $params->{target} = 'http://webservicescol.correios.com.br/ScolWeb/WebServiceScol?wsdl';
        $params->{wsdl_local_file} = 'live/scol.wsdl';
    }

    WWW::Correios::SIGEP::Common::build_transport($params);
    return bless $params, $class;
}

sub solicitar_postagem_reversa {
    my ($self, $params) = @_;

    return WWW::Correios::SIGEP::Common::call(
        $self,
        'solicitarPostagemReversa',
        +{
            usuario => $self->{usuario} || '',
            senha   => $self->{senha}   || '',
            %$params
        }
    );
}

sub cancelar_pedido {
    my ($self, $params) = @_;

    return WWW::Correios::SIGEP::Common::call(
        $self,
        'cancelarPedido',
        +{
            usuario => $self->{usuario} || '',
            senha   => $self->{senha}   || '',
            %$params
        }
    );
}

sub acompanhar_pedido {
    my ($self, $params) = @_;

    return WWW::Correios::SIGEP::Common::call(
        $self,
        'acompanharPedido',
        +{
            usuario => $self->{usuario} || '',
            senha   => $self->{senha}   || '',
            %$params
        }
    );
}

42;
__END__
=encoding utf-8

=head1 NAME

WWW::Correios::SIGEP::LogisticaReversa - API de Logística Reversa dos Correios (SIGEP WEB)

=head1 SYNOPSIS

usando diretamente:

    use WWW::Correios::SIGEP::LogisticaReversa;

    my $correios = WWW::Correios::SIGEP::LogisticaReversa->new({
        usuario => ...,
        senha   => ...,
    });

    my $res = $correios->solicitar_postagem_reversa( {...} );

    my $pedido = $res->{resultado_solicitacao}[0];
    die $pedido->{descricao_erro} if $pedido->{codigo_erro};

    say 'postagem reversa código ' . $pedido->{numero_coleta}
      . ' com validade até ' . $pedido->{prazo};

você também pode acessar esse módulo dinamicamente através do
L<WWW::Correios::SIGEP>:

    use WWW::Correios::SIGEP;

    my $correios = WWW::Correios::SIGEP->new( {...} );
    $correios->logistica_reversa->solicitar_postagem_reversa( {...} );

=head1 IMPORTANTE: NECESSITA DE CONTRATO COM OS CORREIOS

Este módulo funciona como interface para o Web Service de Logística Reversa
dos Correios, usado essencialmente para solicitar postagens reversas
(devoluções de produtos) pagas pela empresa solicitante. Para que isso faça
sentido, você precisa ter um contrato de prestação de serviços dos Correios.

Caso não tenha, entre em contato com os Correios para obter seu cartão de
parceria empresarial B<ANTES> de tentar usar esse módulo.

=head1 MÉTODOS

=head2 new( \%opcoes )

Cria o objeto cliente das requisições para o Web Service de Logística Reversa.
Aceita os seguintes parâmetros (parâmetros obrigatórios estão demarcados):

=over 4

=item * C<usuario> B<[OBRIGATÓRIO]>
Seu nome de usuário para o Web Service, conforme contrato com os Correios.
Se você não passar esse campo durante a inicialização do objeto, precisará
passar como valor em cada requisição (pode ser útil para gerir chamadas com
vários contratos diferentes a partir do mesmo objeto).

=item * C<senha> B<[OBRIGATÓRIO]>
Sua senha para o Web Service, conforme contrato com os Correios.
Se você não passar esse campo durante a inicialização do objeto, precisará
passar como valor em cada requisição (pode ser útil para gerir chamadas com
vários contratos diferentes a partir do mesmo objeto).

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

   precompile => [ 'solicitarPostagemReversa' ]

=back

=head2 solicitar_postagem_reversa( \%opcoes )

Este método processa o pedido de autorização de postagem ou coleta nos
Correios. Poderá ser efetuado até 50 solicitações simultâneas em uma única
chamada, sendo uma lista de coletas_solicitadas.

Consulte a documentação dos Correios para uma descrição de cada parâmetro,
e se são obrigatórios ou opcionais.

Um exemplo de requisição válida (que pode ser testada na sandbox):

    my $res = $correios->solicitar_postagem_reversa({
        usuario           => '60618043',
        senha             => '8o8otn',
        codAdministrativo => '08082650',
        contrato          => '9912208555',
        codigo_servico    => '41076',
        cartao            => '0057018901',
        destinatario      => {
            nome        => 'Museu de Arte Moderna',
            logradouro  => 'Av. Infante Dom Henrique',
            numero      => '85',
            complemento => '2o andar',
            bairro      => 'FLamengo',
            cep         => '20021140',
            cidade      => 'Rio de Janeiro',
            uf          => 'RJ',
            referencia  => 'dentro do Parque do Flamengo',
            ddd         => '21',
            telefone    => '2138835600',
            email       => 'sigepdestinatario@mailinator.com',
        },
        coletas_solicitadas => {
            id_cliente => '1234',
            remetente => {
                nome          => 'Inhotim',
                logradouro    => 'Rua B',
                numero        => '20',
                complemento   => 'Sala 10',
                bairro        => 'Centro',
                cep           => '35460000',
                cidade        => 'Brumadinho',
                uf            => 'MG',
                # email com número de postagem será enviado pelos Correios para:
                email         => 'sigepremetente@mailinator.com',,
            },
            tipo            => 'A',
            valor_declarado => '399',
            ag              => '10',
            ar              => 0,
            obj_col         => { item => 1 },
        }
    });

O valor de retorno, nesse caso, conterá uma estrutura na forma:

    $res = {
        cod_erro              => "00",
        data_processamento    => "20/10/2016",
        hora_processamento    => "17:41",
        msg_erro              => "",
        resultado_solicitacao => [
            {
                codigo_erro      => 0,
                data_solicitacao => "20/10/2016",
                descricao_erro   => "",
                hora_solicitacao => "17:41",
                id_cliente       => 1,
                numero_coleta    => "225319229",
                numero_etiqueta  => "",
                prazo            => "30/10/2016",
                status_objeto    => "01",
                tipo             => "A"
            }
        ]
    };

=head2 cancelar_pedido( \%opcoes )

Cancela um número de autorização de postagem que ainda não tenha sido
utilizado. Como exemplo, para cancelar o número solicitado no exemplo
de C<solicitar_postagem_reversa()>, faríamos algo como:

    my $res = $correios->cancelar_pedido({
        usuario           => '60618043',
        senha             => '8o8otn',
        codAdministrativo => '08082650',
        numeroPedido      => '225319229',
        tipo              => 'A',
    });

e a resposta seria na forma:

    $res = {
        codigo_administrativo => "8082650",
        objeto_postal         => {
            datahora_cancelamento => "22/10/2016 12:26",
            numero_pedido         => "225319229",
            status_pedido         => "Desistência do Cliente ECT"
        }
    }

=head2 acompanhar_pedido( \%opcoes )

Quando houver a postagem em uma unidade dos Correios, este método retornará o
número da etiqueta de registro através da chave C<numero_etiqueta>. Utilize
esse número para acompanhar o rastreamento do objeto. Exemplo:

    my $res = $correios->acompanhar_pedido({
        usuario           => '60618043',
        senha             => '8o8otn',
        codAdministrativo => '08082650',
        numeroPedido      => '225319229',
        tipoBusca         => 'H', # (H => todos, U => última)
        tipoSolicitacao   => 'A', # (A => autorização, C => coleta, L => domiciliar)
    });

Como neste exemplo passamos C<"H"> como tipo de busca, a resposta inclui todo
o histórico da solicitação, bem como o último status:

    $res = {
        codigo_administrativo => "8082650",
        coleta => [
            {
                controle_cliente => 1,
                historico        => [
                    {
                        data_atualizacao => "20-10-2016",
                        descricao_status => "Aguardando Objeto na Ag�ncia",
                        hora_atualizacao => "17:41:03",
                        observacao       => "",
                        status           => "55",
                    },
                    {
                        data_atualizacao => "22-10-2016",
                        descricao_status => "Desist�ncia do Cliente ECT",
                        hora_atualizacao => "12:26:31",
                        observacao       => "",
                        status           => 9
                    }
                ],
                numero_pedido => "225319229",
                objeto        => [
                    {
                        controle_objeto_cliente => "",
                        data_ultima_atualizacao => "20-10-2016",
                        descricao_status        => "Aguardando Objeto na Ag�ncia",
                        hora_ultima_atualizacao => "17:41:03",
                        numero_etiqueta         => "",
                        ultimo_status           => "55"
                    }
                ]
            }
        ],
        tipo_solicitacao => "A"
    }

B<Nota do autor:> Repare que na resposta acima os dados na chave C<historico>
estão mais atualizados do que os dados na chave C<objeto>. Pode ser apenas uma
questão do ambiente de homologação dos Correios. Por garantia, minha sugestão
é usar o C<tipoBusca> como C<"U"> e pegar o status da (única) ocorrência
retornada no C<historico>.

=head1 AGRADECIMENTOS

Este módulo não existiria sem a interface SIGEP WEB disponibilizada pelos Correios.

=head1 AUTOR

Breno G. de Oliveira  C<< <garu@cpan.org> >>

=head1 LICENÇA E COPYRIGHT

Copyright (c) 2016, Breno G. de Oliveira. Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou
modificá-lo sob os mesmos termos que o Perl. Veja L<perlartistic>.

B<< Este módulo não vem com nenhuma garantia. Use sob sua própria conta e risco. >>

=head1 VEJA TAMBÉM

L<WWW::Correios::SIGEP>
