#!/usr/bin/perl

use XML::DT ;

my $filename = shift;

%xml=( 'music'    => sub{"Autor da musica: $c"},
       'musica'   => sub{"--------------(AMP)--------\n$c"},
       'lyrics'   => sub{"Autor da letra:$c"},
       'title'    => sub{ uc($c) . $v{acordes} },
       '-default' => sub{"$q:$c"},
       '-outputenc' => 'ISO-8859-1'
     );

print &dt($filename,%xml);

