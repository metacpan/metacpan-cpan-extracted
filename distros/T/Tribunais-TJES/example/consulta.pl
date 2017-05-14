#!/usr/bin/perl -w
use strict;
use CGI;
use TJES;

my $q = new CGI;

my $numeracaoantiga = "021070011867";
my $numeracaonova = "";

my $edNumProcesso;
my $seInstancia=1;
my $sePesquisar=1;

if(length($numeracaonova)>1)
{
    $edNumProcesso=$numeracaonova;
}
else
{
    $edNumProcesso=$numeracaoantiga;
}

my $tribunal = new Tribunais::TJES($edNumProcesso, $seInstancia, $sePesquisar);

print $q->header('application/json');

print $tribunal->sincroniza;