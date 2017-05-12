#!perl

use Test::More tests => 13;
use strict;
use warnings;

package HTTP::Response::Mock;
sub new     { bless {}, 'HTTP::Response::Mock' }
sub content { '<?xml><cServico><Foo>42</Foo></cServico></xml>' }

package LWP::Mock;
sub new { bless {}, 'LWP::Mock' }
sub get { return HTTP::Response::Mock->new }

package main;

use WWW::Correios::PrecoPrazo;

ok my $cpp = WWW::Correios::PrecoPrazo->new( { user_agent => LWP::Mock->new } ),
    'modulo carregado';

is_deeply(
    $cpp->query,
    { response => undef },
    'Query vazia'
);

is_deeply(
    $cpp->query( formato => 'caixa' ),
    { response => undef },
    'Query recebendo Hash'
);

is_deeply(
    $cpp->query( { formato => 'caixa' } ),
    { response => undef },
    'Query recebendo HashRef'
);

is_deeply(
    $cpp->query( { formato => 'Batata Baroa' } ),
    { response => undef },
    'Formato inválido'
);

my %query = (
    cep_origem     => '22222-222',
    cep_destino    => '11111-111',
    codigo_servico => 1,
);

ok my $res = $cpp->query( %query ), 'query retornou';
is ref $res, 'HASH', 'query retornou hashref';
is $res->{Foo}, 42, 'parser';
isa_ok $res->{response}, 'HTTP::Response::Mock';


ok $res = $cpp->query( \%query ), 'query retornou (hashref)';
is ref $res, 'HASH', 'query retornou hashref (hashref)';
is $res->{Foo}, 42, 'parser (hashref)';
isa_ok $res->{response}, 'HTTP::Response::Mock';


