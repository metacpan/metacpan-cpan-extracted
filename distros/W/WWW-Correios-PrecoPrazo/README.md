WWW-Correios-PrecoPrazo
=======================

[![Build status](https://api.travis-ci.org/garu/WWW-Correios-PrecoPrazo.png)](https://api.travis-ci.org/garu/WWW-Correios-PrecoPrazo.png)
[![Coverage Status](https://coveralls.io/repos/garu/WWW-Correios-PrecoPrazo/badge.png)](https://coveralls.io/r/garu/WWW-Correios-PrecoPrazo)
[![CPAN version](https://badge.fury.io/pl/WWW-Correios-PrecoPrazo.png)](http://badge.fury.io/pl/WWW-Correios-PrecoPrazo)

Os Correios oferecem uma API destinada a qualquer um que deseje calcular,
de forma personalizada, o preço e o prazo de entrega de uma encomenda.

Os preços apresentados são os mesmos praticados no balcão da agência, a menos
que você possua contrato de SEDEX, e-SEDEX ou PAC. Nesses casos, você pode
informar código da empresa e senha e solicitar consultas com contrato.

Este módulo visa ser extremamente leve a fim de não introduzir dependências
extras em sua aplicação. Você pode adequá-lo ao seu ambiente e suas necessidades
através da injeção de dependências (I<dependency injection>) durante a criação
do objeto.

A documentação completa sobre o webservice dos Correios pode ser encontrada em
http://www.correios.com.br/para-voce/correios-de-a-a-z/pdf/calculador-remoto-de-precos-e-prazos/manual-de-implementacao-do-calculo-remoto-de-precos-e-prazos

#### Instalação ####

    cpanm WWW::Correios::PrecoPrazo

#### Saiba mais ####

Para exemplos, lista de métodos e detalhes de uso, por favor
consulte a [documentação completa do WWW::Correios::PrecoPrazo](https://metacpan.org/module/WWW::Correios::PrecoPrazo).


#### COPYRIGHT & LICENCE ####

Copyright (C) 2011-2015, Breno G. de Oliveira, Blabos de Blebe.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
