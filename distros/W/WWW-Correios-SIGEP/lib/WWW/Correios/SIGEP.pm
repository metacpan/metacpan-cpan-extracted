package WWW::Correios::SIGEP;
use strict;
use warnings;
use WWW::Correios::SIGEP::LogisticaReversa;
use WWW::Correios::SIGEP::Common;

our $VERSION = 0.03;

sub new {
    my ($class, $params) = @_;
    $params = {} unless $params && ref $params eq 'HASH';

    if ($params->{sandbox}) {
        $params->{target} = 'https://apphom.correios.com.br/SigepMasterJPA/AtendeClienteService/AtendeCliente?wsdl';
        # na sandbox, Correios nos instruem a ignorar configurações do cliente e usar essas:
        $params->{usuario}  = 'sigep';
        $params->{senha}    = 'n5f9t8';
        $params->{contrato} = '9992157880';
        $params->{cartao}   = '0067599079';

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
    return () unless $return && !ref $return;

    my ($i, $f) = map { s/\D+//g; $_ } split /\s*,\s*/ => $return;
    my $prefixo = substr $return, 0, 2;

    my @etiquetas;
    foreach my $codigo ($i .. $f) {
        push @etiquetas, $prefixo . $codigo . digito_verificador($codigo) . 'BR';
    }
    return @etiquetas;
}

sub fecha_plp_varios_servicos {
    my ($self, $params) = @_;
    die "fecha_plp_varios_servicos: parametros exigidos"
        unless ref $params eq 'HASH';

    my $xml;
    if (exists $params->{xml}) {
        $xml = $params->{xml};
    }
    else {
        $xml = $self->gera_xml_plp($params);
    }

    return WWW::Correios::SIGEP::Common::call(
        $self,
        'fechaPlpVariosServicos',
        {
            usuario        => $self->{usuario} || $params->{usuario},
            senha          => $self->{senha}   || $params->{senha},
            cartaoPostagem => $self->{cartao} || $params->{cartao},
            xml            => $xml,
            idPlpCliente   => $params->{id},
            listaEtiquetas => [
                map {
                    my $etq = $_->{etiqueta};
                    substr($etq, 10, 1, '');
                    $etq;
                } @{$params->{objetos}}
            ],
        }
    );
}

sub status_plp {
    my ($self, $id) = @_;
    die "status_plp: id da PLP exigido" unless defined $id;
    return WWW::Correios::SIGEP::Common::call(
        $self,
        'solicitaXmlPlp',
        {
            usuario     => $self->{usuario},
            senha       => $self->{senha},
            idPlpMaster => $id,
        }
    );
}

sub gera_xml_plp {
    my ($self, $params) = @_;

    #  I'm sorry, ubu.
    my $xml = '<?xml version="1.0" encoding="ISO-8859-1"?><correioslog><tipo_arquivo>Postagem</tipo_arquivo><versao_arquivo>2.3</versao_arquivo><plp><id_plp /><valor_global /><mcu_unidade_postagem/><nome_unidade_postagem/><cartao_postagem>'
    . ($params->{cartao} || $self->{cartao} || die "cartao de postagem exigido")
    . '</cartao_postagem></plp><remetente><numero_contrato>'
    . ($params->{contrato} || $self->{contrato} || die "contrato exigido")
    . '</numero_contrato><numero_diretoria>'
    . ($params->{diretoria} || die "diretoria exigido")
    . '</numero_diretoria><codigo_administrativo>'
    . ($params->{codigo_administrativo} || die "codigo_administrativo exigido")
    . '</codigo_administrativo><nome_remetente><![CDATA['
    . ($params->{remetente}{nome} || die "remetente.nome exigido")
    . ']]></nome_remetente><logradouro_remetente><![CDATA['
    . ($params->{remetente}{logradouro} || die "remetente.logradouro exigido")
    . ']]></logradouro_remetente><numero_remetente>'
    . ($params->{remetente}{numero} || die "remetente.numero exigido")
    . '</numero_remetente>'
    . (defined $params->{remetente}{complemento}
        ? '<complemento_remetente><![CDATA['
          . $params->{remetente}{complemento}
          . ']]></complemento_remetente>'
        : '<complemento_remetente />'
      )
    . '<bairro_remetente><![CDATA['
    . ($params->{remetente}{bairro} || die "remetente.bairro exigido")
    . ']]></bairro_remetente><cep_remetente>'
    . ($params->{remetente}{cep} =~ /\A\d{8}\z/ ? $params->{remetente}{cep} : die "remetente.cep (somente numeros) exigido")
    . '</cep_remetente><cidade_remetente><![CDATA['
    . ($params->{remetente}{cidade} || die "remetente.cidade exigido")
    . ']]></cidade_remetente><uf_remetente>'
    . uc($params->{remetente}{estado} || die "remetente.estado (sigla) exigido")
    . '</uf_remetente>'
    . (defined $params->{remetente}{telefone}
        ? '<telefone_remetente><![CDATA['
          . $params->{remetente}{telefone}
          . ']]></telefone_remetente>'
        : '<telefone_remetente />'
      )
    . (defined $params->{remetente}{fax}
        ? '<fax_remetente><![CDATA['
          . $params->{remetente}{fax}
          . ']]></fax_remetente>'
        : '<fax_remetente />'
      )
    . (defined $params->{remetente}{email}
        ? '<email_remetente><![CDATA['
          . $params->{remetente}{email}
          . ']]></email_remetente>'
        : '<email_remetente />'
      )
    . '</remetente><forma_pagamento />'
    ;

    die "objetos exigidos (ao menos 1)" unless @{$params->{objetos}} > 0;
    foreach my $obj (@{$params->{objetos}}) {
        if (defined $obj->{valor_declarado}) {
            if ($obj->{valor_declarado} =~ /\A(\d{1,9}),(\d{2})\z/) {
                my $valor_declarado = $1 + $2/100;
                if ($obj->{codigo_postagem_sigla} eq 'PAC') {
                    die "objetos[].valor_declarado (PAC) precisa ser entre 18,50 e 3000,00"
                        unless $valor_declarado >= 18.5 && $valor_declarado <= 3000;
                }
                elsif ($obj->{codigo_postagem_sigla} eq 'SEDEX') {
                    die "objetos[].valor_declarado (SEDEX) precisa ser entre 18,50 e 10000,00"
                        unless $valor_declarado >= 18.5 && $valor_declarado <= 10_000;
                }
                else {
                    die "objetos[].codigo_postagem_sigla precisa ser SEDEX, PAC ou CARTA"
                        unless $obj->{codigo_postagem_sigla} eq 'CARTA';
                }
            }
            else {
                die "objetos[].valor_declarado (formato NNNN,NN) invalido";
            }
        }
        $xml .= '<objeto_postal><numero_etiqueta>'
             . ($obj->{etiqueta} || die "objetos[].etiqueta exigido")
             . '</numero_etiqueta><codigo_objeto_cliente/><codigo_servico_postagem>'
             . ($obj->{codigo_postagem} || die "objetos[].codigo_postagem exigido")
             . '</codigo_servico_postagem><cubagem>0,00</cubagem><peso>'
             . ($obj->{peso} || die "objetos[].peso em gramas exigido")
             . '</peso><rt1/><rt2/><destinatario><nome_destinatario><![CDATA['
             . (substr($obj->{destinatario}{nome},0,50) || die "objetos[].destinatario.nome exigido")
             . ']]></nome_destinatario>'
             . (defined $obj->{destinatario}{telefone}
                 ? '<telefone_destinatario><![CDATA['
                   . $obj->{destinatario}{telefone}
                   . ']]></telefone_destinatario>'
                 : '<telefone_destinatario />'
               )
             . (defined $obj->{destinatario}{celular}
                 ? '<celular_destinatario><![CDATA['
                   . $obj->{destinatario}{celular}
                   . ']]></celular_destinatario>'
                 : '<celular_destinatario />'
               )
             . (defined $obj->{destinatario}{email}
                 ? '<email_destinatario><![CDATA['
                   . $obj->{destinatario}{email}
                   . ']]></email_destinatario>'
                 : '<email_destinatario />'
               )
             . '<logradouro_destinatario><![CDATA['
             . ($obj->{destinatario}{logradouro} || die "objetos[].destinatario.logradouro exigido")
             . ']]></logradouro_destinatario>'
             . (defined $obj->{destinatario}{complemento}
                 ? '<complemento_destinatario><![CDATA['
                   . $obj->{destinatario}{complemento}
                   . ']]></complemento_destinatario>'
                 : '<complemento_destinatario />'
             )
             . '<numero_end_destinatario>'
             . ($obj->{destinatario}{numero} || die "objetos[].destinatario.numero")
             . '</numero_end_destinatario></destinatario><nacional><bairro_destinatario><![CDATA['
             . ($obj->{destinatario}{bairro} || die "objetos[].destinatario.bairro exigido")
             . ']]></bairro_destinatario><cidade_destinatario><![CDATA['
             . ($obj->{destinatario}{cidade} || die "objetos[].destinatario.cidade exigido")
             . ']]></cidade_destinatario><uf_destinatario>'
             . (uc $obj->{destinatario}{uf} || die "objetos[].destinatario.uf exigido")
             . '</uf_destinatario><cep_destinatario><![CDATA['
             . ($obj->{destinatario}{cep} =~ /\A\d{8}\z/ ? $obj->{destinatario}{cep} : die "objetos[].destinatario.cep (somente numeros) exigido")
             . ']]></cep_destinatario>'
             . '<codigo_usuario_postal/><centro_custo_cliente/><numero_nota_fiscal/>'
             . '<serie_nota_fiscal/><valor_nota_fiscal/><natureza_nota_fiscal/>'
             . '<descricao_objeto/>'
             . '<valor_a_cobrar>0,0</valor_a_cobrar>'
             . '</nacional>'
             # 'O serviço adicional “025”, referente ao registro, deve sempre ser informado.'
             . '<servico_adicional><codigo_servico_adicional>025</codigo_servico_adicional>'
             . (exists $obj->{servicos_adicionais} && @{$obj->{servicos_adicionais}} > 0
                 ? join('' => map '<codigo_servico_adicional>' . $_ . '</codigo_servico_adicional>', @{$obj->{servicos_adicionais}})
                 : ''
               )
             . (defined $obj->{valor_declarado}
                ? '<codigo_servico_adicional>' . ($obj->{codigo_postagem_sigla} eq 'PAC'
                    ? '064' : $obj->{codigo_postagem_sigla} eq 'SEDEX' ? '019' : '035'
                  ) . '</codigo_servico_adicional><valor_declarado>' . $obj->{valor_declarado} . '</valor_declarado>'
                  : ''
             )
             . '</servico_adicional>'
             . '<dimensao_objeto><tipo_objeto>'
             . ($obj->{tipo} || die "objetos[].tipo (001, 002, 003) exigido")
             . '</tipo_objeto><dimensao_altura>'
             . ($obj->{altura} || '0')
             . '</dimensao_altura><dimensao_largura>'
             . ($obj->{largura} || '0')
             . '</dimensao_largura><dimensao_comprimento>'
             . ($obj->{comprimento} || '0')
             . '</dimensao_comprimento><dimensao_diametro>'
             . ($obj->{diametro} || '0')
             . '</dimensao_diametro></dimensao_objeto><data_postagem_sara/><status_processamento>0</status_processamento><numero_comprovante_postagem/><valor_cobrado/></objeto_postal>'
             ;
    }
    $xml .= '</correioslog>';
    return $xml;
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
    my @etiquetas = $correios->solicita_etiquetas(10);

    # gera Pré-lista de Postagem (PLP) de objetos:
    my $id_plp = $correios->fecha_plp_varios_servicos( \%dados_postagem );

    # consulta PLPs:
    my $res = $correios->status_plp( $id_plp );


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
L<API do SIGEP WEB|http://www.corporativo.correios.com.br/encomendas/sigepweb/doc/Manual_de_Implementacao_do_Web_Service_SIGEP_WEB.pdf>
e de L<Logística Reversa|http://www.corporativo.correios.com.br/encomendas/sigepweb/doc/Manual_de_Implementacao_do_Web_Service_SIGEPWEB_Logistica_Reversa.pdf>.

Vale notar que apenas os métodos listados abaixo estão implementados. Se você
deseja acesso a qualquer outro método descrito na API do SIGEP acima, favor
entrar em contato com o autor ou criar uma issue/pull request no GitHub.

=head1 IMPORTANTE: NECESSITA DE CONTRATO COM OS CORREIOS

Este módulo funciona como interface para o Web Service do Sistema Gerenciador
de Postagens (SIGEP) dos Correios, para organização de postagens contratadas.
Por isso, a maioria dos métodos desta B<< API exige contrato de prestação de
serviços firmado entre a sua empresa e os Correios >>.

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
O sistema dos Correios utiliza SOAP para comunicação com a API. Como a
compilação de XML é uma operação custosa (de processamento e memória),
por padrão as chamadas a este módulo são todas preguiçosas, ou seja, cada
operação é compilada na primeira vez em que é utilizada. Escolhemos essa
abordagem para evitar um tempo alto de inicialização (e maior quantidade de
memória utilizada) caso apenas uma ou outra operação seja de fato utilizada.
Se preferir, pode passar uma lista de operações nesse parâmetro para
pré-compilar. Assim, a inicialização do objeto demora um pouco mais, mas não
há penalidade durante a primeira execução da operação. Note que você precisará
utilizar o nome da operação em I<camelCase> conforme a documentação dos
Correios:

   precompile => [ 'solicitaEtiquetas' ]

Cada método abaixo inclui descrição do nome da chamada feita ao SIGEP WEB,
para eventual inclusão nessa lista ou depuração.

=back


=head2 busca_cliente()

=head2 busca_cliente( \%opcoes )

Método da API SIGEP: I<buscaCliente>

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

Método da API SIGEP: I<consultaCEP>

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

Método da API SIGEP: I<getStatusCartaoPostagem>

Consulta a API e retorna verdadeiro se o cartão ainda está válido, ou falso
caso contrário.

    if ( $sigep->cartao_valido ) {
        ...
    }

=head1 solicita_etiquetas( $cnpj, $id, $n_etiquetas )

Método da API SIGEP: I<solicitaEtiquetas>

    my $cnpj = '00000000000000';

    # 5 etiquetas para SEDEX com contrato (109811)
    # ATENÇÃO! Você quer o ID do serviço, não o código.
    my @etiquetas = $sigep->solicita_etiquetas( $cnpj, 109811, 5 );

Reserva e retorna uma lista de C<N> códigos de rastreamento (etiquetas)
para sua empresa. Ao contrário de uma chamada pura à API do SIGEP WEB,
os códigos são retornados já prontos para uso, B<com dígito verificador>.

I<< De nada. :) >>

=head1 fecha_plp_varios_servicos( \%params )

Método da API SIGEP: I<fechaPlpVariosServicos>

    my $id_plp = $sigep->fecha_plp_varios_servicos({
        id => 111111, # inventado pelo seu sistema, até 10 digitos (somente números)

        diretoria             => 10,  # obtido via busca_cliente()
        codigo_administrativo => 111, # obtido via busca_cliente()
        remetente => {
            nome => 'Minha Empresa LTDA',
            logradouro  => 'Minha Rua',
            numero      => 100,
            complemento => 302,  # opcional
            bairro      => 'Meu bairro',
            cep         => '111111222', # somente números
            cidade      => 'Minha Cidade',
            estado      => 'XX',
            telefone    => '', # opcional, somente números COM ddd
            fax         => '', # opcional, somente números COM ddd
            email       => '', # opcional
        },
        objetos => [
            # cada pacote vai numa estrutura separada
            {
                etiqueta => 'SS123456789BR', # obtida via solicita_etiquetas()
                codigo_postagem => '41068',  # obtido via busca_cliente()
                tipo => '001', # pode ser 001 (envelope), 002 (caixa) ou 003 (rolo)
                # envelope não precisa de medidas, mas se tipo for caixa (002)
                # você precisa informar "largura", "altura" e "comprimento".
                # Se tipo for rolo (003) você precisa informar "comprimento"
                # e "diametro". Todas as medidas são em centímetros.
                # ex: diametro => 4, comprimento => 10
                peso => 50, # em gramas
                valor_declarado => '50,00', # opcional
                # o servico adicional "25" (Registro Nacional) é obrigatório
                # em PLPs e portanto é sempre enviado. Outros servicos são:
                #   1 - aviso de recebimento
                #   2 - mão própria nacional
                #  19 - valor declarado nacional
                #  35 - carta registrada com valor declarado
                #  37 - aviso de recebimento digital
                #  47 - grandes formatos
                #  49 - devolução de nota fiscal - SEDEX
                #  57 - taxa de entrega de encomenda despadronizada
                #  67 - logística reversa simultânea domiciliária
                #  69 - logística reversa simultânea em agência
                # 107 - cobrança emergencial
                servicos_adicionais => [1,35], # opcionais
                destinatario => {
                    nome => 'Comprador Feliz da Silva',
                    logradouro => 'Rua da Entrega',
                    numero     => 1,
                    complemento => 'casa',  # opcional
                    bairro      => 'Bairro Feliz',
                    cidade      => 'Cidade Feliz',
                    uf          => 'ZZ',
                    cep         => '2222233',
                },
            },
        ],
    });

Use esse método para gerar a PLP associada à entrega de um ou mais objetos
postais. O valor retornado é o id da PLP gerada, que pode ser consultada
via C<status_plp()>.

Esse método gera automaticamente o XML a ser enviado para o SIGEP.
Se preferir gerar em duas etapas, por exemplo para validar o XML gerado
junto aos Correios, é só usar o método C<gera_xml_plp()>. De fato, a
chamada acima é exatamente igual a:

    my $xml = $sigep->gera_xml_plp({
        diretoria             => 10,
        codigo_administrativo => 111,
        remetente => {
            nome => 'Minha Empresa LTDA',
            logradouro  => 'Minha Rua',
            numero      => 100,
            complemento => 302,
            bairro      => 'Meu bairro',
            cep         => '111111222',
            cidade      => 'Minha Cidade',
            estado      => 'XX',
        },
        objetos => [
            {
                etiqueta => 'SS123456789BR',
                codigo_postagem => '41068',
                tipo => '001',
                peso => 50, # em gramas
                valor_declarado => '50,00',
                servicos_adicionais => [1,35],
                destinatario => {
                    nome => 'Comprador Feliz da Silva',
                    logradouro => 'Rua da Entrega',
                    numero     => 1,
                    complemento => 'casa',
                    bairro      => 'Bairro Feliz',
                    cidade      => 'Cidade Feliz',
                    uf          => 'ZZ',
                    cep         => '2222233',
                },
            },
        ],
    });

    my $id_plp = $sigep->fecha_plp_varios_servicos({
        id      => 111111,
        xml     => $xml,
        objetos => [{ etiqueta => 'SS123456789BR' }],
    });

=head1 status_plp( $id_plp )

Método da API SIGEP: I<solicitaXmlPlp>

    my $res = $sigep->status_plp( '1234' );

    if (exists $res->{SigepClienteException}) {
        print $res->{SigepClienteException}{reason};
    }
    else {
        # olhar status!
    }

Recebe o id da PLP (retornado por C<fecha_plp_varios_servicos()>) e consulta os
Correios sobre o status de envio. Naturalmente, só funciona para PLPs
criadas pelo próprio usuário. Se a PLP ainda não tiver sido processada pelos
Correios, você receberá uma mensagem de erro (veja exemplo acima para tratar).

=head1 servico_disponivel( \%opcoes )

Método da API SIGEP: I<verificaDisponibilidadeServico>

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
