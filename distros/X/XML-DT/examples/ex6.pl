#!/usr/bin/perl

use XML::DT ;
use Data::Dumper;
sub XML::DT::Dumper {}# Dumper(shift)}

my $filename = shift;

%xml=(
       '-default' => sub{
          if(inctxt('url')) 
               {"\n (sunof url) $q:$c\n pai=". ctxt(1). "\n" }
          elsif(inctxt('foto')) 
               {"\n (sun of foto) $q:$c\n pai=". ctxt(1). "\n" }
          elsif(inctxt('desenho.*')) 
               {"\n (desenho....) $q:$c\n pai=". ctxt(1). "\n" }
          else {"\n (outros) $q:$c\n pai=". ctxt(1). "\n" }
       },
       '-outputenc' => 'ISO-8859-1'
     );

# print dt("$filename");
print dt($filename,%xml);
