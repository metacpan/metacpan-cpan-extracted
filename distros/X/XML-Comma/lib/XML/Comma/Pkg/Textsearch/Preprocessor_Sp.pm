##
#
#    Copyright 2001 AllAfrica Global Media
#
#    This file is part of XML::Comma
#
#    XML::Comma is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    For more information about XML::Comma, point a web browser at
#    http://xml-comma.org, or read the tutorial included
#    with the XML::Comma distribution at docs/guide.html
#
##

package XML::Comma::Pkg::Textsearch::Preprocessor_Sp;

use XML::Comma::Pkg::Textsearch::Preprocessor;
use locale qw( sp );
use strict;

use XML::Comma::Util qw( dbg );

my %Preprocessor_Stopwords;
my $max_length = $XML::Comma::Pkg::Textsearch::Preprocessor::max_word_length;


# usage: @list_of_words = XML::Comma::Pkg::Textsearch::Preprocessor->stem($text)
sub stem {
  my %dups;
  # split and throw away stopwords
  my @words = grep { ! defined $Preprocessor_Stopwords{$_} }
    split ( /\W+/, $_[1] );
  # stem and throw away long words and duplicates
  return grep { $_ and (! $dups{$_} ++) and (length($_) <= $max_length) }
    lightweight_stem(@words);
}

# usage:
#   %hash = XML::Comma::Pkg::Textsearch::Preprocessor->stem_and_count($text)
#
sub stem_and_count {
  my %hash;
  foreach ( @{Lingua::Stem::stem ( split(m:[\s\W]+:, $_[1]) )} ) {
    unless ( defined $Preprocessor_Stopwords{$_} or
             length($_) > $max_length ) {
      $hash{$_}++;
    }
  }
  return %hash;
}

##
# lightweight stemming algorithm and stopwords list adapted from
# information found at 'University of Neuchatel' :
# http://www.unine.ch/info/clef/
##
sub lightweight_stem {
  my @words;
  foreach my $word ( @_) {
    if ( length($word) > 5 ) {
      # remove all accents
      $word =~ s/[à|á]/a/g;
      $word =~ s/[ò|ó]/o/g;
      $word =~ s/[è|é]/e/g;
      $word =~ s/[ù|ú|ü]/u/g;
      $word =~ s/[ì|í]/i/g;
      # apply exactly one plural rule
      $word =~ s/eses$/es/           ||
        $word =~ s/ces$/z/           ||
          $word =~ s/[o|a|e]s$//     ||
            $word =~ s/o$//          ||
              $word =~ s/a$//        ||
                $word =~ s/e$//      ;
    }
    push @words, $word;
  }
  return @words;
}

BEGIN {
  %Preprocessor_Stopwords = map { $_ => 1 }
    qw(
          él
          ésta
          éstas
          éste
          éstos
          última
          últimas
          último
          últimos
          a
          añadió
          aún
          actualmente
          adelante
          además
          afirmó
          agregó
          ahí
          ahora
          al
          algún
          algo
          alguna
          algunas
          alguno
          algunos
          alrededor
          ambos
          ante
          anterior
          antes
          apenas
          aproximadamente
          aquí
          así
          aseguró
          aunque
          ayer
          bajo
          bien
          buen
          buena
          buenas
          bueno
          buenos
          cómo
          cada
          casi
          cerca
          cierto
          cinco
          comentó
          como
          con
          conocer
          consideró
          considera
          contra
          cosas
          creo
          cual
          cuales
          cualquier
          cuando
          cuanto
          cuatro
          cuenta
          da
          dado
          dan
          dar
          de
          debe
          deben
          debido
          decir
          dejó
          del
          demás
          dentro
          desde
          después
          dice
          dicen
          dicho
          dieron
          diferente
          diferentes
          dijeron
          dijo
          dio
          donde
          dos
          durante
          e
          ejemplo
          el
          ella
          ellas
          ello
          ellos
          embargo
          en
          encuentra
          entonces
          entre
          era
          eran
          es
          esa
          esas
          ese
          eso
          esos
          está
          están
          esta
          estaba
          estaban
          estamos
          estar
          estará
          estas
          este
          esto
          estos
          estoy
          estuvo
          ex
          existe
          existen
          explicó
          expresó
          fin
          fue
          fuera
          fueron
          gran
          grandes
          ha
          había
          habían
          haber
          habrá
          hace
          hacen
          hacer
          hacerlo
          hacia
          haciendo
          han
          hasta
          hay
          haya
          he
          hecho
          hemos
          hicieron
          hizo
          hoy
          hubo
          igual
          incluso
          indicó
          informó
          junto
          la
          lado
          las
          le
          les
          llegó
          lleva
          llevar
          lo
          los
          luego
          lugar
          más
          manera
          manifestó
          mayor
          me
          mediante
          mejor
          mencionó
          menos
          mi
          mientras
          misma
          mismas
          mismo
          mismos
          momento
          mucha
          muchas
          mucho
          muchos
          muy
          nada
          nadie
          ni
          ningún
          ninguna
          ningunas
          ninguno
          ningunos
          no
          nos
          nosotras
          nosotros
          nuestra
          nuestras
          nuestro
          nuestros
          nueva
          nuevas
          nuevo
          nuevos
          nunca
          o
          ocho
          otra
          otras
          otro
          otros
          para
          parece
          parte
          partir
          pasada
          pasado
          pero
          pesar
          poca
          pocas
          poco
          pocos
          podemos
          podrá
          podrán
          podría
          podrían
          poner
          por
          porque
          posible
          próximo
          próximos
          primer
          primera
          primero
          primeros
          principalmente
          propia
          propias
          propio
          propios
          pudo
          pueda
          puede
          pueden
          pues
          qué
          que
          quedó
          queremos
          quién
          quien
          quienes
          quiere
          realizó
          realizado
          realizar
          respecto
          sí
          sólo
          se
          señaló
          sea
          sean
          según
          segunda
          segundo
          seis
          ser
          será
          serán
          sería
          si
          sido
          siempre
          siendo
          siete
          sigue
          siguiente
          sin
          sino
          sobre
          sola
          solamente
          solas
          solo
          solos
          son
          su
          sus
          tal
          también
          tampoco
          tan
          tanto
          tenía
          tendrá
          tendrán
          tenemos
          tener
          tenga
          tengo
          tenido
          tercera
          tiene
          tienen
          toda
          todas
          todavía
          todo
          todos
          total
          tras
          trata
          través
          tres
          tuvo
          un
          una
          unas
          uno
          unos
          usted
          va
          vamos
          van
          varias
          varios
          veces
          ver
          vez
          y
          ya
          yo
    );
}

1;

