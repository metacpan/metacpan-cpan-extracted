package WebService::Heartrails::Express::Provider::Station;
use strict;
use warnings;
use utf8;
use Carp;

sub call{
  my($self,$class,$arg) = @_;

  my $line = $arg->{line};
  my $name = $arg->{name}; 

  unless(defined $line or defined $name){
    croak("line or name is either required");
  }

  my $sub_url = do{
    if(not defined $line){
      {method => 'getStations',name => $name};
    }elsif(not defined $name){
      {method => 'getStations',line => $line};
    }else{
      {method => 'getStations',line => $line ,name => $name};
    }
  };

  my $content = WebService::Heartrails::Express::Provider::Common::call($class,$sub_url);

  return JSON::decode_json($content)->{response}->{station};

}

1;
