package WebService::Heartrails::Express::Provider::Near;
use strict;
use warnings;
use utf8;
use WebService::Heartrails::Express::Provider::Common;
use Carp;

sub call{
  my($self,$class,$arg) = @_;
  my $x = $arg->{x};
  my $y = $arg->{y};
 
  unless(defined $x or defined $y){
     croak("x or y is either required");
  }
 
  my $sub_url =do{
   if(not defined $x){
     {method => 'getStations',y => $y};
   }elsif(not defined $y){
     {method => 'getStations',x => $x};
   }else{
     {method => 'getStations',x => $x,y => $y};
   }
  };

  my $content = WebService::Heartrails::Express::Provider::Common::call($class,$sub_url);
  return JSON::decode_json($content)->{response}->{station};
}

1;
