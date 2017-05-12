#!/usr/bin/perl

use XML::DT ;

my $filename = shift;

%xml=( 'ARTIGO' => sub{"------------\n$c\n"},
       'TEXTO' => sub{""},
       '-default' => sub{"$q - $c\n"},
       '-outputenc' => 'ISO-8859-1'
     );

print &dt($filename,%xml);
   
