#!/usr/bin/perl -w
use strict;
use CGI;
use TRTES;

my $q = new CGI;

my $tiponumeracao; # antiga / unificada

my $numero;
my $numeracaoantiga = "";
my $numeracaonova = "0127600-96";

my $digito;
my $ano="2007";
my $vara="151";
my $recurso="00"; #00

if(length($numeracaonova)>1)
{
    my @vetnum=split(/-/, $numeracaonova);
    $numero=$vetnum[0];
    $tiponumeracao="unificada";
    $digito=$vetnum[1];
}
else
{
    $numero=$numeracaoantiga;
    $tiponumeracao="antiga";
}

# cria o objeto TRTES
my $tribunal = new Tribunais::TRTES($tiponumeracao, $numero, $ano, $vara, $recurso, $digito);

#responde para o cliente em JSON
print $q->header();#'application/json'

print $tribunal->sincroniza;

