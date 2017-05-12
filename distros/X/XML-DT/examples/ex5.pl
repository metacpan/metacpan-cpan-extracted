#!/usr/bin/perl

use XML::DT ;
use Data::Dumper;
sub XML::DT::Dumper {}# Dumper(shift)}

my $filename = shift;

%xml=( 'music'    => sub{"Autor da musica: $c ($v{x})"},
       'musica'   => sub{"\n--------------(AMP)$v{x}--------\n$c"},
       '-default' => sub{"contexto=".join("/",@dtcontext). 
                         "\n $q:$c\n". 
                         "pai=". ctxt(1). "\n" },
       'arquivo'  => sub{("_" x 60). dt($v{file},%xml2)},
       '-outputenc' => 'ISO-8859-1'
     );

# print dt("$filename");
print dt($filename,%xml);
