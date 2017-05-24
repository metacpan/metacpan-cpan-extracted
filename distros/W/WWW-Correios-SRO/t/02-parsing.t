use strict;
use warnings;
use Test::More tests => 2;
use WWW::Correios::SRO;

# single object returned
my $content = q{<?xml version="1.0" encoding="utf-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace xmlns:X-OPNET-Transaction-Trace="http://opnet.com">pid=41517,requestid=48242f7f60b2af57aac8f547938ecb01a0d5acf4ea051273</X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace></soapenv:Header><soapenv:Body><ns2:buscaEventosResponse xmlns:ns2="http://resource.webservice.correios.com.br/"><return><versao>2.0</versao><qtd>1</qtd><objeto><numero>SW473852549BR</numero><sigla>SW</sigla><nome>e-SEDEX</nome><categoria>E-SEDEX</categoria><evento><tipo>DO</tipo><status>01</status><data>20/05/2017</data><hora>06:45</hora><descricao>Objeto encaminhado </descricao><local>CTE VILA MARIA</local><codigo>02170975</codigo><cidade>Sao Paulo</cidade><uf>SP</uf><destino><local>CDD TUCURUVI</local><codigo>02307970</codigo><cidade>Sao Paulo</cidade><bairro>Tucuruvi</bairro><uf>SP</uf></destino></evento><evento><tipo>DO</tipo><status>01</status><data>19/05/2017</data><hora>22:19</hora><descricao>Objeto encaminhado </descricao><local>CTE BELO HORIZONTE</local><codigo>31276970</codigo><cidade>BELO HORIZONTE</cidade><uf>MG</uf><destino><local>CTE VILA MARIA</local><codigo>02170975</codigo><cidade>Sao Paulo</cidade><bairro>Parque Novo Mundo</bairro><uf>SP</uf></destino></evento><evento><tipo>DO</tipo><status>01</status><data>19/05/2017</data><hora>16:47</hora><descricao>Objeto encaminhado </descricao><local>AGF BERNARDO MONTEIRO</local><codigo>30140973</codigo><cidade>Belo Horizonte</cidade><uf>MG</uf><destino><local>CTE BELO HORIZONTE</local><codigo>31276970</codigo><cidade>BELO HORIZONTE</cidade><bairro>Universitário</bairro><uf>MG</uf></destino></evento><evento><tipo>PO</tipo><status>01</status><data>19/05/2017</data><hora>15:57</hora><descricao>Objeto postado</descricao><local>AGF BERNARDO MONTEIRO</local><codigo>30140973</codigo><cidade>Belo Horizonte</cidade><uf>MG</uf></evento></objeto></return></ns2:buscaEventosResponse></soapenv:Body></soapenv:Envelope>};

my $parsed = WWW::Correios::SRO::_parse_response($content);
is_deeply(
    $parsed,
    [
      {
        'status'    => '01',
        'cidade'    => 'Sao Paulo',
        'hora'      => '06:45',
        'uf'        => 'SP',
        'descricao' => 'Objeto encaminhado',
        'tipo'      => 'DO',
        'destino'   => {
          'cidade' => 'Sao Paulo',
          'codigo' => '02307970',
          'uf'     => 'SP',
          'local'  => 'CDD TUCURUVI',
          'bairro' => 'Tucuruvi'
        },
        'codigo' => '02170975',
        'data'   => '20/05/2017',
        'local'  => 'CTE VILA MARIA'
      },
      {
        'destino' => {
          'bairro' => 'Parque Novo Mundo',
          'cidade' => 'Sao Paulo',
          'codigo' => '02170975',
          'local'  => 'CTE VILA MARIA',
          'uf'     => 'SP'
        },
        'codigo'    => '31276970',
        'local'     => 'CTE BELO HORIZONTE',
        'data'      => '19/05/2017',
        'hora'      => '22:19',
        'cidade'    => 'BELO HORIZONTE',
        'uf'        => 'MG',
        'descricao' => 'Objeto encaminhado',
        'tipo'      => 'DO',
        'status'    => '01'
      },
      {
        'local'   => 'AGF BERNARDO MONTEIRO',
        'data'    => '19/05/2017',
        'codigo'  => '30140973',
        'destino' => {
          'bairro' => 'Universitário',
          'local'  => 'CTE BELO HORIZONTE',
          'uf'     => 'MG',
          'cidade' => 'BELO HORIZONTE',
          'codigo' => '31276970'
        },
        'status'    => '01',
        'uf'        => 'MG',
        'descricao' => 'Objeto encaminhado',
        'tipo'      => 'DO',
        'hora'      => '16:47',
        'cidade'    => 'Belo Horizonte'
      },
      {
        'status'    => '01',
        'descricao' => 'Objeto postado',
        'uf'        => 'MG',
        'tipo'      => 'PO',
        'cidade'    => 'Belo Horizonte',
        'hora'      => '15:57',
        'local'     => 'AGF BERNARDO MONTEIRO',
        'data'      => '19/05/2017',
        'codigo'    => '30140973'
      }
    ],
    'proper data parsing for single object'
);

# multiple objects returned
$content = q{<?xml version="1.0" encoding="utf-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header><X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace xmlns:X-OPNET-Transaction-Trace="http://opnet.com">pid=30598,requestid=4c23630380a92ed96cd1a52a6b63d25e4dd8e0f8013cf9b3</X-OPNET-Transaction-Trace:X-OPNET-Transaction-Trace></soapenv:Header><soapenv:Body><ns2:buscaEventosResponse xmlns:ns2="http://resource.webservice.correios.com.br/"><return><versao>2.0</versao><qtd>2</qtd><objeto><numero>PL497608251BR</numero><sigla>PL</sigla><nome>ENCOMENDA PAC</nome><categoria>ENCOMENDA PAC</categoria><evento><tipo>DO</tipo><status>01</status><data>23/05/2017</data><hora>16:15</hora><descricao>Objeto encaminhado </descricao><local>AGF MERITI</local><codigo>21250973</codigo><cidade>Rio De Janeiro</cidade><uf>RJ</uf><destino><local>CTE BENFICA</local><codigo>21041973</codigo><cidade>Rio De Janeiro</cidade><bairro>Benfica</bairro><uf>RJ</uf></destino></evento></objeto><objeto><numero>JR724074792BR</numero><sigla>JR</sigla><nome>REGISTRADO PRIORITÁRIO</nome><categoria>REGISTRADO ESPECIAL</categoria><evento><tipo>PO</tipo><status>09</status><data>23/05/2017</data><hora>16:30</hora><descricao>Objeto postado após o horário limite da agência</descricao><detalhe>Objeto sujeito a encaminhamento no próximo dia útil</detalhe><local>AGF MERITI</local><codigo>21250973</codigo><cidade>Rio De Janeiro</cidade><uf>RJ</uf></evento></objeto></return></ns2:buscaEventosResponse></soapenv:Body></soapenv:Envelope>};

$parsed = WWW::Correios::SRO::_parse_response($content);
is_deeply(
    $parsed,
    {
        JR724074792BR => [{
            cidade    => "Rio De Janeiro",
            codigo    => '21250973',
            data      => "23/05/2017",
            descricao => "Objeto postado após o horário limite da agência",
            detalhe   => "Objeto sujeito a encaminhamento no próximo dia útil",
            hora      => "16:30",
            local     => "AGF MERITI",
            status    => "09",
            tipo      => "PO",
            uf        => "RJ",
        }],
        PL497608251BR => [{
            cidade    => "Rio De Janeiro",
            codigo    => 21250973,
            data      => "23/05/2017",
            descricao => "Objeto encaminhado",
            destino   => {
                bairro => "Benfica",
                cidade => "Rio De Janeiro",
                codigo => 21041973,
                local  => "CTE BENFICA",
                uf     => "RJ",
            },
            hora   => "16:15",
            local  => "AGF MERITI",
            status => "01",
            tipo   => "DO",
            uf     => "RJ",
        }],
    },
    'proper data parsing for multiple objects'
);
