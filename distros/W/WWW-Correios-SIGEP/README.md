## WWW::Correios::SIGEP ##

Os Correios disponibilizam gratuitamente para todos os clientes com contrato
uma API para o sistema gerenciador de postagens SIGEP WEB, que permite a
automatização de serviços como Pré-lista de Postagem (PLP), rastreamento
de objetos, disponibilidade de serviços, SEDEX, logística reversa, entre
muitos outros.

Este módulo permite uma integação fácil e rápida entre seu produto e a 
[API do SIGEP WEB](http://www.corporativo.correios.com.br/encomendas/sigepweb/doc/Manual_de_Implementacao_do_Web_Service_SIGEPWEB_Logistica_Reversa.pdf).

```perl
use WWW::Correios::SIGEP;

my $correios = WWW::Correios::SIGEP->new(
    usuario => ...,
    senha   => ...,
);

# consulta endereços por CEP
my $cep = $correios->consulta_cep( '70002900' );
say $cep->{cidade};
say $cep->{endereco};

# solicita uma ou mais etiquetas para postagem futura
my @etiquetas = $correios->etiquetas(10);

# solicita serviço de postagem reversa
my $reversa = $correios->logistica_reversa->solicitar_postagem_reversa( {...} );
say 'postagem reversa código: '
  . $reversa->{resultado_solicitacao}[0]{numero_coleta};

# entre várias outras chamadas disponíveis
```

Para mais chamadas e exemplos, consulte a [documentação completa do WWW::Correios::SIGEP](https://metacpan.org/pod/WWW::Correios::SIGEP).

### IMPORTANTE: NECESSITA DE CONTRATO COM OS CORREIOS ###

Este módulo funciona como interface para o Web Service do Sistema Gerenciador
de Postagens (SIGEP) dos Correios, para organização de postagens contratadas.
Por isso, a maioria dos métodos desta API exige contrato de prestação de
serviços firmado entre a sua empresa e os Correios.

Caso não tenha, entre em contato com os Correios para obter seu cartão de
parceria empresarial *ANTES* de tentar usar esse módulo.


### Instalação ###

    # do CPAN
    $ cpan WWW::Correios::SIGEP

    # do cpanm
    $ cpanm WWW::Correios::SIGEP

    # clonando o repositório
    $ git clone git://github.com/garu/WWW-Correios-SIGEP.git

    # instalação manual, após o download
    perl Makefile.PL
    make && make test && make install

### Autor ###

Breno G. de Oliveira

### LICENÇA E COPYRIGHT ###

Copyright (c) 2016-2021, Breno G. de Oliveira. Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou
modificá-lo sob os mesmos termos que o Perl. Veja L<perlartistic>.

*Este módulo não vem com nenhuma garantia. Use sob sua própria conta e risco.*


