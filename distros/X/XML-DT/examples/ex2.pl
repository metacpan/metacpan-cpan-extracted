#!/usr/bin/perl

use XML::DT ;
use Data::Dumper;

my $filename = shift;

%xml2=('foto'    => sub{$ind{$isa}= [@{$ind{$isa}},$url]; 
                        $isa=$url="";
                        "<li> $c"},
       'url'     => sub{$url=$c;"<a href=\"$c\">$c</a>"},
       'isa'     => sub{$isa=lc($c);$c},
       'author'  => sub{uc($c) },
       'resol'   => sub{""},
       'arq'     => sub{"Indice\n". Dumper(\%ind) . "----------\n$c"},
       '-default'=> sub{"$q:$c"},
       '-outputenc' => 'ISO-8859-1'
     );

%xml=( 'music'    => sub{"Autor da musica: $c"},
       'musica'   => sub{"--------------(AMP)--------\n$c"},
       'lyrics'   => sub{"Autor da letra:$c"},
       'title'    => sub{ uc($c) . $v{acordes} },
       '-default' => sub{"$q:$c"},
       'arquivo'  => sub{("_" x 60). dt($v{file},%xml2)},
       '-outputenc' => 'ISO-8859-1'
     );

print dt($filename,%xml);
