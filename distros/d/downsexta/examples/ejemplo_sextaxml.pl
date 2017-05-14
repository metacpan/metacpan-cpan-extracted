 #!/usr/bin/perl

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use open 'locale';
use Encode;
use DownVideos::DataSexta;
use DownVideos::SextaXML;

my $sexta = DataSexta->new();

my $programas = $sexta->get_programas;

print "Programas:\n\n";
for my $p (@$programas)
  {
  for my $k (keys $p)
    {
    print "\t$k\n";
    }
  }

my $capitulos = $sexta->get_capitulos("Más Vale Tarde");


foreach my $c (0..@{$capitulos} - 1)
  {
  print "$c) TITULO: " . @{$capitulos}[$c]->{TITULO} . "\n";
  print "$c) URL: " . @{$capitulos}[$c]->{URL} . "\n\n";
  }

print "\n";

my $xml = SextaXML->new(URL => $$capitulos[26]->{URL});

print "\n\n\nObteniendo datos del capítulo 27:\n\n";

print "\tNombre:\t\t" . $xml->nombre . "\n";
print "\tSección:\t" . $xml->seccion . "\n";
print "\tInfo:\t\t" . $xml->info . "\n";
print "\tDescripción:\t" . $xml->descripcion . "\n";
print "\tRTMP:\t\t" . $xml->rtmp . "\n\n";

my @etiquetas = ('Video', 'Tipo', 'Tamaño', 'Imagen'); 
my @seccion = ('VIDEO', 'MIMETYPE', 'TAMANYO', 'IMAGEN'); 

my $multimedia = $xml->multimedia;

foreach my $n (0..@{$xml->multimedia} - 1)
    {
    foreach my $m (0..@seccion - 1)
      {
      print "\t$etiquetas[$m]:\t\t" . @{$xml->multimedia}[$n]->{"$seccion[$m]"} . "\n";
      }
    print "\n";
    }

