#!perl

use Test::More;
use strict;
use warnings;

use WWW::Correios::PrecoPrazo;
use Const::Fast;

const my $args => {
    scheme  => 'https',
    host    => 'example.com',
    path    => '/webservice',
    timeout => 42,
};

my $cpp = WWW::Correios::PrecoPrazo->new($args);

ok $cpp, 'Argumentos constantes copiados internamente para escrita';

done_testing;
