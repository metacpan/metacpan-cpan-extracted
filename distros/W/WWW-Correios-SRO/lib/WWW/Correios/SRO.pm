package WWW::Correios::SRO;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw( sro sro_en sro_ok sro_sigla status_da_entrega );

our $VERSION = '0.12';
my $AGENT = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';
my $TIMEOUT = 30;

# Verificado em 22 de Maio de 2017
# http://www.correios.com.br/para-voce/precisa-de-ajuda/como-rastrear-um-objeto/siglas-utilizadas-no-rastreamento-de-objeto
#
#
# Sabemos que as seguintes siglas são usadas: DH
# Como não existem na tabela dos correios, nao se encontra na hash.
# Um código com esse prefixo funcionará ao usar a funcao sro sem
# passar o parametro verifica_prefixo. Porém, se passar este
# parametro, deve retornar undef como qualquer SRO
# cujo prefixo não está previsto na tabela dos Correios.
my %siglas = (
  AL => 'AGENTES DE LEITURA',
  AR => 'AVISO DE RECEBIMENTO',
  AS => 'ENCOMENDA PAC – AÇÃO SOCIAL',
  BE => 'REMESSA ECONÔMICA TALÃO/CARTÃO (SEM AR DIGITAL)',
  CA => 'ENCOMENDA INTERNACIONAL - COLIS',
  CB => 'ENCOMENDA INTERNACIONAL - COLIS',
  CC => 'ENCOMENDA INTERNACIONAL - COLIS',
  CD => 'ENCOMENDA INTERNACIONAL - COLIS',
  CE => 'ENCOMENDA INTERNACIONAL - COLIS',
  CF => 'ENCOMENDA INTERNACIONAL - COLIS',
  CG => 'ENCOMENDA INTERNACIONAL - COLIS',
  CH => 'ENCOMENDA INTERNACIONAL - COLIS',
  CI => 'ENCOMENDA INTERNACIONAL - COLIS',
  CJ => 'ENCOMENDA INTERNACIONAL - COLIS',
  CK => 'ENCOMENDA INTERNACIONAL - COLIS',
  CL => 'ENCOMENDA INTERNACIONAL - COLIS',
  CM => 'ENCOMENDA INTERNACIONAL - COLIS',
  CN => 'ENCOMENDA INTERNACIONAL - COLIS',
  CO => 'ENCOMENDA INTERNACIONAL - COLIS',
  CP => 'ENCOMENDA INTERNACIONAL - COLIS',
  CQ => 'ENCOMENDA INTERNACIONAL - COLIS',
  CR => 'CARTA REGISTRADA SEM VALOR DECLARADO',
  CS => 'ENCOMENDA INTERNACIONAL - COLIS',
  CT => 'ENCOMENDA INTERNACIONAL - COLIS',
  CU => 'ENCOMENDA INTERNACIONAL - COLIS',
  CV => 'ENCOMENDA INTERNACIONAL - COLIS',
  CW => 'ENCOMENDA INTERNACIONAL - COLIS',
  CX => 'ENCOMENDA INTERNACIONAL - COLIS OU SELO LACRE PARA CAIXETAS',
  CY => 'ENCOMENDA INTERNACIONAL - COLIS',
  CZ => 'ENCOMENDA INTERNACIONAL - COLIS',
  DA => 'SEDEX OU REMESSA EXPRESSA COM AR DIGITAL',
  DB => 'SEDEX OU REMESSA EXPRESSA COM AR DIGITAL (BRADESCO)',
  DC => 'REMESSA EXPRESSA CRLV/CRV/CNH e NOTIFICAÇÕES',
  DD => 'DEVOLUÇÃO DE DOCUMENTOS',
  DE => 'REMESSA EXPRESSA TALÃO/CARTÃO COM AR',
  DF => 'E-SEDEX',
  DG => 'SEDEX',
  DI => 'SEDEX OU REMESSA EXPRESSA COM AR DIGITAL (ITAU)',
  DJ => 'SEDEX',
  DK => 'PAC EXTRA GRANDE',
  DL => 'SEDEX',
  DM => 'E-SEDEX',
  DN => 'SEDEX',
  DO => 'SEDEX OU REMESSA EXPRESSA COM AR DIGITAL (ITAU)',
  DP => 'SEDEX PAGAMENTO NA ENTREGA',
  DQ => 'SEDEX OU REMESSA EXPRESSA COM AR DIGITAL (BRADESCO)',
  DR => 'REMESSA EXPRESSA COM AR DIGITAL (SANTANDER)',
  DS => 'SEDEX OU REMESSA EXPRESSA COM AR DIGITAL (SANTANDER)',
  DT => 'REMESSA ECONÔMICA COM AR DIGITAL (DETRAN)',
  DU => 'E-SEDEX',
  DV => 'SEDEX COM AR DIGITAL',
  DW => 'ENCOMENDA SEDEX (ETIQUETA LÓGICA)',
  DX => 'SEDEX 10',
  EA => 'ENCOMENDA INTERNACIONAL - EMS',
  EB => 'ENCOMENDA INTERNACIONAL - EMS',
  EC => 'PAC',
  ED => 'PACKET EXPRESS',
  EE => 'ENCOMENDA INTERNACIONAL - EMS',
  EF => 'ENCOMENDA INTERNACIONAL - EMS',
  EG => 'ENCOMENDA INTERNACIONAL - EMS',
  EH => 'ENCOMENDA INTERNACIONAL - EMS OU ENCOMENDA COM AR DIGITAL',
  EI => 'ENCOMENDA INTERNACIONAL - EMS',
  EJ => 'ENCOMENDA INTERNACIONAL - EMS',
  EK => 'ENCOMENDA INTERNACIONAL - EMS',
  EL => 'ENCOMENDA INTERNACIONAL - EMS',
  EM => 'ENCOMENDA INTERNACIONAL - SEDEX MUNDI OU EMS IMPORTAÇÃO',
  EN => 'ENCOMENDA INTERNACIONAL - EMS',
  EO => 'ENCOMENDA INTERNACIONAL - EMS',
  EP => 'ENCOMENDA INTERNACIONAL - EMS',
  EQ => 'ENCOMENDA DE SERVIÇO NÃO EXPRESSA (ECT)',
  ER => 'OBJETO REGISTRADO',
  ES => 'E-SEDEX OU EMS',
  ET => 'ENCOMENDA INTERNACIONAL - EMS',
  EU => 'ENCOMENDA INTERNACIONAL - EMS',
  EV => 'ENCOMENDA INTERNACIONAL - EMS',
  EW => 'ENCOMENDA INTERNACIONAL - EMS',
  EX => 'ENCOMENDA INTERNACIONAL - EMS',
  EY => 'ENCOMENDA INTERNACIONAL - EMS',
  EZ => 'ENCOMENDA INTERNACIONAL - EMS',
  FA => 'FAC REGISTRADO',
  FE => 'ENCOMENDA FNDE',
  FF => 'OBJETO REGISTRADO (DETRAN)',
  FH => 'FAC REGISTRADO COM AR DIGITAL',
  FM => 'FAC MONITORADO',
  FR => 'FAC REGISTRADO',
  IA => 'LOGÍSTICA INTEGRADA (AGENDADO/AVULSO)',
  IC => 'LOGÍSTICA INTEGRADA (A COBRAR)',
  ID => 'LOGÍSTICA INTEGRADA (DEVOLUCAO DE DOCUMENTO)',
  IE => 'LOGÍSTICA INTEGRADA (ESPECIAL)',
  IF => 'CPF',
  II => 'LOGÍSTICA INTEGRADA (ECT)',
  IK => 'LOGÍSTICA INTEGRADA COM COLETA SIMULTÂNEA',
  IM => 'LOGÍSTICA INTEGRADA (MEDICAMENTOS)',
  IN => 'CORRESPONDÊNCIA E EMS RECEBIDO DO EXTERIOR',
  IP => 'LOGÍSTICA INTEGRADA (PROGRAMADA)',
  IR => 'IMPRESSO REGISTRADO',
  IS => 'LOGÍSTICA INTEGRADA STANDARD (MEDICAMENTOS)',
  IT => 'REMESSA EXPRESSA MEDICAMENTOS / LOGÍSTICA INTEGRADA TERMOLÁBIL',
  IU => 'LOGÍSTICA INTEGRADA (URGENTE)',
  IX => 'EDEI EXPRESSO',
  JA => 'REMESSA ECONOMICA COM AR DIGITAL',
  JB => 'REMESSA ECONOMICA COM AR DIGITAL',
  JC => 'REMESSA ECONOMICA COM AR DIGITAL',
  JD => 'REMESSA ECONOMICA TALÃO/CARTÃO',
  JE => 'REMESSA ECONÔMICA COM AR DIGITAL',
  JF => 'REMESSA ECONÔMICA COM AR DIGITAL',
  JG => 'OBJETO REGISTRADO URGENTE/PRIORITÁRIO',
  JH => 'OBJETO REGISTRADO URGENTE/PRIORITÁRIO',
  JI => 'REMESSA ECONÔMICA TALÃO/CARTÃO',
  JJ => 'OBJETO REGISTRADO (JUSTIÇA)',
  JK => 'REMESSA ECONÔMICA TALÃO/CARTÃO',
  JL => 'OBJETO REGISTRADO',
  JM => 'MALA DIRETA POSTAL ESPECIAL',
  JN => 'OBJETO REGISTRADO ECONÔMICO',
  JO => 'OBJETO REGISTRADO URGENTE',
  JP => 'RECEITA FEDERAL',
  JQ => 'REMESSA ECONÔMICA COM AR DIGITAL',
  JR => 'OBJETO REGISTRADO URGENTE/PRIORITÁRIO',
  JS => 'OBJETO REGISTRADO',
  JT => 'OBJETO REGISTRADO URGENTE',
  JV => 'REMESSA ECONÔMICA COM AR DIGITAL',
  LA => 'SEDEX COM LOGÍSTICA REVERSA SIMULTÂNEA EM AGÊNCIA',
  LB => 'E-SEDEX COM LOGÍSTICA REVERSA SIMULTÂNEA EM AGÊNCIA',
  LC => 'OBJETO INTERNACIONAL (PRIME)',
  LE => 'LOGÍSTICA REVERSA ECONOMICA',
  LF => 'OBJETO INTERNACIONAL (PRIME)',
  LI => 'OBJETO INTERNACIONAL (PRIME)',
  LJ => 'OBJETO INTERNACIONAL (PRIME)',
  LK => 'OBJETO INTERNACIONAL (PRIME)',
  LM => 'OBJETO INTERNACIONAL (PRIME)',
  LN => 'OBJETO INTERNACIONAL (PRIME)',
  LP => 'PAC COM LOGÍSTICA REVERSA SIMULTÂNEA EM AGÊNCIA',
  LS => 'SEDEX LOGISTICA REVERSA',
  LV => 'LOGISTICA REVERSA EXPRESSA',
  LX => 'PACKET STANDARD/ECONÔMICA',
  LZ => 'OBJETO INTERNACIONAL (PRIME)',
  MA => 'SERVIÇOS ADICIONAIS DO TELEGRAMA',
  MB => 'TELEGRAMA (BALCÃO)',
  MC => 'TELEGRAMA (FONADO)',
  MD => 'SEDEX MUNDI (DOCUMENTO INTERNO)',
  ME => 'TELEGRAMA',
  MF => 'TELEGRAMA FONADO',
  MK => 'TELEGRAMA (CORPORATIVO)',
  ML => 'FECHA MALAS (RABICHO)',
  MM => 'TELEGRAMA (GRANDES CLIENTES)',
  MP => 'TELEGRAMA (PRÉ-PAGO)',
  MR => 'AR DIGITAL',
  MS => 'ENCOMENDA SAUDE',
  MT => 'TELEGRAMA (TELEMAIL)',
  MY => 'TELEGRAMA INTERNACIONAL (ENTRANTE)',
  MZ => 'TELEGRAMA (CORREIOS ONLINE)',
  NE => 'TELE SENA RESGATADA',
  NX => 'EDEI ECONÔMICO (NÃO URGENTE)',
  OA => 'ENCOMENDA SEDEX',
  OB => 'ENCOMENDA E-SEDEX',
  PA => 'PASSAPORTE',
  PB => 'PAC',
  PC => 'PAC A COBRAR',
  PD => 'PAC',
  PE => 'PAC',
  PF => 'PASSAPORTE',
  PG => 'PAC',
  PH => 'PAC',
  PI => 'PAC',
  PJ => 'PAC',
  PK => 'PAC EXTRA GRANDE',
  PL => 'PAC',
  PN => 'PAC',
  PR => 'REEMBOLSO POSTAL',
  QQ => 'OBJETO DE TESTE (SIGEP WEB)',
  RA => 'OBJETO REGISTRADO/PRIORITÁRIO',
  RB => 'CARTA REGISTRADA',
  RC => 'CARTA REGISTRADA COM VALOR DECLARADO',
  RD => 'REMESSA ECONOMICA OU OBJETO REGISTRADO (DETRAN)',
  RE => 'OBJETO REGISTRADO ECONÔMICO',
  RF => 'RECEITA FEDERAL',
  RG => 'OBJETO REGISTRADO',
  RH => 'OBJETO REGISTRADO COM AR DIGITAL',
  RI => 'OBJETO REGISTRADO INTERNACIONAL PRIORITÁRIO',
  RJ => 'OBJETO REGISTRADO',
  RK => 'OBJETO REGISTRADO',
  RL => 'OBJETO REGISTRADO',
  RM => 'OBJETO REGISTRADO URGENTE',
  RN => 'OBJETO REGISTRADO (SIGEPWEB OU AGÊNCIA)',
  RO => 'OBJETO REGISTRADO',
  RP => 'REEMBOLSO POSTAL',
  RQ => 'OBJETO REGISTRADO',
  RR => 'OBJETO REGISTRADO',
  RS => 'OBJETO REGISTRADO',
  RT => 'REMESSA ECONÔMICA TALÃO/CARTAO',
  RU => 'OBJETO REGISTRADO (ECT)',
  RV => 'REMESSA ECONÔMICA CRLV/CRV/CNH E NOTIFICAÇÕES COM AR DIGITAL',
  RW => 'OBJETO INTERNACIONAL',
  RX => 'OBJETO INTERNACIONAL',
  RY => 'REMESSA ECONÔMICA TALÃO/CARTÃO COM AR DIGITAL',
  RZ => 'OBJETO REGISTRADO',
  SA => 'SEDEX',
  SB => 'SEDEX 10',
  SC => 'SEDEX A COBRAR',
  SD => 'SEDEX OU REMESSA EXPRESSA (DETRAN)',
  SE => 'SEDEX',
  SF => 'SEDEX',
  SG => 'SEDEX',
  SH => 'SEDEX COM AR DIGITAL / SEDEX OU AR DIGITAL',
  SI => 'SEDEX',
  SJ => 'SEDEX HOJE',
  SK => 'SEDEX',
  SL => 'SEDEX',
  SM => 'SEDEX 12',
  SN => 'SEDEX',
  SO => 'SEDEX',
  SP => 'SEDEX PRÉ-FRANQUEADO',
  SQ => 'SEDEX',
  SR => 'SEDEX',
  SS => 'SEDEX',
  ST => 'REMESSA EXPRESSA TALÃO/CARTÃO',
  SU => 'ENCOMENDA DE SERVIÇO EXPRESSA (ECT)',
  SV => 'REMESSA EXPRESSA CRLV/CRV/CNH E NOTIFICAÇÕES COM AR DIGITAL',
  SW => 'E-SEDEX',
  SX => 'SEDEX 10',
  SY => 'REMESSA EXPRESSA TALÃO/CARTÃO COM AR DIGITAL',
  SZ => 'SEDEX',
  TC => 'OBJETO PARA TREINAMENTO',
  TE => 'OBJETO PARA TREINAMENTO',
  TS => 'OBJETO PARA TREINAMENTO',
  VA => 'ENCOMENDAS COM VALOR DECLARADO',
  VC => 'ENCOMENDAS',
  VD => 'ENCOMENDAS COM VALOR DECLARADO',
  VE => 'ENCOMENDAS',
  VF => 'ENCOMENDAS COM VALOR DECLARADO',
  VV => 'OBJETO INTERNACIONAL',
  XA => 'AVISO DE CHEGADA (INTERNACIONAL)',
  XM => 'SEDEX MUNDI',
  XR => 'ENCOMENDA SUR POSTAL EXPRESSO',
  XX => 'ENCOMENDA SUR POSTAL 24 HORAS',
);

# http://www.correios.com.br/para-sua-empresa/servicos-para-o-seu-contrato/guias/enderecamento/arquivos/guia_tecnico_encomendas.pdf/at_download/file
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

sub sro    { _sro('101', @_) }
sub sro_en { _sro('102', @_) }

sub _sro {
    my ($language, $code, $params) = @_;
    return unless $code && length($code) % 13 == 0;
    my @codes = ($code =~ /.{13}/g);
    return if !@codes || (@codes > 1 && !$params->{multiple});

    foreach my $code_to_check (@codes) {
        return unless sro_ok( $code_to_check );

        if ($params->{verifica_prefixo}) {
            my $prefixo = sro_sigla( $code_to_check );
            return unless defined $prefixo;
        }
    }

    my $agent = $params->{ua};
    if (!$agent) {
        require LWP::UserAgent;
        $agent = LWP::UserAgent->new(
            agent   => $AGENT,
            timeout => (exists $params->{timeout} ? $params->{timeout} : $TIMEOUT),
        );
    }

    my $results = wantarray ? 'T' : 'U';
    my $user    = $params->{username} || 'ECT';
    my $pass    = $params->{password} || 'SRO';

    # http://www.correios.com.br/para-voce/correios-de-a-a-z/pdf/rastreamento-de-objetos/manual_rastreamentoobjetosws.pdf
    my $response = $agent->post(
        'http://webservice.correios.com.br:80/service/rastro',
        'Content-Type' => 'text/xml;charset=utf-8',
        'SOAPAction' => 'buscaEventos',
        'Content' => qq{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:res="http://resource.webservice.correios.com.br/"><soapenv:Header/><soapenv:Body><res:buscaEventos><usuario>$user</usuario><senha>$pass</senha><tipo>L</tipo><resultado>$results</resultado><lingua>$language</lingua><objetos>$code</objetos></res:buscaEventos></soapenv:Body></soapenv:Envelope>}
    );
    return unless $response->is_success;

    my $data = _parse_response($response->content);
    if (ref $data eq 'HASH') {
        if (!$params->{multiple}) {
            warn 'unexpected data from Correios webservice';
            return;
        }
        if ($results eq 'U') {
            foreach my $k (keys %$data) {
                $data->{$k} = $data->{$k}[0];
            }
        }
        return $data;
    }
    return $results eq 'T' ? @$data : $data->[0];
}

sub _parse_response {
    my ($content) = @_;
    return unless index($content, '<objeto>') >= 0;

    my %data;
    while ($content =~ m{<objeto>(.+?)</objeto>}gsi) {
        my $object = $1;
        my $tracking;
        if ($object =~ m{<numero>([^>]+)</numero>}) {
            $tracking = $1;
        }
        return unless $tracking;
        my @events;
        while ($object =~ m{<evento>(.+?)</evento>}gi) {
            my $event = $1;
            my $params = _parse_event($event);
            push @events, $params;
        }
        $data{$tracking} = \@events;
    }
    return (keys %data == 1 ? (values %data)[0] : \%data);
}

sub _parse_event {
    my ($event) = @_;

    return $event if index($event, '<') < 0;

    my %params;
    while ($event =~ m{<\s*([^>]+)\s*>\s*(.+?)\s*<\s*/\s*\1\s*>}g) {
        my ($key, $value) = ($1, $2);
        $params{$key} = _parse_event($value);
    }
    return \%params;
}

sub status_da_entrega {
    my ($data) = @_;
    die 'entrega_concluida() takes a HASHREF or ARRAYREF'
        unless $data && ref $data && (ref $data eq 'ARRAY' || ref $data eq 'HASH');

    my $last = ref $data eq 'ARRAY' ? $data->[0] : $data;
    return unless $last;

    # objeto dos Correios tem as mesmas chaves, independente do idioma.
    if (!ref $last || ref $last ne 'HASH' || !exists $last->{tipo} || !exists $last->{status}) {
        warn "status_da_entrega() data looks invalid. Missing keys?";
        return;
    }
    my $tipo   = $last->{tipo};
    my $status = $last->{status};
    if ($tipo eq 'BDR' || $tipo eq 'BDE' || $tipo eq 'BDI') {
        # estado final. entrega efetuada!
        return 'entregue' if $status <= 1;

        # acionar correios (produto extraviado, etc).
        return 'erro' if    $status == 9  || $status == 12 || $status == 28
                         || $status == 37 || $status == 43 || $status == 50
                         || $status == 51 || $status == 52 || $status == 80
        ;

        # pacote aguardando retirada pelo interessado.
        return 'retirar' if $status == 54 || $status == 2;

        # entrega incompleta, pacote retornando.
        return 'incompleto'
            if (  ($status != 20 && $status != 7 && $status <= 21)
                || $status == 26 || $status == 33 || $status == 36
                || $status == 40 || $status == 42 || $status == 48
                || $status == 49 || $status == 56
            );

        return 'acompanhar';
    }
    elsif ($tipo eq 'FC' && $status == 1) {
        return 'incompleto';
    }
    elsif (
        # pacote aguardando retirada.
           ($tipo eq 'LDI' && ($status <= 3 || $status == 14))
        || ($tipo eq 'OEC' && $status == 0)
    ) {
        return 'retirar';
    }
    else {
        return 'acompanhar';
    }
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

    my $prefixo = sro_sigla( $codigo ); # retorna "SEDEX";

    my @historico_completo = sro( $codigo );

    my $ultimo = sro( $codigo );

    # $ultimo terá uma estrutura como:
    {
        cidade    => "BELO HORIZONTE",
        codigo    => 31276970,
        data      => "19/05/2017",
        descricao => "Objeto encaminhado",
        destino   => {
            bairro => "Parque Novo Mundo",
            cidade => "Sao Paulo",
            codigo => "02170975",
            local  => "CTE VILA MARIA",
            uf     => "SP"
        },
        hora   => "22:19",
        local  => "CTE BELO HORIZONTE",
        status => "01",
        tipo   => "DO",
        uf     => "MG"
    }

    if (status_da_entrega($ultimo) eq 'entregue') {
        say "Yay! Pedido entregue!";
    }


English API:

    use WWW::Correios::SRO qw( sro_en sro_ok );

    my $code = 'SS123456789BR';  # insert tracking code here

    return 'invalid SRO' unless sro_ok( $code );

    my $prefix = sro_sigla( $code ); # returns "SEDEX";

    my @full_history = sro_en( $code );

    my $last = sro_en( $code );


Note: All messages are created by the brazilian post office website. Some messages might not be translated.

Note #2: the sro_en() function is experimental, and could be removed in future versions with no prior notice. If you care, or have any comments/suggestions on how to improve this, please let me know.

=head1 DESCRIPTION

Este módulo oferece uma interface com o serviço de rastreamento de objetos dos Correios. Até a data de publicação deste módulo não há uma API pública dos Correios para isso, então este módulo consulta o site dos Correios diretamente e faz parsing dos resultados. Sim, isso significa que mudanças no layout do site dos Correios podem afetar o funcionamento deste módulo. Até os Correios lançarem o serviço via API, isso é o que temos.

This module provides an interface to the Brazilian Postal (Correios) object tracking service. Until the date of release of this module there was no public API to achieve this, so this module queries the Correios website directly and parses its results. Yup, this means any layout changes on their website could affect the correctness of this module. Until Correios releases an API for this service, that's all we can do.

=head1 EXPORTS

Este módulo não exporta nada por padrão. Você precisa explicitar 'sro' (para mensagens em português) ou 'sro_en' (para mensagens em inglês).

This module exports nothing by default. You have to explicitly ask for 'sro' (for the portuguese messages) or 'sro_en' (for the english messages).

=head2 sro

Recebe o código identificador do objeto. 

Em contexto escalar, retorna retorna um hashref contendo a entrada mais recente no registro dos Correios. Em contexto de lista, retorna um array de hashrefs, da entrada mais recente à mais antiga. Em caso de falha, retorna I<undef>. As mensagens do objeto retornado estarão em português.

Seu segundo parâmetro (opcional) é um hashref com dados extras:

    sro( 'SS123456789BR', {
        ua               => LWP::UserAgent->new,
        timeout          => 5,
        username         => 'meu_usuario',
        password         => 'minha_senha',
        verifica_prefixo => 1,
        multiple         => 1,
    });

=over 4

=item * ua - user agent que fará a requisição. Precisa implementar o método C<post()> com a mesma interface do LWP::UserAgent.

=item * timeout - se o user agent não for especificado, esse parâmetro ajusta o timeout do user agent padrão.

=item * username - usuário disponibilizado pelos Correios para o seu contrato de acesso ao webservice de SRO.

=item * password - senha disponibilizada pelos Correios para o seu contrato de acesso ao webservice de SRO.

=item * verifica_prefixo - se verdadeiro, pesquisará apenas códigos com prefixo disponibilizado pelos Correios.

=item * multiple - permite passar vários códigos de rastreamento concatenados (e.g. 'SS123456789BRJR123456789BR').

=back

Se você passar mais de um código de rastreamento concatenado e o parâmetro 'multiple', o resultado será um hash onde cada chave é um dos códigos passados. O valor será o mesmo de antes, por chave (i.e. ou um hashref com os dados ou um array de hashrefs, dependendo se você chamou a função em contexto escalar ou de lista). Em outras palavras:

    my $ultimos_status = sro( 'SS123456789BRJR123456789BR', { multiple => 1 } );
    say $ultimos_status->{'SS123456789BR'}{status};

    my %todos_os_status = sro( 'SS123456789BRJR123456789BR', { multiple => 1 } );
    foreach my $entrada ( @{$todos_os_status{'SS123456789BR'}} ) {
        say $entrada->{status};
    }

--

Receives the item identification code.

In scalar context, returns a hashref containing the most recent log entry in the Postal service. In list context, returns a list of hashrefs, from the most recent entry to the oldest. Returns I<undef> upon failure. Messages on the returned object will be in portuguese.

Its second (optional) parameter is a hashref with extra data:

    sro( 'SS123456789BR', {
        ua               => LWP::UserAgent->new,
        timeout          => 5,
        username         => 'my_user',
        password         => 'my_password',
        verifica_prefixo => 1,
        multiple         => 1,
    });

=over 4

=item * ua - user agent that will make the request. Must implement the C<post()> method with the same API as LWP::UserAgent.

=item * timeout - if no user agent is specified, this parameter will adjust the timeout of the default one.

=item * username - user provided by Correios for your webservice contract.

=item * password - password provided by Correios for your webservice contract.

=item * verifica_prefixo - if given a true value, determines whether we query just the codes with valid prefixes.

=item * multiple - lets you pass several concatenated codes (e.g. 'SS123456789BRJR123456789BR').

=back

If you pass more than one concatenated code with the 'multiple' parameter, the result will be a hash where each key is one of the given codes. The value is the same as before, per key (i.e. either a hashref of data or an array of hashrefs, depending on scalar or list context). In other words:

    my $last_statuses = sro( 'SS123456789BRJR123456789BR', { multiple => 1 } );
    say $last_statuses->{'SS123456789BR'}{status};

    my %all_statuses = sro( 'SS123456789BRJR123456789BR', { multiple => 1 } );
    foreach my $entry ( @{$all_statuses{'SS123456789BR'}} ) {
        say $entry->{status};
    }

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

=head2 status_da_entrega( $dados_retornados )

Esta função recebe os dados retornados por uma consulta via C<sro()> em formato arrayref ou hashref, e retorna uma string no seguinte formato:

=over 4

=item 'entregue' - entrega concluida, nada mais a ser feito.

=item 'erro' - acionar Correios (objetos perdidos, extraviado, etc).

=item 'retirar' - pacote na agência, aguardando retirada pelo interessado.

=item 'incompleto' - pacote retornado ao remetente.

=item 'acompanhar' - pacote em trânsito.

=back


=head1 DADOS RETORNADOS/RETURNED DATA (BREAKING CHANGES)

Em versões anteriores à 0.11, este módulo retornava um objeto (ou uma lista de objetos). A API dos Correios mudou em meados de 2016, e agora a consulta retorna dados diferentes. Para dar mais flexibilidade, optamos por um hashref livre de estrutura. 

Algumas informações ainda são pertinentes:

=over 4

=item a data/hora retornada indica o momento em que os dados de entrega foram B<recebidos pelo sistema>, exceto no I<< 'SEDEX 10' >> e no I<< 'SEDEX Hoje' >>, em que representa o horário real da entrega. Informação sobre onde encontrar o código para rastreamento estão disponíveis (em português) no link: L<< http://www.correios.com.br/servicos/rastreamento/como_loc_objeto.cfm >>

=item the returned date/time refer to the moment in which the delivery data B<got into the system>, except on I<< 'SEDEX 10' >> and I<< 'SEDEX Hoje' >>, where it corresponds to the actual delivery date. Information on how to find the tracking code is available in the link: L<< http://www.correios.com.br/servicos/rastreamento/como_loc_objeto.cfm >> (follow the "English version" link on that page).

=item o campo de "local" contém o local em que o evento ocorreu. A string retornada é prefixada por uma sigla, como B<ACF> (Agência de Correios Franqueada), B<CTE> (Centro de Tratamento de Encomendas), B<CTCE> (Centro de Tratamento de Cartas e Encomendas), B<CTCI> (Centro de Tratamento de Correio Internacional), B<CDD> (Centro de Distribuição Domiciliária), B<CEE> (Centro de Entrega de Encomendas).

=item the "location" field contains the location where the event ocurred. The returned string is prefixed by an acronym like B<ACF> (Franchised Postal Agency), B<CTE> (Center for Item Assessment), B<CTCE> (Center for Item and Mail Assessment), B<CTCI> (Center for International Postal Assessment), B<CDD> (Center for Domiciliary Distribution), B<CEE> (Center for Item Delivery).

=back


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Por favor envie bugs ou pedidos para C<bug-www-correios-sro at rt.cpan.org>, ou pela interface web em L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Correios-SRO>. Eu serei notificado, e então você será automaticamente notificado sobre qualquer progresso na questão.

Please report any bugs or feature requests to C<bug-www-correios-sro at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Correios-SRO>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 AGRADECIMENTOS/ACKNOWLEDGEMENTS

Este módulo não existiria sem o serviço gratuito de rastreamento online dos Correios. 

L<< http://www.correios.com.br/servicos/rastreamento/ >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2017 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


