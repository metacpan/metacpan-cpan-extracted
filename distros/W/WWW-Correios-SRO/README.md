WWW::Correios::SRO
==================

### Serviço de Rastreamento de Objetos (Brazilian Postal Object Tracking Service).

[português] Este módulo oferece uma interface com o serviço de rastreamento de objetos dos Correios. Até a data de publicação deste módulo não há uma API pública dos Correios para isso, então este módulo consulta o site dos Correios diretamente e faz parsing dos resultados. Sim, isso significa que mudanças no layout do site dos Correios podem afetar o funcionamento deste módulo. Até os Correios lançarem o serviço via API, isso é o que temos.

[english] This module provides an interface to the Brazilian Postal (Correios) object tracking service. Until the date of release of this module there was no public API to achieve this, so this module queries the Correios website directly and parses its results. Yup, this means any layout changes on their website could affect the correctness of this module. Until Correios releases an API for this service, that's all we can do.

```perl
    use WWW::Correios::SRO qw( sro sro_ok );

    my $codigo = 'SS123456789BR';  # insira seu código de rastreamento aqui

    return 'SRO inválido' unless sro_ok( $codigo );

    my $prefixo = sro_sigla( $codigo ); # retorna "SEDEX FÍSICO";

    my @historico_completo = sro( $codigo );

    my $ultimo = sro( $codigo );

    $ultimo->data;    # '22/05/2010 12:10'
    $ultimo->local;   # 'CEE JACAREPAGUA - RIO DE JANEIRO/RJ'
    $ultimo->status;  # 'Destinatário ausente'
    $ultimo->extra;   # 'Será realizada uma nova tentativa de entrega'
```

Installation:
-------------

    cpanm WWW::Correios::SRO


Looking for more documentation? [Try here](https://metacpan.org/pod/WWW::Correios::SRO)

Procurando mais documentação? [Tente aqui](https://metacpan.org/pod/WWW::Correios::SRO)

