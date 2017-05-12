#!perl

use Test::More tests => 4;
use strict;
use warnings;

use WWW::Correios::PrecoPrazo;

my $cpp;

$cpp = WWW::Correios::PrecoPrazo->new;
ok( defined $cpp, 'Construtor sem argumentos' );
$cpp = undef;

$cpp = WWW::Correios::PrecoPrazo->new(
    {
        scheme => 'ftp',
        host   => 'localhost',
        path   => '/foo/bar',
    }
);
ok( defined $cpp, 'Construtor com argumentos' );
ok( UNIVERSAL::isa( $cpp->{base_uri}, 'URI' ), 'URI instanciada' );
ok( $cpp->{base_uri}->as_string eq 'ftp://localhost/foo/bar' );
