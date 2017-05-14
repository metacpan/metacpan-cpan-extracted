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
my $noticias = $sexta->get_noticias;

print "Obtenemos los programas de la sección noticias\n";

for my $p (0..@$noticias - 1)
   {
       for my $k (keys @$noticias[$p])
           {
           print "Título $p: $k\n";
           print "URL $p: " . @{$noticias}[$p]->{$k} . "\n\n";
           }
   }

# Obtenemos los capítulos del noticiero "Deportes";
my $capitulos = $sexta->get_capitulos("Deportes");

print "Mostramos información de los 3 últimos capítulos\n";

for my $c (0..2)
   {
       for my $k (keys @$capitulos[$c])
           {
           print "($c) $k:";
           print " " . @{$capitulos}[$c]->{$k} . "\n";
           }
   print "\n";
   }

my $xml = SextaXML->new(URL => $$capitulos[0]->{URL});

print "\n\n\nObteniendo datos del primer capítulo:\n\n";

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

