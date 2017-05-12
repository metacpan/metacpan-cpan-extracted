#!/usr/bin/perl

use XML::DT ;

my $filename = shift;

$f=sub{for (@isa) {$ind{$_}= [@{$ind{$_}},[$url,$title]]};
                        $url=$title="";
                        @isa=();
                        "<li>$c"};

%xml=( 'foto'    => $f,
       'desenho' => $f,
       'aguarela'=> $f,
       'url'     => sub{$url=$c;""},
       'title'   => sub{$title=$c;"<a href=\"$url\">$c</a>[$res]<br>"},
       'isa'     => sub{push(@isa,n($c));" (<i>$c</i>)"},
       'author'  => sub{ " <b>$c</b> " },
       'resol'   => sub{$res=$c;""},
       'arq'     => sub{$c},
#      '-default'=> sub{"<li> $q:$c"},
       '-outputenc' => 'ISO-8859-1',
     );

$imglist = "<ol>" . dt($filename,%xml). "</ol>" ;

print "<h1>Arquivo de imagens</h1>",
      mkind(%ind), 
      "<h2>Lista das imagens</h2> $imglist";  
   
sub mkind{ my %a=@_;
  my $r="<h2>Indice</h2><ul>";
  for $p (sort keys %a){
    $r.= "<li>$p -- <ul> ".
          join("",map{"<li><a href=\"$_->[0]\">$_->[1]</a>\n"} @{$a{$p}}).
         "</ul>" ;
  }
  $r . "</ul>";
}

sub n{ my $a= lc(shift) ;
  for($a){ s/^ +//; s/ +$//; s/  +/ /g; } $a; }
