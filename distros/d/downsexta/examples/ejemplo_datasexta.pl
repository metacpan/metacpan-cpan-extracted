 #!/usr/bin/perl 

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use open 'locale';
use Encode;
use DownVideos::DataSexta;

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
