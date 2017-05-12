package WWW::Correios::SRO::Item;
use Class::XSAccessor::Array {
    constructor => 'new',
    accessors  => {
        'data'     => 0,
        'date'     => 0,
        'location' => 1,
        'local'    => 1,
        'status'   => 2,
        'extra'    => 3,
    },
};

package WWW::Correios::SRO;

use strict;
use warnings;

use LWP::UserAgent;
use HTML::TreeBuilder;

use parent 'Exporter';
our @EXPORT_OK = qw( sro sro_en sro_ok sro_sigla );

our $VERSION = '0.10';
my $AGENT = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';
my $TIMEOUT = 30;

# Verificado em 14 de Setembro de 2014 em  
# http://www.correios.com.br/para-voce/precisa-de-ajuda/como-rastrear-um-objeto/siglas-utilizadas-no-rastreamento-de-objeto
#
#
# Sabemos que as seguintes siglas são usadas: DM, DH, JH, PE 
# Como não existem na tabela dos correios, nao se encontra na
# hash.
# Um código com esse prefixo funcionará ao usar a funcao sro sem
# passar o parametro verifica_prefixo. Porém, se passar este
# parametro, deve retornar undef como qualquer SRO
# cujo prefixo não está previsto na tabela dos Correios.
my %siglas = (
  AL => 'AGENTES DE LEITURA',
  AR => 'AVISO DE RECEBIMENTO',
  AS => 'ENCOMENDA PAC – AÇÃO SOCIAL',
  CA => 'OBJETO INTERNACIONAL',
  CB => 'OBJETO INTERNACIONAL',
  CC => 'COLIS POSTAUX',
  CD => 'OBJETO INTERNACIONAL',
  CE => 'OBJETO INTERNACIONAL',
  CF => 'OBJETO INTERNACIONAL',
  CG => 'OBJETO INTERNACIONAL',
  CH => 'OBJETO INTERNACIONAL',
  CI => 'OBJETO INTERNACIONAL',
  CJ => 'REGISTRADO INTERNACIONAL',
  CK => 'OBJETO INTERNACIONAL',
  CL => 'OBJETO INTERNACIONAL',
  CM => 'OBJETO INTERNACIONAL',
  CN => 'OBJETO INTERNACIONAL',
  CO => 'OBJETO INTERNACIONAL',
  CP => 'COLIS POSTAUX',
  CQ => 'OBJETO INTERNACIONAL',
  CR => 'CARTA REGISTRADA SEM VALOR DECLARADO',
  CS => 'OBJETO INTERNACIONAL',
  CT => 'OBJETO INTERNACIONAL',
  CU => 'OBJETO INTERNACIONAL',
  CV => 'REGISTRADO INTERNACIONAL',
  CW => 'OBJETO INTERNACIONAL',
  CX => 'OBJETO INTERNACIONAL',
  CY => 'OBJETO INTERNACIONAL',
  CZ => 'OBJETO INTERNACIONAL',
  DA => 'REM EXPRES COM AR DIGITAL',
  DB => 'REM EXPRES COM AR DIGITAL BRADESCO',
  DC => 'REM EXPRESSA CRLV/CRV/CNH e NOTIFICAÇÃO',
  DD => 'DEVOLUÇÃO DE DOCUMENTOS',
  DE => 'REMESSA EXPRESSA TALÃO E CARTÃO C/ AR',
  DF => 'E-SEDEX (LÓGICO)',
  DI => 'REM EXPRES COM AR DIGITAL ITAU',
  DL => 'ENCOMENDA SEDEX (LÓGICO)',
  DP => 'REM EXPRES COM AR DIGITAL PRF',
  DS => 'REM EXPRES COM AR DIGITAL SANTANDER',
  DT => 'REMESSA ECON.SEG.TRANSITO C/AR DIGITAL',
  DX => 'ENCOMENDA SEDEX 10 (LÓGICO)',
  EA => 'OBJETO INTERNACIONAL',
  EB => 'OBJETO INTERNACIONAL',
  EC => 'ENCOMENDA PAC',
  ED => 'OBJETO INTERNACIONAL',
  EE => 'SEDEX INTERNACIONAL',
  EF => 'OBJETO INTERNACIONAL',
  EG => 'OBJETO INTERNACIONAL',
  EH => 'ENCOMENDA NORMAL COM AR DIGITAL',
  EI => 'OBJETO INTERNACIONAL',
  EJ => 'ENCOMENDA INTERNACIONAL',
  EK => 'OBJETO INTERNACIONAL',
  EL => 'OBJETO INTERNACIONAL',
  EM => 'OBJETO INTERNACIONAL',
  EN => 'ENCOMENDA NORMAL NACIONAL',
  EO => 'OBJETO INTERNACIONAL',
  EP => 'OBJETO INTERNACIONAL',
  EQ => 'ENCOMENDA SERVIÇO NÃO EXPRESSA ECT',
  ER => 'REGISTRADO',
  ES => 'E-SEDEX',
  ET => 'OBJETO INTERNACIONAL',
  EU => 'OBJETO INTERNACIONAL',
  EV => 'OBJETO INTERNACIONAL',
  EW => 'OBJETO INTERNACIONAL',
  EX => 'OBJETO INTERNACIONAL',
  EY => 'OBJETO INTERNACIONAL',
  EZ => 'OBJETO INTERNACIONAL',
  FA => 'FAC REGISTRATO (LÓGICO)',
  FE => 'ENCOMENDA FNDE',
  FF => 'REGISTRADO DETRAN',
  FH => 'REGISTRADO FAC COM AR DIGITAL',
  FM => 'REGISTRADO - FAC MONITORADO',
  FR => 'REGISTRADO FAC',
  IA => 'INTEGRADA AVULSA',
  IC => 'INTEGRADA A COBRAR',
  ID => 'INTEGRADA DEVOLUCAO DE DOCUMENTO',
  IE => 'INTEGRADA ESPECIAL',
  IF => 'CPF',
  II => 'INTEGRADA INTERNO',
  IK => 'INTEGRADA COM COLETA SIMULTANEA',
  IM => 'INTEGRADA MEDICAMENTOS',
  IN => 'OBJ DE CORRESP E EMS REC EXTERIOR',
  IP => 'INTEGRADA PROGRAMADA',
  IR => 'IMPRESSO REGISTRADO',
  IS => 'INTEGRADA STANDARD',
  IT => 'INTEGRADO TERMOLÁBIL',
  IU => 'INTEGRADA URGENTE',
  JA => 'REMESSA ECONOMICA C/AR DIGITAL',
  JB => 'REMESSA ECONOMICA C/AR DIGITAL',
  JC => 'REMESSA ECONOMICA C/AR DIGITAL',
  JD => 'REMESSA ECONOMICA C/AR DIGITAL',
  JE => 'REMESSA ECONÔMICA C/AR DIGITAL',
  JG => 'REGISTRATO AGÊNCIA (FÍSICO)',
  JJ => 'REGISTRADO JUSTIÇA',
  JL => 'OBJETO REGISTRADO (LÓGICO)',
  JM => 'MALA DIRETA POSTAL ESPECIAL (LÓGICO)',
  LA => 'LOGÍSTICA REVERSA SIMULTÂNEA - ENCOMENDA SEDEX (AGÊNCIA)',
  LB => 'LOGÍSTICA REVERSA SIMULTÂNEA - ENCOMENDA E-SEDEX (AGÊNCIA)',
  LC => 'CARTA EXPRESSA',
  LE => 'LOGÍSTICA REVERSA ECONOMICA',
  LP => 'LOGÍSTICA REVERSA SIMULTÂNEA - ENCOMENDA PAC (AGÊNCIA)',
  LS => 'LOGISTICA REVERSA SEDEX',
  LV => 'LOGISTICA REVERSA EXPRESSA',
  LX => 'CARTA EXPRESSA',
  LY => 'CARTA EXPRESSA',
  MA => 'SERVIÇOS ADICIONAIS',
  MB => 'TELEGRAMA DE BALCÃO',
  MC => 'MALOTE CORPORATIVO',
  ME => 'TELEGRAMA',
  MF => 'TELEGRAMA FONADO',
  MK => 'TELEGRAMA CORPORATIVO',
  MM => 'TELEGRAMA GRANDES CLIENTES',
  MP => 'TELEGRAMA PRÉ-PAGO',
  MS => 'ENCOMENDA SAUDE',
  MT => 'TELEGRAMA VIA TELEMAIL',
  MY => 'TELEGRAMA INTERNACIONAL ENTRANTE',
  MZ => 'TELEGRAMA VIA CORREIOS ON LINE',
  NE => 'TELE SENA RESGATADA',
  PA => 'PASSAPORTE',
  PB => 'ENCOMENDA PAC - NÃO URGENTE',
  PC => 'ENCOMENDA PAC A COBRAR',
  PD => 'ENCOMENDA PAC - NÃO URGENTE',
  PF => 'PASSAPORTE',
  PG => 'ENCOMENDA PAC (ETIQUETA FÍSICA)',
  PH => 'ENCOMENDA PAC (ETIQUETA LÓGICA)',
  PR => 'REEMBOLSO POSTAL - CLIENTE AVULSO',
  RA => 'REGISTRADO PRIORITÁRIO',
  RB => 'CARTA REGISTRADA',
  RC => 'CARTA REGISTRADA COM VALOR DECLARADO',
  RD => 'REMESSA ECONOMICA DETRAN',
  RE => 'REGISTRADO ECONÔMICO',
  RF => 'OBJETO DA RECEITA FEDERAL',
  RG => 'REGISTRADO DO SISTEMA SARA',
  RH => 'REGISTRADO COM AR DIGITAL',
  RI => 'REGISTRADO',
  RJ => 'REGISTRADO AGÊNCIA',
  RK => 'REGISTRADO AGÊNCIA',
  RL => 'REGISTRADO LÓGICO',
  RM => 'REGISTRADO AGÊNCIA',
  RN => 'REGISTRADO AGÊNCIA',
  RO => 'REGISTRADO AGÊNCIA',
  RP => 'REEMBOLSO POSTAL - CLIENTE INSCRITO',
  RQ => 'REGISTRADO AGÊNCIA',
  RR => 'CARTA REGISTRADA SEM VALOR DECLARADO',
  RS => 'REGISTRADO LÓGICO',
  RT => 'REM ECON TALAO/CARTAO SEM AR DIGITAL',
  RU => 'REGISTRADO SERVIÇO ECT',
  RV => 'REM ECON CRLV/CRV/CNH COM AR DIGITAL',
  RY => 'REM ECON TALAO/CARTAO COM AR DIGITAL',
  RZ => 'REGISTRADO',
  SA => 'SEDEX ANOREG',
  SB => 'SEDEX 10 AGÊNCIA (FÍSICO)',
  SC => 'SEDEX A COBRAR',
  SD => 'REMESSA EXPRESSA DETRAN',
  SE => 'ENCOMENDA SEDEX',
  SF => 'SEDEX AGÊNCIA',
  SG => 'SEDEX DO SISTEMA SARA',
  SI => 'SEDEX AGÊNCIA',
  SJ => 'SEDEX HOJE',
  SK => 'SEDEX AGÊNCIA',
  SL => 'SEDEX LÓGICO',
  SM => 'SEDEX MESMO DIA',
  SN => 'SEDEX COM VALOR DECLARADO',
  SO => 'SEDEX AGÊNCIA',
  SP => 'SEDEX PRÉ-FRANQUEADO',
  SQ => 'SEDEX',
  SR => 'SEDEX',
  SS => 'SEDEX FÍSICO',
  ST => 'REM EXPRES TALAO/CARTAO SEM AR DIGITAL',
  SU => 'ENCOMENDA SERVIÇO EXPRESSA ECT',
  SV => 'REM EXPRES CRLV/CRV/CNH COM AR DIGITAL',
  SW => 'E-SEDEX',
  SX => 'SEDEX 10',
  SY => 'REM EXPRES TALAO/CARTAO COM AR DIGITAL',
  SZ => 'SEDEX AGÊNCIA',
  TE => 'TESTE (OBJETO PARA TREINAMENTO)',
  TS => 'TESTE (OBJETO PARA TREINAMENTO)',
  VA => 'ENCOMENDAS COM VALOR DECLARADO',
  VC => 'ENCOMENDAS',
  VD => 'ENCOMENDAS COM VALOR DECLARADO',
  VE => 'ENCOMENDAS',
  VF => 'ENCOMENDAS COM VALOR DECLARADO',
  XM => 'SEDEX MUNDI',
  XR => 'ENCOMENDA SUR POSTAL EXPRESSO',
  XX => 'ENCOMENDA SUR POSTAL 24 HORAS',
);

# http://www.correios.com.br/voce/enderecamento/Arquivos/guia_tecnico_encomendas.pdf
sub sro_ok {
  if ( $_[0] =~ m/^[A-Z|a-z]{2}([0-9]{8})([0-9])BR$/i ) {
    my ( $numeros, $dv ) = ($1, $2);
    my @numeros = split // => $numeros;
    my @magica  = ( 8, 6, 4, 2, 3, 5, 9, 7 );

    my $soma = 0;
    foreach ( 0 .. 7 ) {
      $soma += ( $numeros[$_] * $magica[$_] );
    }

    my $resto = $soma % 11;
    my $dv_check = $resto == 0 ? 5
                 : $resto == 1 ? 0
                 : 11 - $resto
                 ;
    return $dv == $dv_check;
  }
  else {
    return;
  }
}

sub sro_sigla {
  if ( sro_ok( @_ ) ) {
    $_[0] =~ m/^([A-Z|a-z]{2}).*$/i;
    my $prefixo = $1; 
    return $siglas{$prefixo};
  } else {
    return;
  } 
}

sub sro    { _sro('001', @_) }
sub sro_en { _sro('002', @_) }

sub _sro {
    my ($LANG, $code, $_url, $verifica_prefixo) = @_;
    return unless $code && sro_ok( $code );

    if ( defined $verifica_prefixo && $verifica_prefixo == 1 ) {
	my $prefixo = sro_sigla( $code );
        return unless ( defined $prefixo );
    }

    # internal use only: we override this during testing
    $_url = 'http://websro.correios.com.br/sro_bin/txect01$.Inexistente?P_LINGUA=' . $LANG . "&P_TIPO=002&P_COD_LIS=$code"
        unless defined $_url;

    my $agent = LWP::UserAgent->new(
                       agent   => $AGENT,
                       timeout => $TIMEOUT,
            );
    my $response = $agent->get($_url);

    return unless $response->is_success;

    my $html = HTML::TreeBuilder->new_from_content( $response->decoded_content );
    
    my $table = $html->find('table');
    
    return unless $table;
    return if ( $table->as_trimmed_text eq $code);
    
    my @items = $table->find('tr');

    shift @items; # drop the first 'tr'

    my $i = 0;
    my @result;
    foreach my $item (@items) {
        my @elements = $item->find('td');
        return unless @elements;

        # new entry
        if ( @elements == 3 ) {
            # short-circuit
            return $result[0] unless wantarray or $i == 0;

            my $item = WWW::Correios::SRO::Item->new;
            $item->date($elements[0]->as_trimmed_text);
            $item->location($elements[1]->as_trimmed_text);
            utf8::encode(my $status = $elements[2]->as_trimmed_text);
            $item->status($status);
            $result[$i++] = $item;
        }
        # extra info for the current entry
        else {
            return unless ref $result[$i - 1] and scalar @elements == 1;
            utf8::encode(my $extra = $elements[0]->as_trimmed_text);
            $result[$i - 1]->extra($extra);
        }
    }
    return wantarray ? @result : $result[0];
}

42;
__END__
=encoding utf8

=head1 NAME

WWW::Correios::SRO - Serviço de Rastreamento de Objetos (Brazilian Postal Object Tracking Service)


=head1 BILINGUAL MODULE

This module provides APIs in english and portuguese. Documentation is also shown in both languages.

Este módulo oferece APIs em inglês e português. Documentação também é mostrada em ambos os idiomas.


=head1 SYNOPSIS

API em português:

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

English API:

    use WWW::Correios::SRO qw( sro_en sro_ok );

    my $code = 'SS123456789BR';  # insert tracking code here

    return 'invalid SRO' unless sro_ok( $code );

    my $prefix = sro_sigla( $code ); # returns "SEDEX FÍSICO";

    my @full_history = sro_en( $code );

    my $last = sro_en( $code );

    $last->date;       # '22/05/2010 12:10'
    $last->location;   # 'CEE JACAREPAGUA - RIO DE JANEIRO/RJ'
    $last->status;     # 'No receiver at the address'
    $last->extra;      # 'Delivery will be retried'

Note: All messages are created by the brazilian post office website. Some messages might not be translated.

Note #2: the sro_en() function is experimental, and could be removed in future versions with no prior notice. If you care, or have any comments/suggestions on how to improve this, please let me know.

=head1 DESCRIPTION


=head1 EXPORTS

Este módulo não exporta nada por padrão. Você precisa explicitar 'sro' (para mensagens em português) ou 'sro_en' (para mensagens em inglês).

This module exports nothing by default. You have to explicitly ask for 'sro' (for the portuguese messages) or 'sro_en' (for the english messages).

=head2 sro

Recebe o código identificador do objeto. 

Em contexto escalar, retorna retorna um objeto WWW::Correios::SRO::Item contendo a entrada mais recente no registro dos Correios. Em contexto de lista, retorna um array de objetos WWW::Correios::SRO::Item, da entrada mais recente à mais antiga. Em caso de falha, retorna I<undef>. As mensagens do objeto retornado estarão em português.

Seu terceiro parâmetro, verifica_prefixo, determina se pesquisaremos apenas os códigos com prefixos apresentados pelos Correios ($verifica_prefixo = 1) ou não.
--

Receives the item identification code.

In scalar context, returns a WWW::Correios::SRO::Item object containing the most recent log entry in the Postal service. In list context, returns a list of WWW::Correios::SRO::Item objects, from the most recent entry to the oldest. Returns I<undef> upon failure. Messages on the returned object will be in portuguese.

Its thirds parameter, verifica_prefixo, determines if we shall search only the codes with prefixes shown by Brazilian Post Office ($erifica_prefixo = 1) or not.

=head2 sro_en

O mesmo que C<sro()>, mas com mensagens em inglês.

Same as C<sro()>, but with messages in english.


=head2 sro_ok

Retorna verdadeiro se o código de rastreamento passado é válido, caso contrário retorna falso. Essa função é chamada automaticamente pelas funções C<sro> e C<sro_en>, então você
não precisa se preocupar em chamá-la diretamente. Ela deve ser usada quando você quer apenas saber se o código é válido ou não, sem precisar fazer uma consulta HTTP ao site dos
correios. Essa função B<não> elimina espaços da string, você deve fazer sua própria higienização.

--

Returns true if the given tracking code is valid, false otherwise. This function is automatically called by the C<sro> and C<sro_en> functions, so you don't have to worry about calling it directly. It should be used when you just want to know whether the tracking code is valid or not, without the need to make an HTTP request to the postal office website. This function does B<not> trim whitespaces from the given string, you have to sanitize it by yourself.

=head2 sro_sigla

Retorna uma string com o significado do prefixo do código que foi passado. Retorna I<undef> caso a string não seja conhecida.

--

Returns a string with the meaning of the code's prefix. Returns I<undef> if we don't know the meaning.

=head1 OBJETO RETORNADO/RETURNED OBJECT

=head2 data

=head2 date (alias)

Retorna a data/hora em que os dados de entrega foram recebidos pelo sistema, exceto no I<< 'SEDEX 10' >> e no I<< 'SEDEX Hoje' >>, em que representa o horário real da entrega. Informação sobre onde encontrar o código para rastreamento estão disponíveis (em português) no link: L<< http://www.correios.com.br/servicos/rastreamento/como_loc_objeto.cfm >>

Returns the date/time in which the delivery data got into the system, except on I<< 'SEDEX 10' >> and I<< 'SEDEX Hoje' >>, where it corresponds to the actual delivery date. Information on how to find the tracking code is available in the link: L<< http://www.correios.com.br/servicos/rastreamento/como_loc_objeto.cfm >> (follow the "English version" link on that page).


=head2 local

=head2 location (alias)

Retorna local em que o evento ocorreu. A string retornada é prefixada por uma sigla, como B<ACF> (Agência de Correios Franqueada), B<CTE> (Centro de Tratamento de Encomendas), B<CTCE> (Centro de Tratamento de Cartas e Encomendas), B<CTCI> (Centro de Tratamento de Correio Internacional), B<CDD> (Centro de Distribuição Domiciliária), B<CEE> (Centro de Entrega de Encomendas).

Returns the location where the event ocurred. The returned string is prefixed by an acronym like B<ACF> (Franchised Postal Agency), B<CTE> (Center for Item Assessment), B<CTCE> (Center for Item and Mail Assessment), B<CTCI> (Center for International Postal Assessment), B<CDD> (Center for Domiciliary Distribution), B<CEE> (Center for Item Delivery).


=head2 status

Retorna a situação registrada para o evento (postado, encaminhado, destinatário ausente, etc)

Returns the registered situation for the event (no receiver at the address, etc)


=head2 extra

Contém informações adicionais a respeito do evento, ou I<undef>. Exemplo: 'Será realizada uma nova tentativa de entrega'.

Contains additional information about the event, or I<undef>. E.g.: 'Delivery will be retried'


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Por favor envie bugs ou pedidos para C<bug-www-correios-sro at rt.cpan.org>, ou pela interface web em L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Correios-SRO>. Eu serei notificado, e então você será automaticamente notificado sobre qualquer progresso na questão.

Please report any bugs or feature requests to C<bug-www-correios-sro at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Correios-SRO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Correios::SRO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Correios-SRO>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Correios-SRO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Correios-SRO>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Correios-SRO/>

=back


=head1 AGRADECIMENTOS/ACKNOWLEDGEMENTS

Este módulo não existiria sem o serviço gratuito de rastreamento online dos Correios. 

L<< http://www.correios.com.br/servicos/rastreamento/ >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


